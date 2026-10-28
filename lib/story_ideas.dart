import 'dart:convert';

import 'package:flutter/material.dart';

import 'gemini_call.dart';
import 'prompts.dart';
import 'secrets.dart';
import 'prompt_preview.dart';

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
  'Brushing teeth',
  'Bath time',
  'Refusing vegetables',
  'Too much tablet time',
  'Not cleaning up toys',
  'Not wanting to wear shoes',
  'Bedtime',
  'Not sharing a toy',
  'Upset at losing a game',
  'Not wanting to leave the park',
  'Wanting a toy in a shop',
  'Interrupting',
  'Refusing a small task',
  'Scared to try something new',
  'Losing something through carelessness',
  'Making a mess',
  'Not listening when called',
  'Fighting over toys',
  'Not wanting to wait',
  'Main khud karungi',
  'School',
  'Brother and sister',
  'Making a mistake',
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
//
// Lite models (gemini-3.5-flash-lite and below) reject thinkingConfig.thinkingBudget
// with a 400 INVALID_ARGUMENT error. All flash models (gemini-3.5-flash+) accept it.
const _lightModel = 'gemini-3.5-flash';
const _fullModel = 'gemini-3.8-flash';
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
  /// Five cover hooks written with the idea, so one can be chosen before the script.
  final List<HookChoice> hooks;

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
    this.hooks = const [],
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
  /// What the story already does, so the check is not only a list of complaints.
  final List<String> good;
  /// What is weak, in the order worth fixing.
  final List<String> missing;
  final String verdict;
  final List<CheckRow> rows;
  /// Five cover hooks for the story, in the same request as the check — so a hook can
  /// be chosen before the script is written, without spending anything extra.
  final List<HookChoice> hooks;

  const StoryCheck({
    required this.good,
    required this.missing,
    required this.verdict,
    this.rows = const [],
    this.hooks = const [],
    this.score,
  });

  /// Optional override for score; when null, score is computed from [rows].
  final int? score;

  /// Score equals pass count, clamped to 1..10. Computed from rows so it
  /// always reflects the actual pass/fail state, unless explicitly overridden.
  int get effectiveScore =>
      score ?? rows.where((r) => r.pass).length.clamp(1, 10);

  /// Worked out here from the score rather than trusted from the model, so a 7 always
  /// means the same thing. Below 7 is not worth an evening of making pictures for.
  /// Blocker checks (Hook, Real-life problem) cap the band at 'Improve' —
  /// even a 10-score story cannot be 'Ready' if those foundational checks fail.
  String get band {
    final hasBlocker = rows.any((r) =>
        !r.pass && (r.name == 'Hook' || r.name == 'Real-life problem'));
    if (hasBlocker) return effectiveScore >= 9 ? 'Improve' : effectiveScore >= 7 ? 'Improve' : 'Rewrite';
    return effectiveScore >= 9 ? 'Ready' : effectiveScore >= 7 ? 'Improve' : 'Rewrite';
  }

  /// Derives the primary content purpose from the check results.
  ///
  /// Maps the passing checks to one of the five purposes:
  /// RELATE, LEARN, FEEL, LAUGH, or SHARE.
  String get contentPurpose {
    final passes = rows.where((r) => r.pass).map((r) => r.name.toLowerCase()).toSet();
    if (passes.contains('real-life problem')) return 'RELATE';
    if (passes.contains('child learns naturally')) return 'LEARN';
    if (passes.contains('emotion')) return 'FEEL';
    if (passes.contains('hook') && passes.contains('curiosity')) return 'LAUGH';
    if (passes.contains('share value')) return 'SHARE';
    return 'RELATE';
  }
}

/// Builds the checkStory prompt without sending it.
/// Use with [showPromptPreview] to preview before sending.
String buildCheckStoryPrompt(String story) {
  return '''Judge this story for a 30 second Instagram reel for Indian parents of preschoolers.

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
  "hook_options": [
    {"type": "Curiosity", "text": "e.g. Rio Ne Kya Dekha?!"},
    {"type": "Parent relatable", "text": "e.g. Mumma Haar Gayi?"},
    {"type": "Situation", "text": "e.g. Brush Nahi Karungi?!"},
    {"type": "Mystery", "text": "e.g. Phir Kya Hua?!"},
    {"type": "Emotional", "text": "e.g. Ye Toh Problem Ho Gayi!"}
  ],
  "verdict": "one sentence saying whether to use it or how to rework it"
}

"hook_options" are five cover hooks for this story: 2 to 4 Hinglish words, scroll-stopping,
true to what actually happens in it, and genuinely different from each other — not five
rewordings of one line. The examples show the style only; write new ones for this story.

"score" is 1 to 10 and should roughly equal the number of checks passed. Be strict:
9 or 10 means ready to make today.
''';
}

/// Generation config for checkStory
const Map<String, dynamic> kCheckStoryGenConfig = {
  'temperature': 0.3,
  'maxOutputTokens': 2048,
  'thinkingConfig': {'thinkingBudget': 0},
  'responseMimeType': 'application/json',
};

/// Calls checkStory with a prompt preview dialog first.
/// Returns the StoryCheck result after user confirms.
Future<StoryCheck> checkStoryWithPreview({
  required BuildContext context,
  required String story,
  String? apiKey,
  void Function(String message)? onWait,
  bool useSheet = false,
}) async {
  final prompt = buildCheckStoryPrompt(story);
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  return prompt.withPromptPreview<StoryCheck>(
    context: context,
    title: 'Story Quality Check',
    modelName: _lightModel,
    generationConfig: kCheckStoryGenConfig,
    useSheet: useSheet,
    onSend: () async {
      final response = await geminiPost(
        model: _lightModel,
        fallbackModel: _fullModel,
        apiKey: key,
        timeout: _timeout,
        onWait: onWait,
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': kCheckStoryGenConfig,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.statusCode == 503 || response.statusCode == 429
            ? geminiBusyMessage(response.statusCode, response.body)
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
        good: list('good'),
        missing: list('missing'),
        verdict: (json['verdict'] as String?)?.trim() ?? '',
        rows: rows,
        hooks: hookChoicesFrom(json['hook_options']),
      );
    },
  );
}

/// Reads a story and says whether it will make a reel worth watching.
///
/// Worth doing before the script, not after: a weak story produces a weak script, a
/// weak voiceover and seven weak pictures, and by then it has cost twenty minutes.
/// Ten seconds here saves all of that.
Future<StoryCheck> checkStory(String story,
    {String? apiKey, void Function(String message)? onWait}) async {
  if (story.trim().length < 15) {
    throw Exception('Write a bit more of the story first.');
  }

  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  final prompt = buildCheckStoryPrompt(story);

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _fullModel,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': kCheckStoryGenConfig,
    }),
  );

  if (response.statusCode != 200) {
    // Still busy after every retry. Say that plainly — the raw JSON reads like the
    // app is broken when the only thing wrong is Google's load at this minute.
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
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
    good: list('good'),
    missing: list('missing'),
    verdict: (json['verdict'] as String?)?.trim() ?? '',
    rows: rows,
    hooks: hookChoicesFrom(json['hook_options']),
  );
}

/// Asks Gemini for one story built on a real problem at a real age.
Future<StoryIdea> generateStoryIdea({
  required String age,
  required String problem,
  String? apiKey,
  void Function(String message)? onWait,
}) async {
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;
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
  "moral": "the lesson the child watching takes away, one short warm Hinglish line. A lesson, not a summary of what happened",
  "hook_options": [
    {"type": "Curiosity", "text": "2-4 Hinglish words"},
    {"type": "Parent relatable", "text": "2-4 Hinglish words"},
    {"type": "Situation", "text": "2-4 Hinglish words"},
    {"type": "Mystery", "text": "2-4 Hinglish words"},
    {"type": "Emotional", "text": "2-4 Hinglish words"}
  ]
}

"ending_line" is spoken by a character. "moral" is what the reel leaves the parent
with. They are not the same sentence.

"hook_options" are five cover hooks for this story, genuinely different from each other,
each true to what happens in it — not five rewordings of the same line.

The child should work it out or be shown, not told off. Keep every value under 25 words.
''';

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _fullModel,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        // Higher than the script call: this one is meant to surprise you, and a
        // predictable idea generator returns the same story every time.
'temperature': 1.0,
          'maxOutputTokens': 2048,
          'thinkingConfig': {'thinkingBudget': 0},
          'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    // Still busy after every retry. Say that plainly — the raw JSON reads like the
    // app is broken when the only thing wrong is Google's load at this minute.
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
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
    hooks: hookChoicesFrom(json['hook_options']),
  );
}

/// Hook options from a reply, skipping empty or repeated ones. An empty list just means
/// no choices are shown, and the script request will offer its own later.
List<HookChoice> hookChoicesFrom(Object? value) {
  if (value is! List) return const [];
  final seen = <String>{};
  return value
      .whereType<Map<String, dynamic>>()
      .map((m) => HookChoice(
            (m['type'] as String?)?.trim() ?? '',
            (m['text'] as String?)?.trim() ?? ''))
      .where((c) => c.text.isNotEmpty && seen.add(c.text.toLowerCase()))
      .take(5)
      .toList();
}

// ── Replying to comments ──────────────────────────────────────────────────────
//
// Paste a comment, get five replies that suit what KIND of comment it is. A compliment,
// a parent's own story, a question, a piece of advice and a disagreement each want a
// different answer, and one generic "Thank you ❤️" for all of them is what makes a
// page feel automated rather than run by a person.

/// The kinds of comment the assistant recognises, in the order they are most common.
const kCommentTypes = [
  'Compliment',
  'Funny / relatable',
  'Parent experience',
  'Question',
  'Advice',
  'Agreement',
  'Disagreement',
  'Character love',
  'Learning-related',
  'Emotional reaction',
  'Negative / spam',
];

class ReplySuggestions {
  final String type;
  final List<String> replies;
  /// A short word of advice when the comment needs care — a worried parent, a hostile
  /// comment — or empty.
  final String note;
  const ReplySuggestions(this.type, this.replies, this.note);
}

/// Five reply options for one comment, suited to its type.
///
/// [storyContext] is the reel's title and lesson when opened from a story, so replies
/// can refer to what actually happened in it. Empty works too.
Future<ReplySuggestions> suggestReplies(String comment,
    {String? apiKey, String storyContext = '', void Function(String message)? onWait}) async {
  if (comment.trim().isEmpty) throw Exception('Paste the comment first.');
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  final prompt = '''
You reply to comments on "Fun Learning With Palak", an Instagram page of short original
story reels for Indian parents of children aged 2 to 6. The stories star Ria (curious,
expressive, sometimes stubborn), Rio (playful, energetic) and Cuty (a playful bunny).
Brand line: "Little Stories, Big Lessons ❤️".
${storyContext.trim().isEmpty ? '' : '\nThe reel this comment is on: ${storyContext.trim()}\n'}
The comment:
"""
${comment.trim()}
"""

First decide which ONE type it is: ${kCommentTypes.join(', ')}.

Then write five replies suited to THAT type:
- Compliment or character love: warm and specific, not just "thank you". A reply from
  Cuty or Ria now and then is welcome ("Cuty is sending a bunny hug! 🐰").
- Funny / relatable or parent experience: laugh along, relate, sometimes ask one light
  follow-up question about their child.
- Question: actually answer it, briefly and usefully. For health or development worries,
  be kind and suggest checking with their paediatrician — never give medical advice.
- Advice: thank them genuinely and engage with the idea respectfully.
- Agreement: build on what they said.
- Disagreement: polite, never defensive, open to their view, no arguing.
- Learning-related: connect to the lesson in a natural way.
- Emotional reaction: gentle and caring.
- Negative / spam: replies should be calm and minimal; also say in "note" that not
  replying at all may be better.

Every reply must:
- Sound like a real person running a small page, not a brand account or a bot.
- Be in the same language the commenter used (English, Hinglish or Hindi).
- Be short — one or two sentences — and the five must be genuinely different from each
  other in wording and approach, not five versions of one line.
- Use at most one or two emoji, and not in every reply.
- Never say "follow for more", ask for likes, follows, shares or tags, or use any
  engagement bait.

Return ONLY valid JSON:

{
  "type": "one of the types above",
  "replies": ["five different replies"],
  "note": "a short tip if this comment needs care, otherwise an empty string"
}
''';

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _fullModel,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        // High: five replies that all sound alike defeat the purpose of having five.
'temperature': 0.9,
          'maxOutputTokens': 2048,
          'thinkingConfig': {'thinkingBudget': 0},
          'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned no replies.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.\n$text');
  }

  final replies = ((json['replies'] as List?) ?? const [])
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .take(5)
      .toList();
  if (replies.isEmpty) throw Exception('Gemini returned no replies. Try again.');

  final type = (json['type'] as String?)?.trim() ?? '';
  return ReplySuggestions(
    kCommentTypes.contains(type) ? type : 'Other',
    replies,
    (json['note'] as String?)?.trim() ?? '',
  );
}

// ── Stage 1: BeatSheet — idea with beats, no timing ────────────────────────────
//
// A BeatSheet is what gets stored in content_ideas.md under "Stage 1: Base Idea".
// It has the five core story beats plus an optional stretch beat. No timestamps,
// no scene numbers — that comes in Stage 2 when you pick a length.

/// One beat in a BeatSheet, identified by index.
enum BeatIndex {
  setup(0),
  problem(1),
  escalation(2),
  stretch(3),
  turn(4),
  payoff(5);

  final int value;
  const BeatIndex(this.value);
}

/// The five core beats of a reel idea, plus an optional stretch beat.
///
/// Stage 1 model — no timing. Length is decided later in Stage 2.
class BeatSheet {
  final String id;
  final String title;
  final List<String> characters;
  final String where;
  final String hook;
  final String beat1Setup;        // what's normal at the start
  final String beat2Problem;       // what goes wrong
  final String beat3Escalation;   // how it gets worse
  final String beat4Turn;          // the moment things change
  final String beat5Payoff;        // the funny or warm ending
  final String? stretchBeat;       // optional extra between 2 and 4
  final String endingLine;
  final String closingCta;
  final String? caption;
  final List<String> hashtags;     // exactly 5
  final int? bestLength;           // 20, 30, or null (flexible)

  const BeatSheet({
    required this.id,
    required this.title,
    required this.characters,
    required this.where,
    required this.hook,
    required this.beat1Setup,
    required this.beat2Problem,
    required this.beat3Escalation,
    required this.beat4Turn,
    required this.beat5Payoff,
    this.stretchBeat,
    required this.endingLine,
    required this.closingCta,
    this.caption,
    this.hashtags = const [],
    this.bestLength,
  });

  /// Whether a stretch beat is available — determines if 30s works well.
  bool get hasStretchBeat => stretchBeat != null && stretchBeat!.trim().isNotEmpty;

  /// The five required beats as a list (index 0 = setup, 4 = payoff).
  List<String> get beats => [
    beat1Setup,
    beat2Problem,
    beat3Escalation,
    beat4Turn,
    beat5Payoff,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'characters': characters,
    'where': where,
    'hook': hook,
    'beat1_setup': beat1Setup,
    'beat2_problem': beat2Problem,
    'beat3_escalation': beat3Escalation,
    'beat4_turn': beat4Turn,
    'beat5_payoff': beat5Payoff,
    'stretch_beat': stretchBeat,
    'ending_line': endingLine,
    'closing_cta': closingCta,
    'caption': caption,
    'hashtags': hashtags,
    'best_length': bestLength,
  };

  factory BeatSheet.fromJson(Map<String, dynamic> json) {
    String read(String key, String fallback) {
      final value = json[key];
      return (value is String && value.trim().isNotEmpty) ? value.trim() : fallback;
    }

    return BeatSheet(
      id: read('id', ''),
      title: read('title', ''),
      characters: ((json['characters'] as List?)?.cast<String>() ?? [])
          .where((s) => s.trim().isNotEmpty).toList(),
      where: read('where', ''),
      hook: read('hook', ''),
      beat1Setup: read('beat1_setup', ''),
      beat2Problem: read('beat2_problem', ''),
      beat3Escalation: read('beat3_escalation', ''),
      beat4Turn: read('beat4_turn', ''),
      beat5Payoff: read('beat5_payoff', ''),
      stretchBeat: json['stretch_beat'] as String?,
      endingLine: read('ending_line', ''),
      closingCta: read('closing_cta', ''),
      caption: json['caption'] as String?,
      hashtags: ((json['hashtags'] as List?)?.cast<String>() ?? [])
          .where((s) => s.trim().isNotEmpty).toList(),
      bestLength: json['best_length'] as int?,
    );
  }

  BeatSheet copyWith({
    String? id,
    String? title,
    List<String>? characters,
    String? where,
    String? hook,
    String? beat1Setup,
    String? beat2Problem,
    String? beat3Escalation,
    String? beat4Turn,
    String? beat5Payoff,
    String? stretchBeat,
    String? endingLine,
    String? closingCta,
    String? caption,
    List<String>? hashtags,
    int? bestLength,
  }) {
    return BeatSheet(
      id: id ?? this.id,
      title: title ?? this.title,
      characters: characters ?? this.characters,
      where: where ?? this.where,
      hook: hook ?? this.hook,
      beat1Setup: beat1Setup ?? this.beat1Setup,
      beat2Problem: beat2Problem ?? this.beat2Problem,
      beat3Escalation: beat3Escalation ?? this.beat3Escalation,
      beat4Turn: beat4Turn ?? this.beat4Turn,
      beat5Payoff: beat5Payoff ?? this.beat5Payoff,
      stretchBeat: stretchBeat ?? this.stretchBeat,
      endingLine: endingLine ?? this.endingLine,
      closingCta: closingCta ?? this.closingCta,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      bestLength: bestLength ?? this.bestLength,
    );
  }
}

/// Asks Gemini for a Stage 1 base idea — beats only, no timing.
Future<BeatSheet> generateBeatSheet({
  required String ideaDescription,
  required String id,
  String? apiKey,
  void Function(String message)? onWait,
}) async {
  final key = (apiKey ?? '').trim().isNotEmpty ? apiKey!.trim() : geminiApiKey;

  final prompt = '''
Think of one short story for an Instagram reel for Indian parents of preschoolers.

THE IDEA: $ideaDescription

Characters: Ria, Rio, Cuty, Mumma, Papa. Use only the ones the story needs.

Do NOT decide the length. Write beats, not timed scenes. Return ONLY valid JSON:

{
  "title": "short Hinglish title with emoji",
  "characters": ["ria", "mumma"],
  "where": "setting in 2-3 words",
  "hook": "one-line hook",
  "beat1_setup": "what's normal at the start",
  "beat2_problem": "what goes wrong",
  "beat3_escalation": "how it gets worse",
  "beat4_turn": "the moment things change",
  "beat5_payoff": "the funny or warm ending",
  "stretch_beat": "an extra moment between problem and turn, or null if none",
  "ending_line": "one short warm line in Hinglish",
  "closing_cta": "a short follow line",
  "caption": "2-3 lines for Instagram",
  "hashtags": ["exactly", "five", "relevant", "tags", "here"],
  "best_length": 20 or 30 or null
}

Every value should be under 25 words. The child should work it out or be shown,
not told off. Be specific to an Indian household.
''';

  final response = await geminiPost(
    model: _lightModel,
    fallbackModel: _fullModel,
    apiKey: key,
    timeout: _timeout,
    onWait: onWait,
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 1.0,
        'maxOutputTokens': 2048,
        'thinkingConfig': {'thinkingBudget': 0},
        'responseMimeType': 'application/json',
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(response.statusCode == 503 || response.statusCode == 429
        ? geminiBusyMessage(response.statusCode, response.body)
        : 'Gemini error ${response.statusCode}: ${response.body}');
  }

  final body = jsonDecode(response.body);
  final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
  if (text.trim().isEmpty) throw Exception('Gemini returned no beat sheet.');

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text.trim()) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('Gemini did not return usable JSON.\n$text');
  }

  return BeatSheet.fromJson(json).copyWith(id: id);
}
