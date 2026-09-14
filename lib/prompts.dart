import 'characters.dart';

// ── Prompts for the AI tools that make the pictures and the video ─────────────
//
// The app writes the story and the script; these turn that into prompts you paste
// into an image or video generator.
//
// The character block below is the whole point. Describe "Ria, a toddler girl" and
// you get a different child every time — different hair, different face, nothing that
// looks like a series. Repeating the exact same wording in every prompt is what keeps
// her the same person from one reel to the next, so it is written once here and never
// paraphrased.

/// The cast, written out for a prompt. Descriptions go in exactly as saved.
///
/// Only characters that actually have a description are listed — an empty one would
/// read as "- MUM:" and leave the generator to invent her, which is the problem this
/// whole file exists to avoid.
String buildCharacterBlock(List<CharacterRef> cast) {
  final lines = cast
      .where((c) => c.description.trim().isNotEmpty)
      .map((c) => '- ${c.name.toUpperCase()}: ${c.description.trim()}');
  return lines.isEmpty ? '(no characters saved yet)' : lines.join('\n');
}

const _style = 'Soft 3D Pixar/Disney-style render, warm natural lighting, '
    'semi-realistic quality. NOT flat 2D, NOT kawaii-chibi.';

/// Everything a video prompt needs that the story itself has to supply.
class StoryBeats {
  final String title;
  final String hook;
  final String who;
  final String where;
  final String whatStartsIt;
  final String whatGoesWrong;
  final String howItGetsWorse;
  final String howItIsSolved;
  final String endingLine;
  final String closingCta;

  const StoryBeats({
    required this.title,
    required this.hook,
    required this.who,
    required this.where,
    required this.whatStartsIt,
    required this.whatGoesWrong,
    required this.howItGetsWorse,
    required this.howItIsSolved,
    required this.endingLine,
    required this.closingCta,
  });

  /// Anything Gemini leaves out falls back to a usable line rather than an empty slot.
  factory StoryBeats.fromJson(Map<String, dynamic> json) {
    String read(String key, String fallback) {
      final value = json[key];
      return (value is String && value.trim().isNotEmpty) ? value.trim() : fallback;
    }

    return StoryBeats(
      title:          read('title', 'Ria aur Rio ki kahani'),
      hook:           read('hook', 'Arey! Ab kya hoga?'),
      who:            read('who', 'Ria, Rio, Cuty'),
      where:          read('where', 'Indian home, warm daylight'),
      whatStartsIt:   read('what_starts_it', ''),
      whatGoesWrong:  read('what_goes_wrong', ''),
      howItGetsWorse: read('how_it_gets_worse', ''),
      howItIsSolved:  read('how_it_is_solved', ''),
      endingLine:     read('ending_line', 'Sharing se sab khush!'),
      closingCta:     read('closing_cta', 'Follow for more stories!'),
    );
  }
}

/// One picture: what is happening in it, and the face that goes with it.
class ScenePrompt {
  final String scene;
  final String expression;
  /// How the picture is framed — close-up, wide, from above. Nothing is filmed; this is
  /// only the wording a generator understands. Without it every picture comes out as the
  /// same flat mid-shot and the reel looks static.
  final String shot;
  /// Where this moment sits in the story: Hook, Problem, Conflict, Turn, Solution or
  /// Ending. Told which job a picture is doing, a generator draws it differently — a
  /// Hook has to stop someone scrolling, an Ending has to feel warm.
  final String beat;
  /// The props the story turns on — the teddy, the carrot, the spilt milk. Named so
  /// they actually appear, rather than being implied by the action and then missing.
  final String keyObjects;
  /// What the character says out loud in this moment, in Hinglish. Empty when nobody
  /// speaks. Separate from the narration, which is the voice over the top.
  final String dialogue;
  /// The script line this picture belongs to, so the overlay text matches the voice.
  final String overlayText;

  const ScenePrompt({
    required this.scene,
    required this.expression,
    required this.overlayText,
    this.shot = '',
    this.keyObjects = '',
    this.beat = '',
    this.dialogue = '',
  });
}

// ── The brand ─────────────────────────────────────────────────────────────────

/// Closing card, the same on every reel so the channel is recognisable.
const kBrandName = 'Fun Learning With Palak';
const kBrandTagline = 'Little Stories • Big Lessons';

/// Used on the closing screen when Gemini does not write one.
///
/// A reason to keep the reel rather than an instruction to follow. Saving is the
/// thing Instagram counts hardest, and a parent will save a bedtime story long
/// before they will follow a stranger who told them to.
const kDefaultCtaLine = 'Save this for tonight\'s bedtime story';

/// Everything needed to actually post the reel.
class PostDetails {
  final String coverTitle;
  final String caption;
  final List<String> hashtags;
  /// Posted as your own first comment and pinned. Somewhere to put a question or an
  /// invitation without making the caption longer than anyone will read.
  final String pinComment;
  /// One question to reply to commenters with. A reply that asks something keeps the
  /// conversation going, where "thank you!" ends it.
  final String replyQuestion;
  /// A suggested posting window — a starting point, not a fact. See the note below.
  final String bestTime;

  /// Two to four words, drawn from what actually happens. Drawn big across the first
  /// picture, which doubles as the cover — the only thing most people ever see.
  final String coverHook;

  /// The lesson, on its own screen near the end. Separate from the last spoken line
  /// because a moral read aloud and a moral shown in writing are not the same length.
  final String moralLine;

  /// The line on the closing screen that gives a parent a reason to keep the reel:
  /// saving it for bedtime, showing it to a child later. A reason to save beats an
  /// instruction to follow, because saving is the thing Instagram counts hardest.
  final String ctaLine;

  /// A question on the last screen. Comments are what keep a reel alive after the
  /// first hour, and people answer a question far more readily than they volunteer
  /// an opinion.
  final String endQuestion;

  const PostDetails({
    required this.coverTitle,
    required this.caption,
    required this.hashtags,
    this.pinComment = '',
    this.replyQuestion = '',
    this.bestTime = '',
    this.coverHook = '',
    this.moralLine = '',
    this.ctaLine = '',
    this.endQuestion = '',
  });

  /// Caption and hashtags as one block, which is how they get pasted into Instagram.
  String get forInstagram =>
      hashtags.isEmpty ? caption : '$caption\n\n${hashtags.join(' ')}';
}

/// Said next to any suggested posting time.
///
/// Nobody outside Instagram knows how the ranking works, and the best time depends on
/// when YOUR followers are awake, not on a general rule. Presenting a guess as fact
/// would be worse than useless — it would stop anyone checking the real answer, which
/// is sitting in their own Insights.
const kBestTimeCaveat =
    'A starting point only. Instagram › Insights › Total followers › Most active times '
    'shows when your own followers are online — that beats any general advice.';

// ── How a reel script is shaped ───────────────────────────────────────────────

/// The rules for the script itself, in one place.
///
/// Used by the script call and by the combined call. Two copies of this would drift
/// within a week, and the half that drifted would be the half producing weak hooks
/// with nobody able to say why.
const kScriptShapeRules = '''
LINE 1 IS THE HOOK AND IT DECIDES EVERYTHING.
It is heard in the first three seconds. If it does not stop a parent's thumb, nothing
after it is ever seen, so treat it as the hardest line in the script.
- Start in the MIDDLE of the trouble. When the reel begins, the thing has already
  happened. Do not set the scene. Do not introduce anyone.
- It must open a question in the watcher's head that only watching answers.
- Say what happened, never what it means, and NEVER answer it in the same line.
- Good shapes: "Ria ne jo kiya, Mumma dekh ke jam gayi!" or "Cuty subah se gayab hai."
  or "Rio ne woh cheez chhupa di... aur ab sab dhoondh rahe hain."
- Banned openings: "Ek baar ki baat hai", "Aaj hum sikhenge", "Ria aur Rio do dost
  the", anything that begins at the beginning, any greeting, any introduction.

MIDDLE LINES: show the problem and make it worse. Show it happening, do not explain it.
Somewhere in here the turn: what the child works out, or is shown. No adult lecturing.

THE LAST LINE IS THE MORAL.
One short warm Hinglish line saying what the child watching should take away. It is a
lesson, not a summary — "Sharing se dosti badhti hai", not "Aur phir woh khush ho gaye".
If the story has a "Moral:" line, the last line says that moral in your own words.
If the story has a "Hook:" line, line 1 is built from it.

Never introduce a problem, character, event or moral that is not in the story you were
given. Improve how it is told; never replace what it is about.''';

/// The shape every reel on this channel follows, screen by screen.
///
/// Written down and repeated so the channel looks like one thing. A viewer who has
/// seen three of these should know what is coming next, and the last screen should
/// always be the same kind of invitation — that repetition is what turns someone who
/// watched one reel into someone who follows.
const kReelShapeRules = '''
The reel is a fixed run of screens. Every one of them is a picture:

SCREEN 1 — THE COVER. The most eye-catching picture of the whole set, because this is
the thumbnail and for most people it is the only thing they ever see. Two to four words
of Hinglish across it, taken from what actually happens — "Tractor Gayab?!",
"Bath Se Darr?", "Zidd vs Mumma". Never bait: not "Wait for the end", not "You won't
believe". A hook that is not true of the story wins one view and loses a follower.
If the story has a "Cover hook:" line, use those exact words as the cover — it was
chosen on purpose.

The reels are told by a storyteller about Ria, Rio and Cuty. Never write as "I" or
"my child", as if a parent were speaking about their own family.

Hashtags: always #FunLearningWithPalak and #LittleStoriesBigLessons, plus three that
name THIS story's problem — not the same generic tags on every post.

SCREENS 2 to N-2 — THE STORY. The problem, worse, then the turn. Pictures that carry
the moment on their own, because a great many people watch with the sound off.

SCREEN N-1 — THE LESSON. What the child in the story learned, in one warm line a
parent would actually say out loud.

SCREEN N — THE INVITATION. A reason to keep the reel — saving it for bedtime, showing
it to a child later — and one question a parent can answer in four words. Warm, never
demanding. No "LIKE COMMENT SHARE NOW".''';

// ── The two templates ─────────────────────────────────────────────────────────

/// Prompt for a video generator, with the beats filled in and the timings worked out.
///
/// Timings are scaled to the real length rather than hard-coded, so a 45 second reel
/// doesn't get a prompt describing a 28 second one.
String buildVideoPrompt(StoryBeats beats, int seconds, List<CharacterRef> cast) {
  String at(double fraction) {
    final s = (seconds * fraction).round();
    return '0:${s.toString().padLeft(2, '0')}';
  }

  return '''
Create a $seconds second animated story video in 3D Pixar-style cartoon animation, vertical 9:16 format.

TITLE: ${beats.title}

CHARACTERS (must stay visually consistent every time):
${buildCharacterBlock(cast)}

IN THIS STORY: ${beats.who}

STYLE: $_style Setting: ${beats.where}.

STORY STRUCTURE (follow exactly):
${at(0)}-${at(0.11)} — HOOK: bold text overlay: "${beats.hook}"
${at(0.11)}-${at(0.29)} — Set up the situation: ${beats.whatStartsIt}
${at(0.29)}-${at(0.57)} — The problem gets worse: ${beats.whatGoesWrong} ${beats.howItGetsWorse} Show the emotional reaction clearly on the character's face.
${at(0.57)}-${at(0.86)} — The resolution: ${beats.howItIsSolved} Warm, positive tone.
${at(0.86)}-${at(0.93)} — Moral as a text overlay: "${beats.endingLine}"
${at(0.93)}-${at(1.0)} — END CARD, on every reel: "$kBrandName" above "$kBrandTagline"

AUDIO: Warm, upbeat background music that follows the mood — playful, then concerned, then resolved, then happy. Hinglish narration matching the beats above.

TEXT OVERLAYS: Bold rounded font, white speech-bubble shape with a black border, one line at a time, synced to the narration.
''';
}

// ── Prompts for a chat, not a prompt box ──────────────────────────────────────
//
// Meta AI in WhatsApp is a conversation, and that changes what a good prompt is.
// Pasting every character's description before every picture is unreadable in a chat
// window and pointless besides: the thread already remembers what you told it. So the
// cast goes in once, and each picture after that is a short message pointing back.
//
// Every picture message still repeats the format and "same characters as above",
// because a chat model drifts over a long thread. The aspect ratio is the first thing
// it forgets, and a square picture is no use in a reel.

/// Sent once, before any picture, to fix the cast and the style for the whole thread.
String buildCastSetupMessage(List<CharacterRef> cast) => '''
I am going to ask you for several pictures in this chat, one at a time. They are all for
the same children's story, so the characters and the style must stay exactly the same in
every picture.

CHARACTERS:
${buildCharacterBlock(cast)}

STYLE for every picture: $_style Warm bright colour palette, joyful mood.

FORMAT for every picture: vertical 9:16 portrait.

Do not draw anything yet. Reply OK and wait for the first picture.''';

/// One picture as a short chat message, leaning on the setup message above it.
String buildSceneMessage(ScenePrompt scene, int number, int total,
    {bool withOverlay = false}) {
  final parts = <String>['Picture $number of $total. Vertical 9:16 portrait.'];

  if (scene.beat.trim().isNotEmpty) {
    parts.add('This is the ${scene.beat.trim().toLowerCase()} of the story.');
  }
  parts.add(scene.scene.trim());

  if (scene.expression.trim().isNotEmpty) {
    parts.add('Expression: ${scene.expression.trim()}');
  }
  if (scene.shot.trim().isNotEmpty) parts.add('Shot: ${scene.shot.trim()}');
  if (scene.keyObjects.trim().isNotEmpty) {
    parts.add('Must be visible: ${scene.keyObjects.trim()}');
  }
  if (withOverlay && scene.overlayText.trim().isNotEmpty) {
    parts.add('Text across the top in a white speech bubble: '
        '"${scene.overlayText.trim()}"');
  }

  // Last line, not first: it is the instruction most likely to be dropped, and the
  // end of a message is what a chat model weighs most.
  parts.add('Same characters, same style as above.');
  return parts.join('\n');
}

/// Prompt for a single still, for the slideshow or as a reference frame.
String buildImagePrompt(ScenePrompt scene, List<CharacterRef> cast, {bool withOverlay = false}) {
  final overlay = withOverlay && scene.overlayText.trim().isNotEmpty
      ? '\n\nTEXT OVERLAY: "${scene.overlayText.trim()}" — bold rounded sans-serif '
        'inside a white speech-bubble banner with a black border, at the top of the image.'
      : '';

  final beatPart = scene.beat.isEmpty ? '' : 'MOMENT IN THE STORY: ${scene.beat}\n\n';
  final shotPart = scene.shot.isEmpty ? '' : '\n\nSHOT: ${scene.shot}';
  final objectsPart =
      scene.keyObjects.isEmpty ? '' : '\n\nMUST BE VISIBLE: ${scene.keyObjects}';

  return '''
Generate a single high-quality illustration in 3D Pixar/Disney-style cartoon animation, vertical 9:16 format.

CHARACTERS (maintain exact visual consistency):
${buildCharacterBlock(cast)}

${beatPart}SCENE: ${scene.scene}

EXPRESSION: ${scene.expression}$shotPart$objectsPart

STYLE: $_style Warm bright colour palette, joyful mood.$overlay
''';
}
