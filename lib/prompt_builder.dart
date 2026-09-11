import 'dart:convert';

import 'package:http/http.dart' as http;

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
  const PromptSet({required this.beats, required this.scenes});
}

/// Asks Gemini to break the story into beats and to describe a picture per line.
Future<PromptSet> generatePrompts({
  required String storyDescription,
  required List<String> scriptLines,
  required int seconds,
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
  "scenes": [
    {"scene": "what the picture shows, one sentence, name the characters in it",
     "expression": "the main character's face, e.g. worried, laughing, proud"}
  ]
}

Rules:
- "scenes" must have exactly ${scriptLines.length} entries, one per script line, in order.
- Each "scene" describes what is VISIBLE. No dialogue, no camera directions.
- Do not describe what the characters look like. That is handled elsewhere.
- Keep every value under 25 words.
''';

  final response = await http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
        '$_model:generateContent?key=$geminiApiKey'),
    headers: {'Content-Type': 'application/json'},
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
  ).timeout(_timeout);

  if (response.statusCode != 200) {
    throw Exception('Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned nothing for the prompts.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(_stripFence(text)) as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Gemini did not return usable JSON.\n$text');
  }

  final rawScenes = (json['scenes'] as List?) ?? const [];
  final scenes = <ScenePrompt>[];
  for (var i = 0; i < scriptLines.length; i++) {
    // Short by a scene or two is common; fall back to the line itself rather than
    // dropping the picture, since every line needs one.
    final entry = i < rawScenes.length ? rawScenes[i] : null;
    final map = entry is Map<String, dynamic> ? entry : const <String, dynamic>{};
    scenes.add(ScenePrompt(
      scene: (map['scene'] as String?)?.trim().isNotEmpty == true
          ? (map['scene'] as String).trim()
          : scriptLines[i],
      expression: (map['expression'] as String?)?.trim().isNotEmpty == true
          ? (map['expression'] as String).trim()
          : 'cheerful',
      overlayText: scriptLines[i],
    ));
  }

  return PromptSet(beats: StoryBeats.fromJson(json), scenes: scenes);
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
