// ── One image prompt per slide ────────────────────────────────────────────────
//
// A carousel is not one picture. It is one picture per slide, and a single prompt
// for the whole post left six of seven slides with nothing to generate from — so
// each slide was made up on the spot, and a seven-slide post came out looking like
// seven unrelated posts.
//
// This file turns an idea into the full list: the slide text, and one complete,
// copy-paste image prompt per slide, all written against the same character and
// style contract so the set reads as one post.
//
// Deliberately plain, synchronous Dart. The pack is built the moment the button is
// tapped, so the prompts exist even when Gemini is overloaded or the phone is
// offline — the same reason the caption and comment pack are built here too.

/// How many slides a carousel gets when nothing else is chosen.
const kDefaultCarouselSlides = 7;
const kMinCarouselSlides = 3;
const kMaxCarouselSlides = 10;

/// Slide counts offered in the picker.
const kCarouselSlideOptions = <int>[5, 6, 7, 8, 10];

/// Every slide of a carousel is made in the same shape, so the post swipes as one set.
const kCarouselAspect = 'square 1:1';

/// The character and style contract, repeated word for word inside every prompt.
///
/// Repeated rather than referenced, because that repetition is the only thing that
/// keeps the same child's face, dress and colours on all seven slides. Paraphrasing
/// it per slide is what makes a carousel look like seven different families.
///
/// Wording follows the cast in characters.dart, which stays the source of truth for
/// reels; [buildSlidePrompts] takes an override so a caller with the live cast saved
/// can pass its exact descriptions instead.
const kCharacterContract =
    'Ria is a toddler girl with light brown hair in two short pigtails tied with pink '
    'bows, large round dark brown eyes with long lashes, and a pink tiered dress with '
    'small gold stars. Rio is a toddler boy with tousled medium brown hair, large round '
    'amber-brown eyes, a plain blue-grey t-shirt and matching shorts. Cuty is a small '
    'fluffy white bunny with long upright ears and a coral-pink bow at the neck. Keep '
    'every face, hairstyle, outfit, colour and body proportion identical on every slide. '
    'Ria and Rio never wear glasses.';

/// The role each slide plays, in order. Slide 1 is the cover, the last slide is the
/// call to action, and the middle gets whatever is left so no two prompts look alike.
const kSlideRoles = <String>[
  'Cover',
  'Problem',
  'Step',
  'Example',
  'Detail',
  'Turn',
  'Payoff',
  'Recap',
  'Bonus',
  'Call to action',
];

const _fillerBeats = <String>[
  'Show the everyday moment every parent recognises',
  'The small trick that makes it easier',
  'What children actually do here',
  'Try this with your child today',
  'The little win worth celebrating',
];

// ── Reading a script back into slides ─────────────────────────────────────────

/// "Slide 2: ...", "Scene 2 - ...", "Card 2. ...".
final _beatPrefix = RegExp(
  r'^\s*(?:slide|scene|frame|card)\s*(\d+)\s*[:.\-)]\s*(.+)$',
  caseSensitive: false,
);

/// A reel timeline line, "0:04 text | Devanagari".
final _timePrefix = RegExp(r'^\s*\d{1,2}:\s?\d{2}\s*(.+)$');

final _leadingMarker = RegExp(r'^(\d+[.)]\s*|[-•*]\s*)');

/// The slide or scene text of a script, one entry per beat, prefixes removed.
///
/// Returns an empty list when the script is not written beat by beat — a hand
/// written paragraph has no slides in it, and inventing some would be worse than
/// saying there are none.
List<String> scriptBeats(String script) {
  final beats = <String>[];
  for (final raw in script.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    final beat = _beatPrefix.firstMatch(line);
    if (beat != null) {
      _add(beats, beat.group(2)!);
      continue;
    }

    final timed = _timePrefix.firstMatch(line);
    if (timed != null) {
      // The spoken Devanagari half of a reel line is not the picture.
      _add(beats, timed.group(1)!.split('|').first);
    }
  }
  return beats;
}

void _add(List<String> beats, String text) {
  final clean = _cleanBeat(text);
  if (clean.isNotEmpty) beats.add(clean);
}

/// Drops a leftover bullet or number and a wrapping pair of quotes.
String _cleanBeat(String text) {
  var value = text.trim().replaceFirst(_leadingMarker, '').trim();
  final quoted = value.length > 1 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")));
  if (quoted) value = value.substring(1, value.length - 1).trim();
  return value;
}

/// Turns a block of free text into short, list-ready lines.
///
/// The brief fields are written for a human, so they arrive as "1. Identify basic
/// colours" or one run-on sentence. Both are split here rather than pasted into a
/// prompt as a paragraph, because a slide holds one idea.
List<String> splitPoints(String text) {
  final points = <String>[];
  for (final raw in text.split('\n')) {
    for (final piece in raw.split(RegExp(r'\s*(?:\u2022|·)\s*'))) {
      final clean = _cleanBeat(piece);
      if (clean.isNotEmpty) points.add(clean);
    }
  }
  return points;
}

// ── Writing the slides ────────────────────────────────────────────────────────

/// A carousel's slide text and its image prompts, built together so the two can
/// never disagree about how many slides the post has.
class CarouselPlan {
  final List<String> slides;
  final List<String> prompts;

  /// What one beat is called on screen: "Slide" for a carousel, "Frame" for a
  /// story. Held here so the script and the prompts cannot disagree about it.
  final String beatLabel;

  const CarouselPlan({
    required this.slides,
    required this.prompts,
    this.beatLabel = 'Slide',
  });

  int get slideCount => slides.length;

  /// The script as the rest of the app shows it, "Slide 1: ..." per line.
  String get script => [
        for (var i = 0; i < slides.length; i++) '$beatLabel ${i + 1}: ${slides[i]}'
      ].join('\n');
}

/// Builds a full carousel: the slide text first, then a prompt for each slide.
///
/// [slideCount] is what the creator asked for, so a 7 is always 7 slides — the
/// brief supplies the middle, and the filler only appears when the brief ran out
/// before the slides did.
CarouselPlan planCarousel({
  required String title,
  required String hook,
  required String mainIdea,
  required String problem,
  required String lesson,
  required String cta,
  required int slideCount,
  required String visualStyle,
  required String audience,
  required String contentGoal,
  required String mood,
  String beatLabel = 'Slide',
  String characterContract = kCharacterContract,
}) {
  final total = slideCount.clamp(kMinCarouselSlides, kMaxCarouselSlides);
  final opening = hook.trim().isEmpty ? title.trim() : hook.trim();
  final closing = cta.trim().isEmpty ? 'Save this for later' : cta.trim();

  final middle = <String>[
    ...splitPoints(problem),
    ...splitPoints(lesson),
    ...splitPoints(mainIdea),
  ];

  final slides = <String>[opening.isEmpty ? 'A little moment from our day' : opening];
  for (var i = 0; i < total - 2; i++) {
    slides.add(middle.length > i
        ? middle[i]
        : _fillerBeats[(i - middle.length) % _fillerBeats.length]);
  }
  slides.add(closing);

  return CarouselPlan(
    beatLabel: beatLabel,
    slides: slides,
    prompts: buildSlidePrompts(
      title: title,
      slides: slides,
      visualStyle: visualStyle,
      audience: audience,
      contentGoal: contentGoal,
      mood: mood,
      beatLabel: beatLabel,
      characterContract: characterContract,
    ),
  );
}

/// One complete image prompt per slide, ready to paste into an image generator.
///
/// Each prompt can stand alone: it repeats the style, the character contract and
/// the fact that it is one of a set, because a prompt is pasted into a tool that
/// has never seen the other six.
List<String> buildSlidePrompts({
  required String title,
  required List<String> slides,
  String beatLabel = 'Slide',
  required String visualStyle,
  required String audience,
  required String contentGoal,
  required String mood,
  String characterContract = kCharacterContract,
}) {
  if (slides.isEmpty) return const [];

  final style = visualStyle.trim().isEmpty
      ? 'bright, warm, playful preschool lifestyle'
      : visualStyle.trim();
  final who = audience.trim().isEmpty ? 'parents of preschool children' : audience.trim();
  final goal = contentGoal.trim().isEmpty ? 'build connection' : contentGoal.trim();
  final feeling = mood.trim().isEmpty ? 'relatable' : mood.trim();
  final topic = title.trim().isEmpty ? 'a little family moment' : title.trim();
  final total = slides.length;

  return [
    for (var i = 0; i < total; i++)
      _slidePrompt(
        number: i + 1,
        total: total,
        role: _roleFor(i, total),
        slide: slides[i],
        style: style,
        beatLabel: beatLabel,
        aspect: kCarouselAspect,
        topic: topic,
        audience: who,
        goal: goal,
        mood: feeling,
        characterContract: characterContract,
      ),
  ];
}

/// A prompt per beat of a script that was already written — reel scenes, or a
/// carousel loaded from the saved library.
List<String> promptsForScript({
  required String script,
  required String title,
  required String visualStyle,
  required String audience,
  required String contentGoal,
  required String mood,
  required String postType,
  String beatLabel = 'Slide',
  String characterContract = kCharacterContract,
}) {
  final beats = scriptBeats(script);
  if (beats.isEmpty) return const [];

  final isVertical = postType.toLowerCase() == 'reel' || postType.toLowerCase() == 'story';
  final style = visualStyle.trim().isEmpty
      ? 'bright, warm, playful preschool lifestyle'
      : visualStyle.trim();
  final who = audience.trim().isEmpty ? 'parents of preschool children' : audience.trim();
  final goal = contentGoal.trim().isEmpty ? 'build connection' : contentGoal.trim();
  final feeling = mood.trim().isEmpty ? 'relatable' : mood.trim();
  final topic = title.trim().isEmpty ? 'a little family moment' : title.trim();

  return [
    for (var i = 0; i < beats.length; i++)
      _slidePrompt(
        number: i + 1,
        total: beats.length,
        role: _roleFor(i, beats.length),
        slide: beats[i],
        style: style,
        beatLabel: beatLabel,
        aspect: isVertical ? 'vertical 9:16' : kCarouselAspect,
        topic: topic,
        audience: who,
        goal: goal,
        mood: feeling,
        characterContract: characterContract,
      ),
  ];
}

/// The first slide is the cover and the last is the ask; the rest take the roles
/// in between, so a seven-slide set never repeats the same framing.
String _roleFor(int index, int total) {
  if (index == total - 1) return kSlideRoles.last;
  return kSlideRoles[index.clamp(0, kSlideRoles.length - 2)];
}

String _slidePrompt({
  required int number,
  required int total,
  required String role,
  required String slide,
  required String beatLabel,
  required String style,
  required String aspect,
  required String topic,
  required String audience,
  required String goal,
  required String mood,
  required String characterContract,
}) {
  final headline = _headline(slide);
  final visual = _visualFor(role, slide);

  return '$beatLabel $number of $total — $role. Instagram image prompt for the post "$topic".\n'
      'The picture: $visual.\n'
      'Headline on the image: "$headline" — short, big and instantly readable.\n'
      'Style: $style — soft pastel watercolour storybook shading, clean cream '
      'background, warm friendly preschool look.\n'
      'Characters: $characterContract\n'
      'Set consistency: this is one of $total images in one post — same palette, '
      'same line weight, the same character faces on every one.\n'
      'Composition: $aspect, one clear subject, generous empty space where the '
      'headline sits, no collage, no borders.\n'
      'Made for: $audience. Mood: $mood. It should help to $goal.\n'
      'Avoid: extra children, glasses, brand logos, watermarks, photo-realistic '
      'faces, long paragraphs of text, and spelling mistakes.';
}

/// What the picture of a slide actually shows, which is what stops seven prompts
/// from asking for seven slightly different versions of the same scene.
String _visualFor(String role, String slide) {
  switch (role) {
    case 'Cover':
      return 'the most eye-catching moment of the whole post — $slide — shown large '
          'and close, bold colours, the slide that stops the scroll';
    case 'Problem':
      return 'the everyday problem this slide names — $slide — as a small relatable '
          'scene a parent recognises instantly';
    case 'Step':
      return 'one single-prop illustration of this step — $slide — laid out clearly, '
          'with nothing else on the card';
    case 'Example':
      return 'a simple side-by-side comparison that shows $slide';
    case 'Detail':
      return 'a close-up of the one object this slide is about — $slide';
    case 'Turn':
      return 'the moment the story changes — $slide — with an expressive, surprised face';
    case 'Payoff':
      return 'the happy, satisfying result of $slide, characters celebrating';
    case 'Recap':
      return 'a tidy recap of $slide as a neat row of small icons';
    case 'Bonus':
      return 'a playful extra-tip scene for $slide';
    default:
      return 'a warm closing scene with the characters together, leaving clean space '
          'for the final ask — $slide';
  }
}

/// The first few words of a slide, for the headline drawn on the image.
String _headline(String slide) {
  const limit = 9;
  final words = slide.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length <= limit) return slide.trim();
  return '${words.take(limit).join(' ')}…';
}
