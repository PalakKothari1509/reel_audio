import 'dart:convert';

import 'gemini_call.dart';
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

// ── Which model does the small jobs ───────────────────────────────────────────
//
// Idea and Check are short: a paragraph in, a paragraph out. They do not need the
// model the script uses, and pointing them at it was costing more than quality.
//
// The real gain is not price, it is the quota. Free-tier limits are counted PER
// MODEL, so every Idea and every Check was eating requests the script and the
// prompts needed — and running out mid-reel is what that feels like from the
// outside. On a separate model they come out of a separate allowance.
//
// If this name is not available on the key, the first call 404s once and everything
// falls back to the full model from then on. Never worse than before, usually better.
const _lightModel = 'gemini-3.6-flash-lite';
const _fullModel = 'gemini-3.6-flash';
const _timeout = Duration(seconds: 60);

class StoryIdea {
  final String title;
  final String hook;
  final String who;
  final String where;
  final String problem;
  final String twist;
  final String worse;
  final String solution;
  final String endingLine;
  final String moral;

  const StoryIdea({
    required this.title,
    required this.hook,
    required this.who,
    required this.where,
    required this.problem,
    required this.twist,
    required this.worse,
    required this.solution,
    required this.endingLine,
    required this.moral,
  });

  /// Laid out the way the story box expects, so it can be dropped straight in.
  ///
  /// Every field the blank template has, in the same order. It used to fill five of
  /// them and leave the rest out, so an idea and a hand-written story arrived at the
  /// script generator in two different shapes and the idea always had less to work on.
  String get asStoryText => 'Hook: $hook\n'
      'Who: $who\n'
      'Where: $where\n'
      'What starts it: $problem\n'
      'What goes wrong: $twist\n'
      'How it gets worse: $worse\n'
      'How it is solved: $solution\n'
      'Ending line: $endingLine\n'
      'Moral: $moral';
}

// ── Checking a story before it costs anything ─────────────────────────────────

/// One of the ten things a story is judged on.
class CheckRow {
  final String name;
  final bool pass;
  /// Why, in a few words — mostly useful when it did not pass.
  final String note;
  const CheckRow(this.name, this.pass, this.note);
}

/// The ten requirements, in the order they matter to a parent scrolling past.
///
/// Fixed here rather than left to the model, so every story is held to the same
/// standard and two checks of two stories can actually be compared.
const kStoryChecks = [
  'Real-life problem',
  'Hook',
  'Curiosity',
  'Emotion',
  'Child learns naturally',
  'Satisfying ending',
  'Save value',
  'Share value',
  'Originality',
  'Character fit',
];

class StoryCheck {
  final int score;
  /// What the story already does, so the check is not only a list of complaints.
  final List<String> good;
  /// What is weak, in the order worth fixing.
  final List<String> missing;
  final String verdict;
  final List<CheckRow> rows;

  const StoryCheck({
    required this.score,
    required this.good,
    required this.missing,
    required this.verdict,
    this.rows = const [],
  });

  /// Worked out here from the score rather than trusted from the model, so a 7 always
  /// means the same thing. Below 7 is not worth an evening of making pictures for.
  String get band => score >= 9 ? 'Ready' : score >= 7 ? 'Improve' : 'Rewrite';
}

/// Reads a story and says whether it will make a reel worth watching.
///
/// Worth doing before the script, not after: a weak story produces a weak script, a
/// weak voiceover and seven weak pictures, and by then it has cost twenty minutes.
/// Ten seconds here saves all of that.
Future<StoryCheck> checkStory(String story,
    {void Function(String message)? onWait}) async {
  if (story.trim().length < 15) {
    throw Exception('Write a bit more of the story first.');
  }

  final prompt = '''
Judge this story for a 30 second Instagram reel for Indian parents of preschoolers.

$story

Be honest and specific. A story that is merely pleasant scores low — the test is
whether a parent stops scrolling, watches to the end, and saves or shares it.

Judge it on exactly these ten, one entry each, in this order:
1. Real-life problem — a parent recognises it from their own house.
2. Hook — the opening makes you want to keep watching.
3. Curiosity — something stays unresolved long enough to hold attention.
4. Emotion — a genuine feeling, not a forced one.
5. Child learns naturally — through what happens, NOT an adult explaining, NOT a
   "say sorry" scene. A story where an adult explains the lesson FAILS this.
6. Satisfying ending — it lands; it does not just stop.
7. Save value — a parent would want to keep it to show their child later.
8. Share value — a parent would send it to another parent.
9. Originality — not the obvious version every page already posted.
10. Character fit — Ria, Rio and Cuty belong in it and act like themselves.

Return ONLY valid JSON:

{
  "score": 7,
  "checks": [
    {"name": "Real-life problem", "pass": true, "note": "few words why"}
  ],
  "good": ["what already works, short phrases"],
  "missing": ["the most useful fixes, most important first, short and concrete"],
  "verdict": "one sentence saying whether to use it or how to rework it"
}

"score" is 1 to 10 and should roughly equal the number of checks passed. Be strict:
9 or 10 means ready to make today.
''';

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _fullModel,
    apiKey: geminiApiKey,
    timeout: _timeout,
    onWait: onWait,
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
  );

  if (response.statusCode != 200) {
    // Still busy after every retry. Say that plainly — the raw JSON reads like the
    // app is broken when the only thing wrong is Google's load at this minute.
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode)
        : 'Gemini error ${response.statusCode}: ${response.body}');
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

  // Matched to the fixed list by position, and named from it, so a check the model
  // renamed or skipped still lands on the right row instead of shifting every row after.
  final rawChecks = ((json['checks'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>().toList();
  final rows = <CheckRow>[
    for (var i = 0; i < kStoryChecks.length && i < rawChecks.length; i++)
      CheckRow(
        kStoryChecks[i],
        rawChecks[i]['pass'] == true,
        (rawChecks[i]['note'] as String?)?.trim() ?? ''),
  ];

  return StoryCheck(
    score: (json['score'] is num) ? (json['score'] as num).round().clamp(1, 10) : 5,
    good: list('good'),
    missing: list('missing'),
    verdict: (json['verdict'] as String?)?.trim() ?? '',
    rows: rows,
  );
}

/// Asks Gemini for one story built on a real problem at a real age.
Future<StoryIdea> generateStoryIdea({
  required String age,
  required String problem,
  void Function(String message)? onWait,
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
  "hook": "the first line said out loud. It starts in the middle of the trouble, already happened, and opens a question it does not answer. No introductions, no 'Ek baar ki baat hai'",
  "who": "only the characters this story actually needs, comma separated",
  "where": "where it happens, e.g. Indian home kitchen, warm morning light",
  "problem": "what the child does, one sentence",
  "twist": "what goes wrong, one sentence",
  "worse": "how it gets worse or funnier after that, one sentence",
  "solution": "how it resolves, one sentence, no adult lecturing",
  "ending_line": "the last line said out loud in the story, in Hinglish",
  "moral": "the lesson the child watching takes away, one short warm Hinglish line. A lesson, not a summary of what happened"
}

"ending_line" is spoken by a character. "moral" is what the reel leaves the parent
with. They are not the same sentence.

The child should work it out or be shown, not told off. Keep every value under 25 words.
''';

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _fullModel,
    apiKey: geminiApiKey,
    timeout: _timeout,
    onWait: onWait,
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
  );

  if (response.statusCode != 200) {
    // Still busy after every retry. Say that plainly — the raw JSON reads like the
    // app is broken when the only thing wrong is Google's load at this minute.
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode)
        : 'Gemini error ${response.statusCode}: ${response.body}');
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
    who: read('who', 'Ria, Rio, Cuty'),
    where: read('where', 'Indian home, warm daylight'),
    problem: read('problem', ''),
    twist: read('twist', ''),
    worse: read('worse', ''),
    solution: read('solution', ''),
    // Falls back to the moral rather than to nothing: a blank ending line in the box
    // reads as a field you forgot to fill in.
    endingLine: read('ending_line', read('moral', '')),
    moral: read('moral', ''),
  );
}
