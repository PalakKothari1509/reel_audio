import 'dart:convert';

import 'gemini_call.dart';
import 'prompts.dart';
import 'secrets.dart';

// ── Turning a finished script into prompts ────────────────────────────────────
//
// A second Gemini call rather than asking for everything at once. The script call
// already has a lot to get right — timings, line count, Devanagari — and adding a
// dozen more fields to it made the whole thing fail when any one part came back wrong.
// Kept separate, a bad prompt run costs you the prompts and leaves the script alone.

const _model = 'gemini-3.6-flash';
const _timeout = Duration(seconds: 90);

class PromptSet {
  final StoryBeats beats;
  final List<ScenePrompt> scenes;
  final PostDetails post;

  /// Exactly what Gemini sent back, kept so the whole set can be written to the phone
  /// and read again without spending another request on an identical answer.
  ///
  /// The raw reply rather than the parsed objects on purpose: saving the objects would
  /// mean a second writer and a second reader that have to agree with the parsing
  /// below forever, and the day they stop agreeing is the day old stories break.
  final String rawJson;

  const PromptSet({
    required this.beats,
    required this.scenes,
    required this.post,
    this.rawJson = '',
  });
}

/// Rebuilds a prompt set from a reply saved earlier, spending nothing.
///
/// Throws if the saved text is not usable, so the caller can simply ask Gemini again.
PromptSet promptsFromSaved(String rawJson, List<String> scriptLines) {
  final json = jsonDecode(rawJson) as Map<String, dynamic>;
  return _toPromptSet(json, scriptLines, rawJson);
}

// ── Everything in one request ─────────────────────────────────────────────────
//
// The script and the prompts were two calls on purpose: asking for everything at once
// used to fail whole, and losing the script because a hashtag came back wrong is a bad
// trade. Two things have changed since. JSON mode means a reply is either parseable or
// it is not, rather than prose that has to be guessed at; and on a free tier the second
// request is the one that runs you out, which is a cost the split did not have then.
//
// So it is tried first and the two-call path is still there underneath. When this
// works it is one request for the whole reel, and the prompts arrive already written
// down, so opening that screen later costs nothing either.

/// A whole reel from one reply: the script, and the prompts that go with it.
class StoryPackage {
  /// Script lines as "0:04 text | spoken", which is the shape parseScript already
  /// reads — so nothing new parses a script, and nothing new can disagree about it.
  final List<String> scriptLines;
  final PromptSet prompts;
  const StoryPackage({required this.scriptLines, required this.prompts});
}

/// Thrown when the combined reply cannot be used, so the caller can quietly fall back
/// to the two separate calls instead of showing anyone an error about it.
class CombinedCallFailed implements Exception {
  final String reason;
  const CombinedCallFailed(this.reason);
  @override
  String toString() => 'Combined call failed: $reason';
}

/// How many script lines this is worth attempting for.
///
/// A long script plus a scene for each of its lines plus the post details can run past
/// what the model will return in one go, and a truncated reply costs a request and
/// gives nothing. Short reels fit comfortably; 45 and 60 second ones go the old way.
const kCombinedLineLimit = 10;

/// Writes the script AND the prompts in a single request.
Future<StoryPackage> generateEverything({
  required String storyDescription,
  required String language,
  required String style,
  required int seconds,
  required int expectedLines,
  void Function(String message)? onWait,
}) async {
  final isHinglish = language == 'Hinglish';

  final scriptShape = isHinglish
      ? '"text" is Hinglish (Hindi words in English letters). "speak" is the SAME line '
        'written in Devanagari — that half is what gets spoken aloud, so it must match.'
      : '"text" is the line. Leave "speak" as an empty string.';

  final prompt = '''
Write a complete $seconds second preschool reel for "Fun Learning With Palak".

THE STORY (this is the source of truth, follow it):
$storyDescription

Characters: Ria (toddler girl), Rio (toddler boy), Cuty (white bunny), Mumma, Papa.

$kScriptShapeRules

$kReelShapeRules

Keep every spoken line under 12 words so it takes about 4 seconds to say.
Write how a person talks, not how a book reads.

Return ONLY valid JSON in exactly this shape:

{
  "script": [
    {"at": 0, "text": "the line on screen", "speak": "the same line in Devanagari"}
  ],
  "title": "short title in Hinglish",
  "hook": "the opening line as a text overlay",
  "who": "which characters appear",
  "where": "the setting, e.g. sunny Indian kitchen",
  "what_starts_it": "one sentence",
  "what_goes_wrong": "one sentence",
  "how_it_gets_worse": "one sentence",
  "how_it_is_solved": "one sentence",
  "ending_line": "the moral, one short line in Hinglish",
  "closing_cta": "a short follow line in Hinglish",
  "cover_hook": "2 to 4 Hinglish words for screen 1, taken from what happens, e.g. Tractor Gayab?!",
  "cover_title": "3 to 5 words for the reel cover, big and curious",
  "moral_line": "the lesson for the second-to-last screen, one warm line a parent would say out loud",
  "cta_line": "the reason to keep this reel, on the last screen, e.g. Save this for tonight's bedtime story",
  "end_question": "one question on the last screen a parent can answer in four words, about their own child",
  "caption": "2 or 3 lines for Instagram, warm, speaking to parents, ending in something they will want to answer",
  "hashtags": ["#exactly", "#five", "#relevant", "#tags", "#here"],
  "pin_comment": "the first comment, pinned. Say one true thing about this situation in a parent's own house, then ask them about theirs. Something answerable in a few words, never yes or no",
  "reply_question": "what to reply to a comment with. Warm, Hinglish, and it ends in a question of its own so the conversation carries on — a reply that only says thank you ends it",
  "best_time": "a posting window for Indian parents of small children, e.g. Weekdays 8-9 pm IST",
  "scenes": [
    {"scene": "what the picture shows, one sentence, name the characters in it",
     "expression": "the main character's face, e.g. worried, laughing, proud",
     "beat": "one of Hook, Problem, Conflict, Turn, Solution, Ending",
     "shot": "wide / close-up on face / from above / looking up",
     "key_objects": "the props this moment turns on, e.g. red teddy, spilt milk",
     "dialogue": "what a character says out loud here in Hinglish, or empty"}
  ]
}

Rules:
- "script" must have exactly $expectedLines entries.
- "at" is the second that line starts, counting from 0, roughly 4 seconds apart.
- $scriptShape
- "scenes" must have exactly $expectedLines entries, one per script line, in order.
- Scene 1 is the hook and must be the most eye-catching picture of the set.
- Describe pictures, not camera equipment. No text or writing inside the pictures.
- Keep it all compact. Short sentences everywhere.
''';

  final response = await geminiPost(
    model: _model,
    apiKey: geminiApiKey,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.8,
        'maxOutputTokens': 8192,
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    // A busy or rate-limited Gemini is not a reason to try again immediately with a
    // second call, so this one is passed up as a real error rather than a fallback.
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode)
        : 'Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final candidate = body['candidates']?[0];
  final text = candidate?['content']?['parts']?[0]?['text'] as String? ?? '';

  // Ran out of room mid-reply. The JSON is half-written and unusable, and the two
  // smaller calls will fit where this one did not.
  if (candidate?['finishReason'] == 'MAX_TOKENS') {
    throw const CombinedCallFailed('the reply was too long to finish');
  }
  if (text.trim().isEmpty) {
    throw const CombinedCallFailed('nothing came back');
  }

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(_stripFence(text)) as Map<String, dynamic>;
  } catch (_) {
    throw const CombinedCallFailed('the reply was not usable JSON');
  }

  final rawScript = (json['script'] as List?) ?? const [];
  if (rawScript.length < 3) {
    throw const CombinedCallFailed('the script came back too short');
  }

  final lines = <String>[];
  final display = <String>[];
  for (var i = 0; i < rawScript.length; i++) {
    final entry = rawScript[i];
    final map = entry is Map<String, dynamic> ? entry : const <String, dynamic>{};

    final textLine = (map['text'] as String?)?.trim() ?? '';
    if (textLine.isEmpty) continue;

    final spoken = (map['speak'] as String?)?.trim() ?? '';
    // Falls back to four seconds apart rather than dropping the line: a missing
    // timestamp is a detail, and the timings get corrected from the real voice later.
    final at = (map['at'] as num?)?.round() ?? (i * 4);
    final stamp = '${at ~/ 60}:${(at % 60).toString().padLeft(2, '0')}';

    lines.add(spoken.isEmpty ? '$stamp $textLine' : '$stamp $textLine | $spoken');
    display.add(textLine);
  }

  if (display.length < 3) {
    throw const CombinedCallFailed('too few usable script lines');
  }

  // The prompts are built against the on-screen text, because that is what the
  // prompts screen will later compare its cache to.
  return StoryPackage(
    scriptLines: lines,
    prompts: _toPromptSet(json, display, _stripFence(text)),
  );
}

/// Asks Gemini to break the story into beats and to describe a picture per line.
Future<PromptSet> generatePrompts({
  required String storyDescription,
  required List<String> scriptLines,
  required int seconds,
  void Function(String message)? onWait,
}) async {
  if (scriptLines.isEmpty) throw Exception('Write the script first.');

  final numbered = [
    for (var i = 0; i < scriptLines.length; i++) '${i + 1}. ${scriptLines[i]}'
  ].join('\n');

  final prompt = '''
You are preparing prompts for an AI image and video generator, for a $seconds second
preschool reel starring Ria (toddler girl), Rio (toddler boy) and Cuty (white bunny).

The story: $storyDescription

The finished voiceover script, one line per moment:
$numbered

$kReelShapeRules

Return ONLY valid JSON, no markdown fence, in exactly this shape:

{
  "title": "short title in Hinglish",
  "hook": "the opening line as a text overlay, a question or a surprise",
  "who": "which characters appear",
  "where": "the setting, e.g. sunny Indian garden",
  "what_starts_it": "one sentence",
  "what_goes_wrong": "one sentence",
  "how_it_gets_worse": "one sentence",
  "how_it_is_solved": "one sentence",
  "ending_line": "the moral, one short line in Hinglish",
  "closing_cta": "a short follow line in Hinglish",
  "cover_hook": "2 to 4 Hinglish words for screen 1, taken from what happens, e.g. Tractor Gayab?!",
  "cover_title": "3 to 5 words for the reel cover, big and curious",
  "moral_line": "the lesson for the second-to-last screen, one warm line a parent would say out loud",
  "cta_line": "the reason to keep this reel, on the last screen, e.g. Save this for tonight's bedtime story",
  "end_question": "one question on the last screen a parent can answer in four words, about their own child",
  "caption": "2 or 3 lines for Instagram, warm, speaking to parents, ending in something they will want to answer",
  "hashtags": ["#exactly", "#five", "#relevant", "#tags", "#here"],
  "pin_comment": "the first comment, pinned. Say one true thing about this situation in a parent's own house, then ask them about theirs. Something answerable in a few words, never yes or no",
  "reply_question": "what to reply to a comment with. Warm, Hinglish, and it ends in a question of its own so the conversation carries on — a reply that only says thank you ends it",
  "best_time": "a suggested posting window for Indian parents of small children, with the day part, e.g. Weekdays 8-9 pm IST",
  "scenes": [
    {"scene": "what the picture shows, one sentence, name the characters in it",
     "expression": "the main character's face, e.g. worried, laughing, proud",
     "beat": "one of Hook, Problem, Conflict, Turn, Solution, Ending",
     "shot": "wide / close-up on face / from above / looking up",
     "key_objects": "the props this moment turns on, e.g. red teddy, spilt milk",
     "dialogue": "what a character says out loud here in Hinglish, or empty"}
  ]
}

Rules:
- "scenes" must have exactly ${scriptLines.length} entries, one per script line, in order.
- Each "scene" describes what is VISIBLE. Framing words go in "shot", not in "scene".
- Vary "shot" across the scenes. All one framing makes a reel look static.
- "beat" must run in order across the scenes: Hook first, Ending last, and every
  story needs a Turn - the moment it changes - somewhere in the middle.
- Do not describe what the characters look like. That is handled elsewhere.
- "hashtags" must have exactly five entries, each starting with #.
- Keep every value under 25 words.

Do not change, replace or invent the problem, the characters, the solution or the
moral. They come from the story above. Your job is to show that story, not write a
different one.
''';

  final response = await geminiPost(
    model: _model,
    apiKey: geminiApiKey,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.7,
        // Roomy: a dozen fields plus one scene per line, and running out of room
        // truncates the JSON, which then fails to parse with no useful message.
        'maxOutputTokens': 8192,
        // Asking for JSON is not the same as getting it — this makes Gemini return
        // parseable JSON instead of JSON wrapped in a markdown fence.
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode)
        : 'Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned nothing for the prompts.');

  final clean = _stripFence(text);
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(clean) as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Gemini did not return usable JSON.\n$text');
  }

  return _toPromptSet(json, scriptLines, clean);
}

/// Turns Gemini's reply into the prompt set. Shared by a fresh call and a saved one,
/// so a story saved last week parses exactly the way it did when it was made.
PromptSet _toPromptSet(
    Map<String, dynamic> json, List<String> scriptLines, String rawJson) {
  final rawScenes = (json['scenes'] as List?) ?? const [];
  final scenes = <ScenePrompt>[];
  for (var i = 0; i < scriptLines.length; i++) {
    // Short by a scene or two is common; fall back to the line itself rather than
    // dropping the picture, since every line needs one.
    final entry = i < rawScenes.length ? rawScenes[i] : null;
    final map = entry is Map<String, dynamic> ? entry : const <String, dynamic>{};
    String read(String key, [String fallback = '']) {
      final value = map[key];
      return (value is String && value.trim().isNotEmpty) ? value.trim() : fallback;
    }

    scenes.add(ScenePrompt(
      scene: read('scene', scriptLines[i]),
      expression: read('expression', 'cheerful'),
      beat: read('beat'),
      shot: read('shot'),
      keyObjects: read('key_objects'),
      dialogue: read('dialogue'),
      overlayText: scriptLines[i],
    ));
  }

  // Exactly five hashtags is asked for; trim or pad rather than trust it.
  final rawTags = (json['hashtags'] as List?) ?? const [];
  final tags = rawTags
      .whereType<String>()
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .map((t) => t.startsWith('#') ? t : '#$t')
      .take(5)
      .toList();

  return PromptSet(
    rawJson: rawJson,
    beats: StoryBeats.fromJson(json),
    scenes: scenes,
    post: PostDetails(
      coverTitle: (json['cover_title'] as String?)?.trim().isNotEmpty == true
          ? (json['cover_title'] as String).trim()
          : 'Ria aur Rio',
      caption: (json['caption'] as String?)?.trim() ?? '',
      hashtags: tags,
      pinComment: (json['pin_comment'] as String?)?.trim() ?? '',
      replyQuestion: (json['reply_question'] as String?)?.trim() ?? '',
      bestTime: (json['best_time'] as String?)?.trim() ?? '',
      coverHook: (json['cover_hook'] as String?)?.trim() ?? '',
      moralLine: (json['moral_line'] as String?)?.trim() ?? '',
      // Falls back to the channel's own line rather than to nothing: a closing screen
      // with no reason to keep the reel is a wasted screen, and every reel has one.
      ctaLine: (json['cta_line'] as String?)?.trim().isNotEmpty == true
          ? (json['cta_line'] as String).trim()
          : kDefaultCtaLine,
      endQuestion: (json['end_question'] as String?)?.trim() ?? '',
    ),
  );
}

/// Removes a ```json fence when one turns up despite responseMimeType.
String _stripFence(String text) {
  final trimmed = text.trim();
  if (!trimmed.startsWith('```')) return trimmed;
  final firstBreak = trimmed.indexOf('\n');
  final end = trimmed.lastIndexOf('```');
  if (firstBreak < 0 || end <= firstBreak) return trimmed;
  return trimmed.substring(firstBreak + 1, end).trim();
}
