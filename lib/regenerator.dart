// Regeneration System
//
// Allows regenerating individual sections with style variations instead of
// re-generating the entire package.

import 'dart:math';

import 'brand_system.dart';
import 'content_generator.dart';

enum RegenerateTarget {
  hook('Hook', 'The opening line that stops the scroll'),
  slides('Slides/Shots', 'All slide content and structure'),
  singleSlide('Single Slide', 'One specific slide'),
  visualPrompts('Visual Prompts', 'AI image/video prompts for each slide'),
  caption('Caption', 'Instagram caption with CTA + hashtags'),
  cta('CTA', 'Call-to-action line'),
  hashtags('Hashtags', '5 optimized hashtags'),
  pinnedComment('Pinned Comment', 'First comment to drive engagement'),
  replyComments('Reply Comments', '5 varied reply comments');

  final String label;
  final String description;

  const RegenerateTarget(this.label, this.description);
}

enum RegenerateStyle {
  original('Original', 'Same style as before'),
  morePlayful('More Playful', 'Lighter, funnier, more energetic'),
  moreCuriosity('More Curiosity', 'Question-driven, mystery, "what if"'),
  simpler('Simpler', 'Shorter words, clearer, less text'),
  funnier('Funnier', 'More humor, exaggeration, relatable chaos'),
  moreParentRelatable('More Parent-Relatable', 'Specific parenting moments, "this is my life"'),
  moreEducational('More Educational', 'Clear skill-building, explicit learning'),
  moreVisual('More Visual', 'Focus on what\'s seen, less text on image');

  final String label;
  final String description;

  const RegenerateStyle(this.label, this.description);
}

class RegenerationRequest {
  final ContentPackage originalPackage;
  final RegenerateTarget target;
  final RegenerateStyle style;
  final int? slideIndex; // For single slide regeneration

  const RegenerationRequest({
    required this.originalPackage,
    required this.target,
    required this.style,
    this.slideIndex,
  });
}

class RegenerationResult {
  final RegenerateTarget target;
  final dynamic newValue; // String, List<String>, List<SlideContent>, etc.
  final String explanation;

  const RegenerationResult({
    required this.target,
    required this.newValue,
    required this.explanation,
  });
}

class Regenerator {
  static const Map<RegenerateStyle, String> _stylePrompts = {
    RegenerateStyle.morePlayful: 'Make it more playful, lighter, funnier, more energetic. Use exclamation points, playful language.',
    RegenerateStyle.moreCuriosity: 'Make it more curiosity-driven. Use questions, mystery, "what if", "can you guess".',
    RegenerateStyle.simpler: 'Make it simpler. Shorter words, clearer sentences, less text on each slide, more white space.',
    RegenerateStyle.funnier: 'Make it funnier. More humor, exaggeration, relatable parenting chaos, self-deprecating.',
    RegenerateStyle.moreParentRelatable: 'Make it more specifically parent-relatable. Reference real daily moments: bedtime, meals, tantrums, laundry.',
    RegenerateStyle.moreEducational: 'Make it more educational. Explicit skill-building, clear learning outcome, developmental milestone reference.',
    RegenerateStyle.moreVisual: 'Make it more visual. Focus on what the image shows, less text overlay, show don\'t tell.',
  };

  static String _getStyleInstruction(RegenerateStyle style) {
    return _stylePrompts[style] ?? '';
  }

  /// Regenerate a specific section of a content package
  static Future<RegenerationResult> regenerate(RegenerationRequest request) async {
    final pkg = request.originalPackage;
    final style = request.style;
    final instruction = _getStyleInstruction(style);

    switch (request.target) {
      case RegenerateTarget.hook:
        return _regenerateHook(pkg, instruction, style);
      case RegenerateTarget.slides:
        return _regenerateSlides(pkg, instruction, style);
      case RegenerateTarget.singleSlide:
        return _regenerateSingleSlide(pkg, request.slideIndex ?? 0, instruction, style);
      case RegenerateTarget.visualPrompts:
        return _regenerateVisualPrompts(pkg, instruction, style);
      case RegenerateTarget.caption:
        return _regenerateCaption(pkg, instruction, style);
      case RegenerateTarget.cta:
        return _regenerateCTA(pkg, instruction, style);
      case RegenerateTarget.hashtags:
        return _regenerateHashtags(pkg, instruction, style);
      case RegenerateTarget.pinnedComment:
        return _regeneratePinnedComment(pkg, instruction, style);
      case RegenerateTarget.replyComments:
        return _regenerateReplyComments(pkg, instruction, style);
    }
  }

  static RegenerationResult _regenerateHook(ContentPackage pkg, String instruction, RegenerateStyle style) {
    final baseHook = pkg.bucket.exampleHooks.first;
    String newHook;

    if (instruction.contains('funnier')) {
      newHook = '${pkg.bucket.emoji} ${pkg.bucket.exampleHooks.first} — PARENT EDITION 😂';
    } else if (instruction.contains('curiosity')) {
      newHook = 'CAN YOU SOLVE THIS? ${pkg.bucket.emoji}';
    } else if (instruction.contains('simpler')) {
      newHook = pkg.bucket.exampleHooks.first.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    } else if (instruction.contains('visual')) {
      newHook = 'LOOK CLOSELY... ${pkg.bucket.emoji}';
    } else {
      newHook = pkg.bucket.exampleHooks[(DateTime.now().millisecond) % pkg.bucket.exampleHooks.length];
    }

    return RegenerationResult(
      target: RegenerateTarget.hook,
      newValue: newHook,
      explanation: 'Regenerated hook with "${style.label}" style',
    );
  }

  static RegenerationResult _regenerateSlides(ContentPackage pkg, String instruction, RegenerateStyle style) {
    // Re-generate all slides using ContentGenerator with style instruction
    // Note: _generateFromTemplate is private, so we create a new package directly
    final newPackage = ContentGenerator.generate(
      idea: pkg.idea,
      bucket: pkg.bucket,
      format: pkg.format,
      characters: pkg.characters,
      slideCount: pkg.slideCount,
    );
    return RegenerationResult(
      target: RegenerateTarget.slides,
      newValue: (newPackage as Future<ContentPackage>).then((p) => p.slides),
      explanation: 'Regenerated all slides with "${style.label}" style',
    );
  }

  static RegenerationResult _regenerateSingleSlide(ContentPackage pkg, int index, String instruction, RegenerateStyle style) {
    if (index >= pkg.slides.length) index = pkg.slides.length - 1;
    final slide = pkg.slides[index];

    String newTitle = slide.title;
    String newBody = slide.body;

    if (instruction.contains('simpler')) {
      newBody = newBody.split('.').first + '.';
    } else if (instruction.contains('funnier')) {
      newBody = '😂 $newBody';
    } else if (instruction.contains('curiosity')) {
      newBody = 'Can you guess? $newBody';
    }

    final newSlide = SlideContent(
      index: slide.index,
      title: newTitle,
      body: newBody,
      visualPrompt: slide.visualPrompt,
      overlayText: slide.overlayText,
    );

    return RegenerationResult(
      target: RegenerateTarget.singleSlide,
      newValue: newSlide,
      explanation: 'Regenerated slide ${index + 1} with "${style.label}" style',
    );
  }

  static RegenerationResult _regenerateVisualPrompts(ContentPackage pkg, String instruction, RegenerateStyle style) {
    final newPrompts = pkg.visualPrompts.map((prompt) {
      String modified = prompt;
      if (instruction.contains('moreVisual') || instruction.contains('visual')) {
        modified = '$prompt\n\nENHANCED VISUAL FOCUS: Show the action clearly, minimal text overlay, character expressions prominent.';
      } else if (instruction.contains('simpler')) {
        modified = '$prompt\n\nSIMPLIFIED: Clean composition, single clear subject, generous negative space.';
      } else if (instruction.contains('funnier')) {
        modified = '$prompt\n\nFUNNIER: Exaggerated expressions, comedic timing visible in pose.';
      }
      return modified;
    }).toList();

    return RegenerationResult(
      target: RegenerateTarget.visualPrompts,
      newValue: newPrompts,
      explanation: 'Regenerated ${newPrompts.length} visual prompts with "${style.label}" style',
    );
  }

  static RegenerationResult _regenerateCaption(ContentPackage pkg, String instruction, RegenerateStyle style) {
    String newCaption = pkg.caption;

    if (instruction.contains('funnier')) {
      newCaption = '😂 ${pkg.caption}';
    } else if (instruction.contains('curiosity')) {
      newCaption = 'Can you guess the answer? ${pkg.caption}';
    } else if (instruction.contains('simpler')) {
      newCaption = pkg.caption.split('\n').first + '\n\n${pkg.hashtags.join(' ')}';
    } else if (instruction.contains('parentRelatable')) {
      newCaption = 'Real talk: ${pkg.caption}';
    }

    return RegenerationResult(
      target: RegenerateTarget.caption,
      newValue: newCaption,
      explanation: 'Regenerated caption with "${style.label}" style',
    );
  }

  static RegenerationResult _regenerateCTA(ContentPackage pkg, String instruction, RegenerateStyle style) {
    final ctaOptions = [
      'Save this for later 📌',
      'Share with another parent 🤝',
      'Comment your answer below 👇',
      'Follow for daily play ideas 🏠',
      'Try this today and tag us 🏷️',
      'What did your child say? 👇',
      'Tag a parent who needs this 😂',
      'Bookmark for your next activity 📌',
    ];
    final newCTA = ctaOptions[DateTime.now().millisecond % ctaOptions.length];

    return RegenerationResult(
      target: RegenerateTarget.cta,
      newValue: newCTA,
      explanation: 'Regenerated CTA with "${style.label}" style',
    );
  }

  static RegenerationResult _regenerateHashtags(ContentPackage pkg, String instruction, RegenerateStyle style) {
    final newTags = ContentGenerator.generateHashtags(pkg.bucket);
    newTags.shuffle(Random(DateTime.now().millisecondsSinceEpoch));

    return RegenerationResult(
      target: RegenerateTarget.hashtags,
      newValue: newTags,
      explanation: 'Regenerated 5 hashtags with "${style.label}" style',
    );
  }

  static RegenerationResult _regeneratePinnedComment(ContentPackage pkg, String instruction, RegenerateStyle style) {
    final comments = {
      'challenge': 'Try this with your little one — did they get it right away? 👀',
      'conversation': 'We\'d love to hear what your little one said — share it below! ❤️',
      'activity': 'Tried this yet? Tell us how your little one did!',
      'humor': 'Be honest — how many times today? 😂',
      'age_practice': 'How many can your child already do? Tell us below! 💛',
    };
    final base = comments[pkg.bucket.id] ?? 'What did you think? Comment below!';

    String newComment = base;
    if (instruction.contains('funnier')) newComment = '😂 $base';
    if (instruction.contains('curiosity')) newComment = 'Can you guess? $base';
    if (instruction.contains('simpler')) newComment = base.split('—').first.trim();

    return RegenerationResult(
      target: RegenerateTarget.pinnedComment,
      newValue: newComment,
      explanation: 'Regenerated pinned comment with "${style.label}" style',
    );
  }

  static RegenerationResult _regenerateReplyComments(ContentPackage pkg, String instruction, RegenerateStyle style) {
    final baseComments = ContentGenerator.generateReplyComments(pkg.bucket);
    final newComments = baseComments.map((c) {
      String modified = c;
      if (instruction.contains('funnier')) modified = '😂 $c';
      if (instruction.contains('curiosity')) modified = 'Wait, $c';
      if (instruction.contains('simpler')) modified = c.split(',').first + '!';
      return modified;
    }).toList();

    return RegenerationResult(
      target: RegenerateTarget.replyComments,
      newValue: newComments,
      explanation: 'Regenerated 5 reply comments with "${style.label}" style',
    );
  }
}

// Extension to add request to RegenerationResult
extension RegenerationRequestExt on RegenerationResult {
  RegenerateStyle get style => RegenerateStyle.original; // Placeholder
}