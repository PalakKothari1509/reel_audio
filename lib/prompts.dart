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
    this.dialogue = '',
  });
}

// ── The brand ─────────────────────────────────────────────────────────────────

/// Closing card, the same on every reel so the channel is recognisable.
const kBrandName = 'Fun Learning With Palak';
const kBrandTagline = 'Little Stories • Big Lessons';

/// Everything needed to actually post the reel.
class PostDetails {
  final String coverTitle;
  final String caption;
  final List<String> hashtags;

  const PostDetails({
    required this.coverTitle,
    required this.caption,
    required this.hashtags,
  });

  /// Caption and hashtags as one block, which is how they get pasted into Instagram.
  String get forInstagram =>
      hashtags.isEmpty ? caption : '$caption\n\n${hashtags.join(' ')}';
}

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

/// Prompt for a single still, for the slideshow or as a reference frame.
String buildImagePrompt(ScenePrompt scene, List<CharacterRef> cast, {bool withOverlay = false}) {
  final overlay = withOverlay && scene.overlayText.trim().isNotEmpty
      ? '\n\nTEXT OVERLAY: "${scene.overlayText.trim()}" — bold rounded sans-serif '
        'inside a white speech-bubble banner with a black border, at the top of the image.'
      : '';

  final shotPart = scene.shot.isEmpty ? '' : '\n\nSHOT: ${scene.shot}';
  final objectsPart =
      scene.keyObjects.isEmpty ? '' : '\n\nMUST BE VISIBLE: ${scene.keyObjects}';

  return '''
Generate a single high-quality illustration in 3D Pixar/Disney-style cartoon animation, vertical 9:16 format.

CHARACTERS (maintain exact visual consistency):
${buildCharacterBlock(cast)}

SCENE: ${scene.scene}

EXPRESSION: ${scene.expression}$shotPart$objectsPart

STYLE: $_style Warm bright colour palette, joyful mood.$overlay
''';
}
