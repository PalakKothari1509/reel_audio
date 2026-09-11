import 'package:http/http.dart' as http;

// ── One place that talks to Gemini ────────────────────────────────────────────
//
// Every text request in the app goes through here so that "Google is busy" is handled
// once instead of four times.
//
// 503 UNAVAILABLE does not mean anything is wrong with the request. It means the model
// is overloaded at this second, and Google says so in the message: spikes are usually
// temporary. Showing that to someone as a wall of JSON makes a working app look broken
// when the only thing needed was to ask again a moment later.

/// Status codes worth trying again. Everything else is a real error and is returned
/// as-is, because retrying a bad request just makes the same mistake more slowly.
///
/// 500 is Google's own fault, 503 is Google being busy, 429 is too many too quickly.
const _retryable = {429, 500, 503};

/// How long to wait before each retry, when Google does not say.
///
/// A real demand spike on a popular model lasts longer than a few seconds, so giving
/// up quickly meant the retry rarely got to do its job at all. Waiting a minute beats
/// retyping the story, as long as the screen keeps saying why it is waiting.
const _backoff = [
  Duration(seconds: 4),
  Duration(seconds: 10),
  Duration(seconds: 20),
  Duration(seconds: 30),
];

/// How long Google asked us to wait, from the retryDelay in the body ("19s").
///
/// Worth reading rather than guessing: on a 429 Google says exactly when the quota
/// frees up, and waiting our own made-up interval either gives up too early or sits
/// there longer than it had to. A second is added because retrying on the exact
/// boundary tends to come back 429 again.
Duration? _googlesOwnDelay(String body) {
  final match = RegExp(r'"retryDelay"\s*:\s*"(\d+)').firstMatch(body);
  final seconds = int.tryParse(match?.group(1) ?? '');
  if (seconds == null) return null;
  return Duration(seconds: seconds.clamp(1, 60) + 1);
}

/// Posts to a Gemini text model and hands back the response.
///
/// Times out rather than retrying on a timeout: a request that took too long once will
/// usually take too long again, and the caller already explains that case properly.
Future<http.Response> geminiPost({
  required String model,
  required String apiKey,
  required String body,
  required Duration timeout,
  /// Called between tries, so a wait does not look like a hang.
  void Function(String message)? onWait,
}) async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$apiKey');

  http.Response response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  ).timeout(timeout);

  for (final fallback in _backoff) {
    if (!_retryable.contains(response.statusCode)) return response;

    // Google's own number wins when it gives one.
    final wait = _googlesOwnDelay(response.body) ?? fallback;
    final why = response.statusCode == 429
        ? 'Gemini is rate limiting this key'
        : 'Gemini is busy';

    // Counted down rather than one message and a long silence: without this, a
    // thirty second wait is indistinguishable from the app having hung.
    for (var left = wait.inSeconds; left > 0; left--) {
      onWait?.call('$why — trying again in ${left}s...');
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(timeout);
  }

  return response;
}

/// What to say when Gemini was still busy after every try.
///
/// Separate from the code because the answer is "wait a bit", not "something is
/// broken", and the raw JSON says the opposite to anyone reading it.
String geminiBusyMessage(int statusCode) => statusCode == 503
    ? 'Gemini is overloaded right now. This is at their end and usually passes in a '
        'minute or two. Your story is saved — try again shortly.'
    : 'Gemini has run out of free requests for the moment. Your story is saved, so '
        'nothing is lost — wait a minute and tap it again.';
