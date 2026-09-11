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

/// How long to wait before each retry. Two goes after the first attempt, which covers
/// the ordinary blip without leaving someone staring at a frozen button for a minute.
const _backoff = [Duration(seconds: 3), Duration(seconds: 7)];

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

  for (final wait in _backoff) {
    if (!_retryable.contains(response.statusCode)) return response;

    onWait?.call('Gemini is busy — trying again in ${wait.inSeconds}s...');
    await Future<void>.delayed(wait);

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
        'minute or two — try again shortly.'
    : 'Gemini is rate limiting this key. Wait a minute and try again.';
