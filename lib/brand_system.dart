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

  static const String audience = 'Parents of preschoolers (1.5-5 years)';
  static const String tone = 'Warm, playful, parent-relatable, simple';
  static const String visualStyle = 'Soft pastel watercolor storybook, cream background';

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

  static const String defaultVisualStyle = 'Soft pastel watercolor storybook, cream background';
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

  const Character({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.appearance,
    required this.personality,
    required this.role,
  });

  String get fullProfile => '''
$name ($emoji)
Role: $role
Appearance: $appearance
Personality: $personality
Description: $description''';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'appearance': appearance,
        'personality': personality,
        'role': role,
      };
}

class CharacterLibrary {
  static const Character ria = Character(
    id: 'ria',
    name: 'Ria',
    emoji: '🌸',
    description: 'Indian preschool girl, curious and playful',
    appearance: 'Dark brown hair in two ponytails with pink bows, brown eyes, pink dress, no glasses, preschool age (3-4)',
    personality: 'Energetic, playful, asks questions, leads activities, a little bit of harmless chaos',
    role: 'Protagonist / explorer',
  );

  static const Character rio = Character(
    id: 'rio',
    name: 'Rio',
    emoji: '💙',
    description: 'Indian preschool boy, determined and thoughtful',
    appearance: 'Dark brown hair, blue outfit, brown eyes, no glasses, preschool age (3-4)',
    personality: 'Stubborn, determined, says "no" before thinking, follows then leads, deep focus when interested',
    role: 'Co-protagonist / problem solver',
  );

  static const Character cuty = Character(
    id: 'cuty',
    name: 'Cuty',
    emoji: '🐰',
    description: 'Small white bunny, the peace-bringer',
    appearance: 'Small white bunny, pink bow, soft friendly expression, unchanged always',
    personality: 'Calm, sleepy, unbothered, watches everything, the emotional anchor',
    role: 'Mascot / observer',
  );

  static const List<Character> all = [ria, rio, cuty];

  static Character? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static String get characterLockBlock => '''
CHARACTER LOCK — Use these exact descriptions in EVERY prompt. Do not vary.

${ria.fullProfile}

${rio.fullProfile}

${cuty.fullProfile}

RULES:
- Ria and Rio NEVER wear glasses.
- Cuty is ALWAYS a small white bunny with a pink bow.
- Outfits may change per scene but hair/eyes/face stay consistent.
- Visual style: ${BrandDefaults.visualStyle}
''';
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

  static const List<ContentBucket> all = [
    challenge,
    conversation,
    activity,
    humor,
    agePractice,
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
  carousel('Carousel', '📚', 'Swipeable multi-slide post', 7),
  reel('Reel', '🎬', '15-20 sec vertical video', 5),
  trialReel('Trial Reel', '🧪', '60-sec fast-cut for reach', 8),
  singleImage('Single Image', '🖼️', 'One image + full caption pack', 1);

  final String label;
  final String emoji;
  final String description;
  final int defaultSlideCount;

  const ContentFormat(this.label, this.emoji, this.description, this.defaultSlideCount);
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
}

// ============================================================================
// BRAND CONTEXT BLOCK - Injected into EVERY AI prompt
// ============================================================================

String buildBrandContext({
  required ContentBucket bucket,
  required ContentFormat format,
  required List<Character> characters,
  String? customIdea,
}) {
  final charBlock = characters.map((c) => c.fullProfile).join('\n\n');

  return '''
BRAND CONTEXT (auto-injected, do not modify):
Brand: ${BrandDefaults.name} (${BrandDefaults.handle})
Audience: ${BrandDefaults.audience}
Tone: ${BrandDefaults.tone}
Visual Style: ${BrandDefaults.visualStyle}
Default Hashtags: ${BrandDefaults.hashtagPool.take(BrandDefaults.hashtagCount).join(' ')}
CTA Style: ${BrandDefaults.ctaOptions.join(' | ')}

$charBlock

${CharacterLibrary.characterLockBlock}

FORMAT: ${format.label} (${format.description})
Default slides/shots: ${format.defaultSlideCount} (range: ${format.minSlides}-${format.maxSlides})

BUCKET: ${bucket.name} ${bucket.emoji}
${bucket.description}
${bucket.generationPrompt}

SLIDE TEMPLATE for ${bucket.name}:
${bucket.slideTemplates.map((s) => '- $s').join('\n')}

${customIdea != null ? 'USER IDEA: $customIdea' : ''}
''';
}