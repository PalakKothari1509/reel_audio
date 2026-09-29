// Complete Content Package Generator
//
// Generates the FULL post package: hook, slides, visual prompts, caption, CTA,
// hashtags, pinned comment, reply comments — all in one structured object.

import 'dart:math';

import 'brand_system.dart';

class ContentPackage {
  final String id;
  final String idea;
  final ContentBucket bucket;
  final ContentFormat format;
  final List<Character> characters;

  final String hook;
  final List<SlideContent> slides;
  final List<String> visualPrompts;
  final String caption;
  final String cta;
  final List<String> hashtags;
  final String pinnedComment;
  final List<String> replyComments;

  final DateTime createdAt;

  const ContentPackage({
    required this.id,
    required this.idea,
    required this.bucket,
    required this.format,
    required this.characters,
    required this.hook,
    required this.slides,
    required this.visualPrompts,
    required this.caption,
    required this.cta,
    required this.hashtags,
    required this.pinnedComment,
    required this.replyComments,
    required this.createdAt,
  });

  int get slideCount => slides.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'idea': idea,
        'bucket': bucket.id,
        'format': format.name,
        'characters': characters.map((c) => c.id).toList(),
        'hook': hook,
        'slides': slides.map((s) => s.toJson()).toList(),
        'visualPrompts': visualPrompts,
        'caption': caption,
        'cta': cta,
        'hashtags': hashtags,
        'pinnedComment': pinnedComment,
        'replyComments': replyComments,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ContentPackage.fromJson(Map<String, dynamic> json) {
    final bucket = BucketLibrary.byId(json['bucket'] as String) ?? BucketLibrary.challenge;
    final format = ContentFormat.values.byName(json['format'] as String);
    final chars = (json['characters'] as List).map((id) => CharacterLibrary.byId(id)!).toList();
    return ContentPackage(
      id: json['id'] as String,
      idea: json['idea'] as String,
      bucket: bucket,
      format: format,
      characters: chars,
      hook: json['hook'] as String,
      slides: (json['slides'] as List).map((s) => SlideContent.fromJson(s)).toList(),
      visualPrompts: (json['visualPrompts'] as List).cast<String>(),
      caption: json['caption'] as String,
      cta: json['cta'] as String,
      hashtags: (json['hashtags'] as List).cast<String>(),
      pinnedComment: json['pinnedComment'] as String,
      replyComments: (json['replyComments'] as List).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SlideContent {
  final int index;
  final String title;
  final String body;
  final String visualPrompt;
  final String? overlayText;

  const SlideContent({
    required this.index,
    required this.title,
    required this.body,
    required this.visualPrompt,
    this.overlayText,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'body': body,
        'visualPrompt': visualPrompt,
        'overlayText': overlayText,
      };

  factory SlideContent.fromJson(Map<String, dynamic> json) => SlideContent(
        index: json['index'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        visualPrompt: json['visualPrompt'] as String,
        overlayText: json['overlayText'] as String?,
      );
}

// Reply comment styles for variety
enum ReplyStyle {
  relatableParent('Relatable Parent', 'Mom/dad voice, "this is my life"'),
  relatableNonParent('Relatable Non-Parent', 'General relatable, "even without kids"'),
  emojiReaction('Emoji Reaction', 'Pure emoji/short reaction'),
  validation('Validation/Truth', '"This is so true"'),
  ctaConversation('CTA/Conversation', 'Question to drive replies');

  final String label;
  final String description;

  const ReplyStyle(this.label, this.description);
}

// ============================================================================
// CONTENT GENERATOR - Main entry point
// ============================================================================

class ContentGenerator {
  /// Generate a complete content package from an idea + bucket + format
  static Future<ContentPackage> generate({
    required String idea,
    required ContentBucket bucket,
    required ContentFormat format,
    List<Character>? characters,
    int? slideCount,
  }) async {
    characters ??= [CharacterLibrary.ria, CharacterLibrary.rio, CharacterLibrary.cuty];
    final count = slideCount ?? format.defaultSlideCount.clamp(format.minSlides, format.maxSlides);

    // In production, call Gemini here. For now, use local template generation.
    return generateFromTemplate(idea, bucket, format, characters, count);
  }

  /// Local template-based generation (no API call needed)
  static ContentPackage generateFromTemplate(
    String idea,
    ContentBucket bucket,
    ContentFormat format,
    List<Character> characters,
    int slideCount,
  ) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Generate hook based on bucket
    final hook = _generateHook(idea, bucket);

    // Generate slides based on bucket template
    final slides = _generateSlides(idea, bucket, format, slideCount);

    // Generate visual prompts for each slide
    final visualPrompts = _generateVisualPrompts(slides, bucket, format, characters);

    // Generate caption
    final caption = _generateCaption(hook, idea, bucket, format);

    // Generate CTA
    final cta = _generateCTA(bucket, format);

    // Generate hashtags (5 total)
    final hashtags = generateHashtags(bucket);

    // Generate pinned comment
    final pinnedComment = _generatePinnedComment(bucket);

    // Generate 5 varied reply comments
    final replyComments = generateReplyComments(bucket);

    return ContentPackage(
      id: id,
      idea: idea,
      bucket: bucket,
      format: format,
      characters: characters,
      hook: hook,
      slides: slides,
      visualPrompts: visualPrompts,
      caption: caption,
      cta: cta,
      hashtags: hashtags,
      pinnedComment: pinnedComment,
      replyComments: replyComments,
      createdAt: DateTime.now(),
    );
  }

  static String _generateHook(String idea, ContentBucket bucket) {
    final hooks = bucket.exampleHooks;
    // Pick a hook that relates to the idea, or use first as fallback
    return hooks.first;
  }

  static List<SlideContent> _generateSlides(
    String idea,
    ContentBucket bucket,
    ContentFormat format,
    int slideCount,
  ) {
    final templates = bucket.slideTemplates;
    final slides = <SlideContent>[];

    for (int i = 0; i < slideCount && i < templates.length; i++) {
      final template = templates[i];
      final (title, body) = _expandTemplate(template, idea, bucket, i);
      slides.add(SlideContent(
        index: i,
        title: title,
        body: body,
        visualPrompt: '', // Filled in next step
        overlayText: _getOverlayText(template, i),
      ));
    }
    return slides;
  }

  static (String, String) _expandTemplate(String template, String idea, ContentBucket bucket, int index) {
    // Simple template expansion - in production this would use AI
    final lower = template.toLowerCase();

    if (lower.contains('cover')) {
      return ('${bucket.exampleHooks.first}', idea);
    }
    if (lower.contains('challenge') || lower.contains('what you need')) {
      return ('What You Need', _formatItems(bucket.activityItems(idea)));
    }
    if (lower.contains('step 1') || lower.contains('step 2') || lower.contains('step 3') || lower.contains('slide')) {
      return ('Step ${index}', _formatStep(idea, bucket, index));
    }
    if (lower.contains('think') || lower.contains('why') || lower.contains('what they learn')) {
      return ('Why It Works', _generateLesson(idea, bucket));
    }
    if (lower.contains('reveal') || lower.contains('answer')) {
      return ('The Answer', _generateReveal(idea, bucket));
    }
    if (lower.contains('variation') || lower.contains('or try')) {
      return ('Variation', _generateVariation(idea, bucket));
    }
    if (lower.contains('cta') || lower.contains('save') || lower.contains('comment')) {
      return ('Take Action', _generateSlideCTA(bucket));
    }
    if (lower.contains('question')) {
      return ('Question ${index}', _generateQuestion(idea, bucket, index));
    }
    if (lower.contains('skill')) {
      return ('Skill ${index}', _generateSkill(idea, bucket, index));
    }
    if (lower.contains('scene')) {
      return ('Scene ${index}', _generateHumorScene(idea, bucket, index));
    }
    if (lower.contains('punchline')) {
      return ('The Punchline', _generatePunchline(idea, bucket));
    }
    if (lower.contains('tagline')) {
      return ('Relatable Moment', _generateTagline(bucket));
    }

    return (template, idea);
  }

  static String _formatItems(String items) => items.split(',').map((e) => '• ${e.trim()}').join('\n');

  static String _formatStep(String idea, ContentBucket bucket, int index) {
    return 'Step $index of the ${bucket.shortLabel.toLowerCase()} activity: ${_activityStep(idea, index)}';
  }

  static String _activityStep(String idea, int step) {
    final steps = [
      'Gather your items and set up the space',
      'Show your child how to start',
      'Let them try independently',
      'Celebrate every attempt!',
    ];
    return steps[(step - 1) % steps.length];
  }

  static String _generateLesson(String idea, ContentBucket bucket) {
    return 'This ${bucket.shortLabel.toLowerCase()} builds ${bucket.description.toLowerCase().split(',').first} skills in a fun, low-pressure way.';
  }

  static String _generateReveal(String idea, ContentBucket bucket) {
    return 'The answer is revealed with a simple explanation your child can understand.';
  }

  static String _generateVariation(String idea, ContentBucket bucket) {
    return 'Try it with different items next time — same skill, new fun!';
  }

  static String _generateSlideCTA(ContentBucket bucket) {
    final ctas = [
      'Save this for your next play moment!',
      'Try this today and tell us how it went!',
      'Bookmark for your next activity time!',
      'Comment which one your child liked best!',
    ];
    return ctas[DateTime.now().millisecond % ctas.length];
  }

  static String _generateQuestion(String idea, ContentBucket bucket, int index) {
    final questions = [
      'What made you happy today?',
      'What would you build with 100 blocks?',
      'Which animal would you want as a friend?',
      'If your teddy could talk, what would it say?',
      'What was the silliest thing today?',
    ];
    return questions[index % questions.length];
  }

  static String _generateSkill(String idea, ContentBucket bucket, int index) {
    final skills3 = ['Identify basic colours', 'Name 5 fruits', 'Recognise their name', 'Count 1-10', 'Identify body parts'];
    final skills4 = ['Count 1-20', 'Recognise A-Z', 'Name days of week', 'Sort by category', 'Follow 2-3 step instructions'];
    final skills = bucket.id == 'age_practice' && idea.contains('4') ? skills4 : skills3;
    return skills[index % skills.length];
  }

  static String _generateHumorScene(String idea, ContentBucket bucket, int index) {
    final scenes = [
      'Rio sprawled on couch, ignoring "put your shoes on"',
      '5 min later — still no shoes, still distracted',
      'Mom asks "where\'s your water bottle?" — it\'s right beside him',
      '"Don\'t run!" — both sprint past, Cuty asleep',
      '"Come here." — silence — "COME HERE!" 😂',
    ];
    return scenes[index % scenes.length];
  }

  static String _generatePunchline(String idea, ContentBucket bucket) {
    return 'Every parent knows this exact sequence 😂';
  }

  static String _generateTagline(ContentBucket bucket) {
    return 'Tag a parent who lives this daily!';
  }

  static List<String> _generateVisualPrompts(
    List<SlideContent> slides,
    ContentBucket bucket,
    ContentFormat format,
    List<Character> characters,
  ) {
    return slides.map((slide) {
      final charNames = characters.map((c) => c.name).join(', ');
      final aspect = format == ContentFormat.reel || format == ContentFormat.trialReel ? 'vertical 9:16' : 'square 1:1';

      return '''
${slide.title} — ${slide.body}
${BrandDefaults.visualStyle}, ${aspect}.
Characters: ${charNames}.
Scene: ${slide.body}.
Character Lock: ${CharacterLibrary.characterLockBlock}
Bucket context: ${bucket.generationPrompt}
'''.trim();
    }).toList();
  }

  static String _generateCaption(String hook, String idea, ContentBucket bucket, ContentFormat format) {
    final cta = BrandDefaults.ctaOptions[DateTime.now().second % BrandDefaults.ctaOptions.length];
    return '$hook $idea\n\n$cta\n\n${_pickHashtags(bucket).join(' ')}';
  }

  static String _generateCTA(ContentBucket bucket, ContentFormat format) {
    final ctas = {
      'challenge': 'Comment your child\'s answer below 👇',
      'conversation': 'What did they say? Comment below 👇',
      'activity': 'Save this for your next play moment! 📌',
      'humor': 'Tag a parent who needs this 😂',
      'age_practice': 'Bookmark for your next milestone check 📌',
    };
    return ctas[bucket.id] ?? 'Save this for later!';
  }

  static List<String> generateHashtags(ContentBucket bucket) {
    final bucketTags = {
      'challenge': ['#observationskills', '#preschoolgames', '#kidsbrainbooster'],
      'conversation': ['#talkwithyourkids', '#parentingtips', '#bedtimeroutine'],
      'activity': ['#toddleractivities', '#playbasedlearning', '#momhacks'],
      'humor': ['#parentingmemes', '#toddlerlife', '#relatablemom'],
      'age_practice': ['#preschoolmilestones', '#toddlerdevelopment', '#earlylearning'],
    };
    final base = BrandDefaults.hashtagPool;
    final extra = bucketTags[bucket.id] ?? [];
    final combined = [...base, ...extra];
    combined.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    return combined.take(BrandDefaults.hashtagCount).toList();
  }

  static List<String> _pickHashtags(ContentBucket bucket) => generateHashtags(bucket);

  static String _generatePinnedComment(ContentBucket bucket) {
    final comments = {
      'challenge': 'Try this with your little one — did they get it right away? 👀',
      'conversation': 'We\'d love to hear what your little one said — share it below! ❤️',
      'activity': 'Tried this yet? Tell us how your little one did!',
      'humor': 'Be honest — how many times today? 😂',
      'age_practice': 'How many can your child already do? Tell us below! 💛',
    };
    return comments[bucket.id] ?? 'What did you think? Comment below!';
  }

  static List<String> generateReplyComments(ContentBucket bucket) {
    // 5 distinct styles per bucket
    final styles = {
      'challenge': [
        'My daughter got it instantly, so proud! 😍',
        'Even non-parents find this satisfying to watch!',
        '😂😂 my son picked the wrong one but his reasoning was adorable',
        'This is such a simple but smart activity, saving it!',
        'More of these please, my toddler loves puzzles!',
      ],
      'conversation': [
        'My son said his teddy would say "let\'s go on an adventure!" 😍',
        'This made for such a sweet bedtime chat tonight.',
        'She said her teddy would just say "I love you" — I nearly cried 🥹',
        'Trying this tonight, such a lovely idea.',
        'Love having actual questions instead of just "how was your day."',
      ],
      'activity': [
        'Love that this uses stuff I already have at home!',
        'My 3-year-old turned it into a xylophone instead 😂 still counts!',
        'Doing this tonight while I cook, thank you!',
        'So simple but so smart.',
        'This is going straight into my saved activities folder.',
      ],
      'humor': [
        'Literally on repeat in my house every single morning 😭',
        'This is SO accurate it hurts 😂',
        'I said "come here" 4 times before dinner today alone.',
        'Even non-moms understand this energy 😂',
        'Tagging my husband, he needs to see this 😅',
      ],
      'age_practice': [
        'My daughter can do 4 out of 5, so proud!',
        'This is a great reminder, not a pressure checklist. Thank you!',
        'Saving this to track over the next few months.',
        'She\'s still working on counting to 10 but getting there!',
        'Love that this isn\'t presented as a race — so refreshing.',
      ],
    };
    return styles[bucket.id] ?? [
      'This is so helpful, thank you!',
      'Saving this for later!',
      'My child loved this!',
      'More content like this please!',
      'Great idea!',
    ];
  }

  static String _getOverlayText(String template, int index) {
    if (template.toLowerCase().contains('cover')) return 'Hook text';
    if (template.toLowerCase().contains('step')) return 'Step ${index}';
    if (template.toLowerCase().contains('think') || template.toLowerCase().contains('why')) return 'Why it works';
    if (template.toLowerCase().contains('reveal')) return 'Answer';
    if (template.toLowerCase().contains('cta') || template.toLowerCase().contains('save')) return 'CTA';
    return '';
  }
}

// Extension to help with bucket-specific activity items
extension BucketExt on ContentBucket {
  String activityItems(String idea) {
    // Return comma-separated household items for the activity
    switch (id) {
      case 'activity':
        if (idea.toLowerCase().contains('kitchen') || idea.toLowerCase().contains('spoon')) {
          return '5 spoons of different sizes from your kitchen drawer';
        }
        if (idea.toLowerCase().contains('sock') || idea.toLowerCase().contains('laundry')) {
          return 'A laundry basket full of mixed, unmatched socks';
        }
        if (idea.toLowerCase().contains('mission') || idea.toLowerCase().contains('swap')) {
          return 'Broomstick, chairs, dupatta, wooden spoon, steel plates, paper, chalk, sunglasses, laundry basket, tiffin box';
        }
        return 'Common household items (spoons, socks, boxes, paper, chalk)';
      default:
        return 'Simple household items';
    }
  }
}