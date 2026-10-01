// Brand System - Core identity, characters, buckets, and defaults
//
// This file defines the immutable brand identity that ALL generated content
// automatically inherits. No more manual entry of character descriptions,
// hashtags, CTAs, or visual style.

import 'package:flutter/material.dart';

// ============================================================================
// BRAND DEFAULTS
// ============================================================================

class BrandDefaults {
  static const String name = 'Fun Learning With Palak';
  static const String handle = '@funlearningwithpalak';

  static const String audience = 'Indian moms and parents of children aged 1-4';
  static const String tone = 'Warm, playful, parent-relatable, simple';

  /// The single definition of how this brand looks. Every image and video prompt in
  /// the app reads this one constant.
  ///
  /// It was previously "Soft pastel watercolor storybook" here while `prompts.dart`
  /// carried a private "3D Pixar" const, so every generation cycle sent the model two
  /// opposite rendering instructions. All seven character renders in
  /// `assets/characters/` are 3D Pixar, so that is what this says, and "NOT
  /// watercolor" is spelled out because the opposite instruction has already been
  /// sent to these generators in earlier runs.
  static const String visualStyle =
      'Soft 3D Pixar/Disney-style render, warm natural lighting, semi-realistic quality. '
      'NOT flat 2D, NOT watercolor, NOT kawaii-chibi.';

  static const List<String> ctaOptions = [
    'Save this for later 📌',
    'Share with another parent 🤝',
    'Comment your answer below 👇',
    'Follow for daily play ideas 🏠',
    'Try this today and tag us 🏷️',
  ];

  static const List<String> hashtagPool = [
    '#funlearningwithpalak',
    '#noscreenactivities',
    '#playbasedlearning',
    '#montessoriathome',
    '#toddleractivities',
    '#preschoolactivities',
    '#earlylearning',
    '#parentingtips',
    '#momsofinstagram',
    '#indianmoms',
    '#ahmedabadmoms',
  ];

  static const int hashtagCount = 5;
}

// ============================================================================
// CHARACTER PROFILES - Immutable, always injected
// ============================================================================

class Character {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String appearance;
  final String personality;
  final String role;

  /// How this character sounds, in words. Separate from [personality] on purpose:
  /// personality decides what Mumma does, this decides what comes out of her mouth.
  /// A prompt that only knows she is "patient" writes a scolding-adjacent line,
  /// whereas knowing she says "arre mera bachha" gets the tone right.
  final String speechPattern;

  const Character({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.appearance,
    required this.personality,
    required this.role,
    this.speechPattern = '',
  });

  String get fullProfile => '''
$name ($emoji)
Role: $role
Appearance: $appearance
Personality: $personality
Description: $description${speechPattern.isEmpty ? '' : '\nSpeech: $speechPattern'}''';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'appearance': appearance,
        'personality': personality,
        'role': role,
        'speechPattern': speechPattern,
      };
}

class CharacterLibrary {
  static const Character ria = Character(
    id: 'ria',
    name: 'Ria',
    emoji: '🌸',
    description: 'Indian preschool girl, curious and playful',
    appearance: 'Dark brown hair in two ponytails with pink bows, brown eyes, pink dress, no glasses, preschool age (3-4). Toofani: round chubby cheeks and a soft plump build, not thin',
    personality: 'Curious and expressive, energetic and playful, asks questions and leads activities, sometimes stubborn, a little harmless chaos',
    role: 'Protagonist / explorer',
  );

  static const Character rio = Character(
    id: 'rio',
    name: 'Rio',
    emoji: '💙',
    description: 'Indian preschool boy, playful and determined',
    appearance: 'Dark brown hair, blue outfit, brown eyes, no glasses, preschool age (3-4)',
    personality: 'Energetic and playful, naturally stubborn and determined, says "no" before thinking, follows then leads, deep focus when interested',
    role: 'Co-protagonist / problem solver',
  );

  static const Character cuty = Character(
    id: 'cuty',
    name: 'Cuty',
    emoji: '🐰',
    description: 'Small white bunny, the peace-bringer',
    appearance: 'Small white bunny, pink bow, soft friendly expression, unchanged always',
    personality: 'Gentle, quiet observer, calm and sleepy, unbothered, subtle comic relief and warmth, the emotional anchor, never the one who lectures',
    role: 'Mascot / observer',
  );

  /// The fourth character, and the one who carries the whole Jugaadu Mummy direction.
  ///
  /// She was missing from the library while every flagship example ("Phone chahiye →
  /// simple home activity") is a Mumma story, so those prompts were reaching the
  /// model with no description of her at all.
  static const Character mumma = Character(
    id: 'mumma',
    name: 'Mumma',
    emoji: '👩',
    description: 'Young Indian mother in her early 30s, warm and patient',
    appearance: 'Young Indian mother, early 30s, warm brown eyes, gentle radiant smile, '
        'hair neatly styled in a soft high bun with loose face-framing strands, small red bindi '
        'on the forehead. Wearing a mustard yellow kurti with white chikankari embroidery, '
        'classic blue slim-fit jeans, casual brown flat slide sandals. Stylized 3D '
        'Pixar/Disney character design, soft rim lighting, clean white backdrop.',
    personality: 'Warm, patient and observant. Playfully redirects tantrums rather than '
        'scolding, never lectures. A master of low-cost screen-free household hacks. '
        'Her solutions come from noticing what is already in the kitchen, not from buying '
        'anything.',
    role: 'Warm problem-solver, the parent the viewer identifies with',
    speechPattern: 'Calm Hinglish, encouraging, warm. Soft terms of endearment such as '
        '"arre mera bachha" and "dekho toh". Never scolding, never impatient.',
  );

  static const List<Character> all = [ria, rio, cuty, mumma];

  static Character? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Built from [characters], defaulting to the whole library, rather than naming
  /// characters by hand. It used to list Ria, Rio and Cuty by hand, which meant
  /// Mumma could be added to [all] and still never reach a prompt.
  ///
  /// Takes the cast it should describe so that a post featuring only Mumma does not
  /// also carry Ria, Rio and Cuty into the prompt and invite the generator to put
  /// them in the frame.
  static String characterLockFor([List<Character>? characters]) {
    final cast = (characters == null || characters.isEmpty) ? all : characters;
    return '''
CHARACTER LOCK — Use these exact descriptions in EVERY prompt. Do not vary.

${cast.map((c) => c.fullProfile).join('\n\n')}

RULES:
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Only the characters listed above may appear in this post.
- Outfits may change per scene but hair/eyes/face stay consistent.
- Visual style: ${BrandDefaults.visualStyle}
''';
  }

  static String get characterLockBlock => characterLockFor();
}

// ============================================================================
// CONTENT BUCKETS - What the content is ABOUT
// ============================================================================

class ContentBucket {
  final String id;
  final String name;
  final String emoji;
  final String shortLabel;
  final String description;
  final String generationPrompt; // Added to every prompt for this bucket
  final Color color;
  final Color softColor;
  final List<String> exampleHooks;
  final List<String> slideTemplates; // Template for slide/page structure

  const ContentBucket({
    required this.id,
    required this.name,
    required this.emoji,
    required this.shortLabel,
    required this.description,
    required this.generationPrompt,
    required this.color,
    required this.softColor,
    required this.exampleHooks,
    required this.slideTemplates,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'shortLabel': shortLabel,
        'description': description,
        'color': color.value,
        'softColor': softColor.value,
      };
}

class BucketLibrary {
  static const ContentBucket challenge = ContentBucket(
    id: 'challenge',
    name: 'Challenge',
    emoji: '🔎',
    shortLabel: 'Challenge',
    description: 'Observation games, pattern challenges, spot-the-hidden, puzzles',
    generationPrompt: '''
This is a CHALLENGE post. The goal is to make the child (and parent) think, observe, and solve.
Structure: Hook → Challenge Setup → Options/Clues → Thinking Moment → Reveal → Why it works → CTA.
Tone: Curious, satisfying, "aha!" moment.
Visual: Clean, clear, puzzle-like. Show the challenge state clearly.''',
    color: Color(0xFFE8A87C),
    softColor: Color(0xFFFDF0EB),
    exampleHooks: [
      'WHICH ONE DOESN\'T BELONG? 👀',
      'CAN YOU SPOT THE DIFFERENCE? 🔍',
      'WHAT COMES NEXT? 🟡🔵🟡🔵❓',
      'FIND THE HIDDEN CUTY! 🐰',
      'WHICH SHADOW MATCHES? 🐾',
    ],
    slideTemplates: [
      'Cover: Hook + visual teaser',
      'Challenge: Show the puzzle clearly',
      'Options: Present choices',
      'Think: Character thinking pose',
      'Reveal: Answer with explanation',
      'Why: One-line learning takeaway',
      'CTA: Save / Comment answer',
    ],
  );

  static const ContentBucket conversation = ContentBucket(
    id: 'conversation',
    name: 'Conversation',
    emoji: '🗣️',
    shortLabel: 'Talk',
    description: 'Bedtime questions, dinner talks, imagination starters',
    generationPrompt: '''
This is a CONVERSATION post. The goal is to give parents a question that opens up real talk.
Structure: Hook → The Question → Why it works → Example answers → Variations → CTA.
Tone: Warm, curious, no wrong answers.
Visual: Cozy, intimate, evening/bedroom setting.''',
    color: Color(0xFFB8D8E8),
    softColor: Color(0xFFE8F4FA),
    exampleHooks: [
      'ASK YOUR CHILD THIS TONIGHT 🗣️',
      '3 QUESTIONS FOR THIS WEEK ❤️',
      'IF YOUR TEDDY COULD TALK... 🐻',
      'WHAT WOULD YOU BUILD WITH 100 BLOCKS? 🧱',
      'DINNER QUESTION: WHO IS THE KINDEST PERSON YOU KNOW? 🍽️',
    ],
    slideTemplates: [
      'Cover: Hook + cozy scene',
      'Question 1: Main question + illustration',
      'Question 2: Follow-up + illustration',
      'Question 3: Deeper question + illustration',
      'Why: What this builds (imagination/empathy/vocab)',
      'Variation: "Or try this version..."',
      'CTA: Save for tonight / Comment their answer',
    ],
  );

  static const ContentBucket activity = ContentBucket(
    id: 'activity',
    name: 'Activity',
    emoji: '🏠',
    shortLabel: 'Activity',
    description: 'Try This at Home - practical play using household items',
    generationPrompt: '''
This is an ACTIVITY post. The goal is: "I can do this RIGHT NOW with things I already have."
Structure: Hook → What you need (household items) → Step 1 → Step 2 → Step 3 → Learning outcome → CTA.
Tone: Practical, encouraging, zero friction.
Visual: Real home setting, items clearly visible, characters doing the activity.''',
    color: Color(0xFFB8E8C8),
    softColor: Color(0xFFE8FAF0),
    exampleHooks: [
      '5-MINUTE KITCHEN CHALLENGE 🥄',
      'THE SOCK HUNT 🧦',
      'NO SPECIAL TOYS NEEDED 🏠',
      'ONE SPOON, FIVE SKILLS 🥄',
      'LAUNDRY DAY = GAME DAY 🧺',
    ],
    slideTemplates: [
      'Cover: Hook + hero image of activity',
      'What You Need: 3-5 household items illustrated',
      'Step 1: Action shot',
      'Step 2: Action shot',
      'Step 3: Action shot',
      'What They Learn: One-line skill takeaway',
      'CTA: Save for later / Try today',
    ],
  );

  static const ContentBucket humor = ContentBucket(
    id: 'humor',
    name: 'Humor',
    emoji: '😂',
    shortLabel: 'Humor',
    description: 'Parent-relatable moments, toddler logic, daily chaos',
    generationPrompt: '''
This is a HUMOR post. The goal is: "This is MY life" — instant recognition + share.
Structure: Hook → Relatable Scene 1 → Scene 2 → Scene 3 → Punchline → CTA.
Tone: Self-deprecating, warm, exaggerated but true.
Visual: Expressive faces, chaotic-cute energy, meme-style text overlays ok.''',
    color: Color(0xFFF4C2C2),
    softColor: Color(0xFFFDEEEE),
    exampleHooks: [
      'MUMMA SAYS THIS 100× A DAY 😂',
      'TODDLER MATHEMATICS 😂',
      'THREE TYPES OF KIDS AT DINNER 🍽️',
      'TODDLER LOGIC 101 😂',
      'BEDTIME: THE OLYMPIC EVENT 😂',
    ],
    slideTemplates: [
      'Cover: Hook + funny visual',
      'Scene 1: Relatable moment',
      'Scene 2: Escalation',
      'Scene 3: Peak chaos',
      'Punchline: Character reaction',
      'Tagline: "Every parent knows this"',
      'CTA: Tag a parent / Comment your version',
    ],
  );

  static const ContentBucket agePractice = ContentBucket(
    id: 'age_practice',
    name: 'Age Practice',
    emoji: '📚',
    shortLabel: 'Skills',
    description: 'Gentle milestone checklists for specific ages',
    generationPrompt: '''
This is an AGE PRACTICE post. The goal: "Save this to casually check" — zero pressure.
Structure: Hook → Age label → Skill 1 → Skill 2 → Skill 3 → Skill 4 → Skill 5 → Reassurance → CTA.
Tone: Reassuring, informative, "every child at their own pace".
Visual: Clean checklist style, consistent icons per skill, warm not clinical.''',
    color: Color(0xFFD8C8E8),
    softColor: Color(0xFFF3EDFA),
    exampleHooks: [
      'CAN YOUR 3-YEAR-OLD DO THESE? ✅',
      'CAN YOUR 4-YEAR-OLD DO THESE? ✅',
      'SCHOOL READINESS CHECKLIST 🎒',
      '2-YEAR-OLD MILESTONES 📝',
      'PRE-K SKILLS TO PRACTISE 📚',
    ],
    slideTemplates: [
      'Cover: Hook + age badge',
      'Skill 1: Icon + label',
      'Skill 2: Icon + label',
      'Skill 3: Icon + label',
      'Skill 4: Icon + label',
      'Skill 5: Icon + label',
      'CTA: Bookmark / Save for milestone check',
    ],
  );

  // Added when the 14-day posts were folded in. Their 'wrap' bucket held three
  // real posts (favourite format, voted mission, week wrap up) and none of the
  // five buckets above described them: 'conversation' is talking with the child
  // at bedtime, not talking to the page's followers. Folding them into an
  // existing bucket would have quietly changed what those three posts are about.
  static const ContentBucket community = ContentBucket(
    id: 'community',
    name: 'Community',
    emoji: '💬',
    shortLabel: 'Community',
    description: 'Polls, votes, favourites, week wrap ups, feedback',
    generationPrompt: '''
This is a COMMUNITY post. The goal is to make followers answer, vote, or reply.
Structure: Hook → The Question or Vote → Options → Why it matters → CTA.
Tone: Warm, inviting, like a parent asking other parents.
Visual: Characters holding or pointing at choices, friendly and open.''',
    color: Color(0xFFF0E68C),
    softColor: Color(0xFFFFFAEC),
    exampleHooks: [
      'WHICH ONE SHOULD WE DO NEXT? 🗳️',
      'VOTE FOR RIA\'S NEXT MISSION 🐰',
      'TELL US YOUR FAVOURITE FORMAT 💛',
      'THIS WEEK ON THE PAGE: HERE IS EVERYTHING 🌈',
      'WHICH MISSION WON? CAST YOUR VOTE 🏆',
    ],
    slideTemplates: [
      'Cover: Hook + question or vote',
      'Options: Show 2 to 4 choices',
      'Each option: Character with one choice',
      'Why: One line on what you will make next',
      'CTA: Comment or vote',
    ],
  );

  static const List<ContentBucket> all = [
    challenge,
    conversation,
    activity,
    humor,
    agePractice,
    community,
  ];

  static ContentBucket? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  static ContentBucket? byName(String name) {
    for (final b in all) {
      if (b.name.toLowerCase() == name.toLowerCase()) return b;
    }
    return null;
  }
}

// ============================================================================
// FORMATS - How it will be PUBLISHED
// ============================================================================

enum ContentFormat {
  carousel('Carousel', '📚', 'Swipeable multi-slide post', 7,
    canvasWidth: 1080, canvasHeight: 1440,
    topMargin: 180, bottomMargin: 180, leftMargin: 50, rightMargin: 50),
  reel('Reel', '🎬', '15-20 sec vertical video', 5,
    canvasWidth: 1080, canvasHeight: 1920,
    topMargin: 250, bottomMargin: 450, leftMargin: 35, rightMargin: 35),
  trialReel('Trial Reel', '🧪', '60-sec fast-cut for reach', 8,
    canvasWidth: 1080, canvasHeight: 1920,
    topMargin: 250, bottomMargin: 450, leftMargin: 35, rightMargin: 35),
  singleImage('Single Image', '🖼️', 'One image + full caption pack', 1,
    canvasWidth: 1080, canvasHeight: 1080,
    topMargin: 100, bottomMargin: 100, leftMargin: 50, rightMargin: 50);

  final String label;
  final String emoji;
  final String description;
  final int defaultSlideCount;
  final int canvasWidth;
  final int canvasHeight;
  final int topMargin;
  final int bottomMargin;
  final int leftMargin;
  final int rightMargin;

  const ContentFormat(this.label, this.emoji, this.description, this.defaultSlideCount,
    {required this.canvasWidth, required this.canvasHeight,
     required this.topMargin, required this.bottomMargin,
     required this.leftMargin, required this.rightMargin});
}

extension FormatExt on ContentFormat {
  int get minSlides => switch (this) {
    ContentFormat.carousel => 5,
    ContentFormat.reel => 4,
    ContentFormat.trialReel => 7,
    ContentFormat.singleImage => 1,
  };

  int get maxSlides => switch (this) {
    ContentFormat.carousel => 10,
    ContentFormat.reel => 8,
    ContentFormat.trialReel => 10,
    ContentFormat.singleImage => 1,
  };

  String get safeZoneSpec => '''
Safe Zone (content must stay within these margins):
  Canvas: ${canvasWidth}x${canvasHeight}px
  Top Margin: ${topMargin}px
  Bottom Margin: ${bottomMargin}px
  Left Margin: ${leftMargin}px
  Right Margin: ${rightMargin}px
  Safe Area: ${canvasWidth - leftMargin - rightMargin}x${canvasHeight - topMargin - bottomMargin}px
  (All key text, characters, and visual elements MUST remain inside this safe area)''';

  String get visualPromptSpec => '''
Visual Prompt Spec (for AI image/video generation):
  Format: $label ($description)
  Canvas: ${canvasWidth}x${canvasHeight}px (${aspectRatio})
  Safe Zone: Top ${topMargin}px, Bottom ${bottomMargin}px, Left ${leftMargin}px, Right ${rightMargin}px
  Style: ${BrandDefaults.visualStyle}
  Characters: ${CharacterLibrary.all.map((c) => '${c.name} (${c.appearance})').join('; ')}''';

  String get aspectRatio {
    final w = canvasWidth;
    final h = canvasHeight;
    final gcd = _gcd(w, h);
    return '${w ~/ gcd}:${h ~/ gcd}';
  }

  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
}

// ============================================================================
// BRAND CONTEXT BLOCK - Injected into EVERY AI prompt
// ============================================================================

String buildBrandContext({
  required ContentBucket bucket,
  required ContentFormat format,
  List<Character> characters = const [],
  String? customIdea,
}) {
  // One character block, not two. This used to build a block from `characters` and
  // then append the full library lock block regardless, so a Mumma-only post also
  // received Ria, Rio and Cuty and the generator was free to put them in frame.
  final cast = characters.isEmpty ? CharacterLibrary.all : characters;
  final charBlock = CharacterLibrary.characterLockFor(cast);

  return '''
BRAND CONTEXT (auto-injected, do not modify):
Brand: ${BrandDefaults.name} (${BrandDefaults.handle})
Audience: ${BrandDefaults.audience}
Tone: ${BrandDefaults.tone}
Visual Style: ${BrandDefaults.visualStyle}
Default Hashtags: ${BrandDefaults.hashtagPool.take(BrandDefaults.hashtagCount).join(' ')}
CTA Style: ${BrandDefaults.ctaOptions.join(' | ')}

$charBlock

FORMAT: ${format.label} (${format.description})
Default slides/shots: ${format.defaultSlideCount} (range: ${format.minSlides}-${format.maxSlides})
${format.safeZoneSpec}
${format.visualPromptSpec}

BUCKET: ${bucket.name} ${bucket.emoji}
${bucket.description}
${bucket.generationPrompt}

SLIDE TEMPLATE for ${bucket.name}:
${bucket.slideTemplates.map((s) => '- $s').join('\n')}

${customIdea != null ? 'USER IDEA: $customIdea' : ''}
''';
}