import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

/// True when a 429 is the DAILY free allowance running out, not the per-minute one.
///
/// Google says which in the error: the quota's name has "PerDay" or "PerMinute" in it.
/// A per-minute limit is worth waiting out — a minute later it works. A per-day one is
/// not, and every retry against it is another request thrown at a wall, spending the
/// wait for nothing and telling you nothing new.
bool isDailyLimit(String body) => body.contains('PerDay');

/// Models this key has answered 404 for, kept on the phone with the day they failed.
///
/// Kept across launches: in memory only, the missing model was tried again — and
/// failed again — every time the app opened. Forgotten after a week, because Google
/// does add models to keys, and a name missing today may be there next month.
final Map<String, DateTime> _missingModels = {};
bool _missingLoaded = false;

Future<File> _missingFile() async =>
    File('${(await getApplicationDocumentsDirectory()).path}/missing_models.json');

Future<void> _loadMissing() async {
  if (_missingLoaded) return;
  _missingLoaded = true;
  try {
    final f = await _missingFile();
    if (!await f.exists()) return;
    final raw = jsonDecode(await f.readAsString());
    if (raw is! Map) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    raw.forEach((name, when) {
      final t = DateTime.tryParse('$when');
      if (t != null && t.isAfter(cutoff)) _missingModels['$name'] = t;
    });
  } catch (_) {}
}

Future<void> _rememberMissing(String model) async {
  _missingModels[model] = DateTime.now();
  try {
    await (await _missingFile()).writeAsString(jsonEncode(
      _missingModels.map((k, v) => MapEntry(k, v.toIso8601String()))));
  } catch (_) {}
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
  /// A model to fall back to when [model] does not exist for this key.
  ///
  /// Free-tier limits are counted per model, so the small jobs are pointed at a
  /// lighter one to keep them out of the budget the script needs. Google renames
  /// models often enough that hard-coding a name is a bet, and this is the hedge:
  /// a name that is not there costs one 404 and then never gets used again.
  String? fallbackModel,
  /// Called between tries, so a wait does not look like a hang.
  void Function(String message)? onWait,
}) async {
  await _loadMissing();
  var chosen = model;
  if (_missingModels.containsKey(chosen) && fallbackModel != null) {
    chosen = fallbackModel;
  }

  Uri urlFor(String m) =>
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
          '$m:generateContent?key=$apiKey');

  var url = urlFor(chosen);
  http.Response response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  ).timeout(timeout);

  if (response.statusCode == 404 && fallbackModel != null && chosen != fallbackModel) {
    await _rememberMissing(chosen);
    chosen = fallbackModel;
    url = urlFor(chosen);
    response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(timeout);
  }

  for (final fallback in _backoff) {
    if (!_retryable.contains(response.statusCode)) return response;
    // Out for the day: stop here rather than spend four more requests learning it.
    if (response.statusCode == 429 && isDailyLimit(response.body)) return response;

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
String geminiBusyMessage(int statusCode, [String body = '']) {
  if (statusCode == 503) {
    return 'Gemini is overloaded right now. This is at their end and usually passes in '
        'a minute or two. Your story is saved — try again shortly.';
  }
  // Said differently because the advice is different: waiting a minute will not help,
  // and tapping again and again only fails again.
  if (isDailyLimit(body)) {
    return 'Today\'s free Gemini requests are used up. They reset tomorrow. Your story '
        'is saved — nothing is lost. Reels you already made still open, and the '
        'caption sheet still works.';
  }
  return 'Gemini has run out of free requests for the moment. Your story is saved, so '
      'nothing is lost — wait a minute and tap it again.';
}
