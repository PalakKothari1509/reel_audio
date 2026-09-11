import 'dart:convert';

import 'package:http/http.dart' as http;

import 'secrets.dart';

// ── Story ideas ───────────────────────────────────────────────────────────────
//
// Picks a real preschool problem and writes it up in the format the story box wants,
// so the next reel does not start with a blank field.
//
// The list below is the whole point: these are the arguments that actually happen in
// a house with small children. A story invented without one of these to hang on comes
// out as a fable — pleasant, and nothing a parent recognises.

const kStoryAges = ['2-3', '3-4', '4-5', '5-6'];

const kStoryProblems = [
  'Bedtime',
  'Food and eating',
  'Sharing',
  'Tantrum',
  'Doing it myself',
  'School',
  'Brother and sister',
  'Tidying up',
  'Waiting',
  'Losing a game',
  'Making a mistake',
  'Screen time',
  'Brushing teeth',
  'Bath time',
  'Saying sorry',
];

const _model = 'gemini-3.6-flash';
const _timeout = Duration(seconds: 60);

class StoryIdea {
  final String title;
  final String hook;
  final String problem;
  final String twist;
  final String solution;
  final String moral;

  const StoryIdea({
    required this.title,
    required this.hook,
    required this.problem,
    required this.twist,
    required this.solution,
    required this.moral,
  });

  /// Laid out the way the story box expects, so it can be dropped straight in.
  String get asStoryText => 'Who: Ria, Rio, Cuty\n'
      'What starts it: $problem\n'
      'What goes wrong: $twist\n'
      'How it is solved: $solution\n'
      'Ending line: $moral';
}

// ── Checking a story before it costs anything ─────────────────────────────────

class StoryCheck {
  final int score;
  /// What the story already does, so the check is not only a list of complaints.
  final List<String> good;
  /// What is weak, in the order worth fixing.
  final List<String> missing;
  final String verdict;

  const StoryCheck({
    required this.score,
    required this.good,
    required this.missing,
    required this.verdict,
  });
}

/// Reads a story and says whether it will make a reel worth watching.
///
/// Worth doing before the script, not after: a weak story produces a weak script, a
/// weak voiceover and seven weak pictures, and by then it has cost twenty minutes.
/// Ten seconds here saves all of that.
Future<StoryCheck> checkStory(String story) async {
  if (story.trim().length < 15) {
    throw Exception('Write a bit more of the story first.');
  }

  final prompt = '''
Judge this story for a 30 second Instagram reel for Indian parents of preschoolers.

$story

Be honest and specific. A story that is merely pleasant scores low — the test is
whether a parent stops scrolling and recognises their own house.

Return ONLY valid JSON:

{
  "score": 7,
  "good": ["what already works, short phrases"],
  "missing": ["what is weak, most important first, short phrases"],
  "verdict": "one sentence saying whether to use it or rework it"
}

Check for: a real everyday problem, a clear start, the problem actually shown, a moment
of feeling, a turn where it changes, a solution the child reaches, a warm ending,
age-appropriate, nothing frightening, and enough to fill 30 seconds but not 3 minutes.

"score" is 1 to 10.
''';

  final response = await http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
        '$_model:generateContent?key=$geminiApiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        // Low: a critique should be the same twice for the same story, or it is
        // not a judgement, it is a mood.
        'temperature': 0.3,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      },
    }),
  ).timeout(_timeout);

  if (response.statusCode != 200) {
    throw Exception('Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned no answer.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.\n$text');
  }

  List<String> list(String key) => ((json[key] as List?) ?? const [])
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  return StoryCheck(
    score: (json['score'] is num) ? (json['score'] as num).round().clamp(1, 10) : 5,
    good: list('good'),
    missing: list('missing'),
    verdict: (json['verdict'] as String?)?.trim() ?? '',
  );
}

/// Asks Gemini for one story built on a real problem at a real age.
Future<StoryIdea> generateStoryIdea({
  required String age,
  required String problem,
}) async {
  final prompt = '''
Think of one short story for an Instagram reel for Indian parents of preschoolers.

The child is $age years old. The problem is: $problem.

It must be a problem a parent watching would recognise from their own house this week.
Not a fable, not talking animals teaching lessons, not a moral dressed up as a story.
Something small, ordinary and true — the kind of thing that happens before breakfast.

Characters: Ria (little girl), Rio (little boy), Cuty (their pet bunny). Use only the
ones the story needs. A grown-up (Mumma, Papa, Daadi) only if the story needs one.

Return ONLY valid JSON:

{
  "title": "short Hinglish title",
  "hook": "the first line, said out loud, that makes a parent stop scrolling",
  "problem": "what the child does, one sentence",
  "twist": "what makes it worse or funnier, one sentence",
  "solution": "how it resolves, one sentence, no adult lecturing",
  "moral": "one short warm line in Hinglish"
}

The child should work it out or be shown, not told off. Keep every value under 25 words.
''';

  final response = await http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
        '$_model:generateContent?key=$geminiApiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        // Higher than the script call: this one is meant to surprise you, and a
        // predictable idea generator returns the same story every time.
        'temperature': 1.0,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      },
    }),
  ).timeout(_timeout);

  if (response.statusCode != 200) {
    throw Exception('Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned no idea.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.\n$text');
  }

  String read(String key, String fallback) {
    final value = json[key];
    return (value is String && value.trim().isNotEmpty) ? value.trim() : fallback;
  }

  return StoryIdea(
    title: read('title', 'Ria aur Rio'),
    hook: read('hook', ''),
    problem: read('problem', ''),
    twist: read('twist', ''),
    solution: read('solution', ''),
    moral: read('moral', ''),
  );
}
