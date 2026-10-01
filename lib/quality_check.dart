import 'package:flutter/material.dart';

import 'brand_system.dart';
import 'content_generator.dart';
import 'format_adapter.dart';

enum QualitySeverity { pass, warn, fail }

class QualityRule {
  final String id;
  final String name;
  final String description;
  final QualitySeverity severity;
  final bool Function(ContentPackage pkg, Map<ContentFormat, FormatOutput> formats) check;
  final String? Function(ContentPackage pkg)? fixSuggestion;

  const QualityRule({
    required this.id,
    required this.name,
    required this.description,
    required this.severity,
    required this.check,
    this.fixSuggestion,
  });
}

class QualityResult {
  final QualityRule rule;
  final bool passed;
  final String message;
  final String? details;

  const QualityResult({
    required this.rule,
    required this.passed,
    required this.message,
    this.details,
  });

  QualitySeverity get severity => passed ? QualitySeverity.pass : rule.severity;
  Color get color => switch (severity) {
    QualitySeverity.pass => Colors.green,
    QualitySeverity.warn => Colors.orange,
    QualitySeverity.fail => Colors.red,
  };
  IconData get icon => switch (severity) {
    QualitySeverity.pass => Icons.check_circle,
    QualitySeverity.warn => Icons.warning_amber,
    QualitySeverity.fail => Icons.error,
  };
}

class QualityReport {
  final ContentPackage package;
  final Map<ContentFormat, FormatOutput> formats;
  final List<QualityResult> results;
  final DateTime checkedAt;

  const QualityReport({
    required this.package,
    required this.formats,
    required this.results,
    required this.checkedAt,
  });

  int get passCount => results.where((r) => r.passed).length;
  int get warnCount => results.where((r) => !r.passed && r.severity == QualitySeverity.warn).length;
  int get failCount => results.where((r) => !r.passed && r.severity == QualitySeverity.fail).length;
  int get totalCount => results.length;
  double get score => totalCount > 0 ? passCount / totalCount : 1.0;
  bool get isReadyToPost => failCount == 0;

  QualitySeverity get overallSeverity {
    if (failCount > 0) return QualitySeverity.fail;
    if (warnCount > 0) return QualitySeverity.warn;
    return QualitySeverity.pass;
  }

  List<QualityResult> get failures => results.where((r) => !r.passed && r.severity == QualitySeverity.fail).toList();
  List<QualityResult> get warnings => results.where((r) => !r.passed && r.severity == QualitySeverity.warn).toList();
  List<QualityResult> get passes => results.where((r) => r.passed).toList();
}

class QualityChecker {
  // ── Reach-scorer phrase lists ────────────────────────────────────────────────
  //
  // Matched case-insensitively against the lowercased text. Deliberately narrow: a
  // broad list would flag innocent phrasing and train you to ignore the warnings,
  // which is the same failure as a quality gate nobody trusts.

  /// Openings that spend the first seconds on nothing.
  static const _kIntroOpeners = [
    'ek baar ki baat',
    'aaj hum',
    'hello dosto',
    'welcome to',
    'introducing',
    'let me tell you',
    'in this video',
    'namaste',
  ];

  /// Bait the reel has to earn, and usually does not.
  static const _kBaitPhrases = [
    'wait for the end',
    "you won't believe",
    'you will not believe',
    'part 2',
    'watch till the end',
    'subscribe',
  ];

  /// Phrases that mean a cold viewer is missing context they do not have.
  static const _kAssumedContext = [
    'as you know',
    'as we all know',
    'in our last',
    'in my last',
    'if you have been watching',
    'my subscribers',
    'regulars dekho',
    'part of our series',
  ];

  /// Claims the brand is not allowed to make, since there are no real results.
  static const _kFabricatedClaims = [
    'i tried this for',
    'we tried this for',
    'after just one week',
    'guaranteed',
    '100% proven',
    'studies show',
    'research shows',
    'doctors recommend',
    'trusted by thousands',
    'our results show',
  ];

  static const _kQuestionMarks = ['?', 'kya', 'kyun', 'kaise', 'kab'];

  static const _kSaveWords = ['save', 'save karo', 'save this', 'note down', 'likh lo'];
  static const _kShareWords = ['share', 'bhejo', 'bhej do', 'forward'];
  static const _kReferenceWords = [
    'list',
    'steps',
    'step 1',
    'ideas',
    'items',
    'ways',
    'kitne',
    '5 ',
    'seven',
    'age ',
    'months',
  ];

  static String _allText(ContentPackage pkg) =>
      '${pkg.hook} ${pkg.caption} ${pkg.cta} ${pkg.pinnedComment} ${pkg.idea} '
      '${pkg.slides.map((s) => '${s.title} ${s.body}').join(' ')}'
      .toLowerCase();

  static bool _opensAQuestion(String hook) {
    final h = hook.toLowerCase();
    return _kQuestionMarks.any(h.contains);
  }

  /// The hook withholds the outcome if it states the trouble without resolving it.
  static bool _withholdsOutcome(String hook) {
    final h = hook.toLowerCase();
    final resolvers = ['because', 'solution', 'fix', 'answer', 'here is how', 'yeh kaam', 'isse'];
    return !resolvers.any(h.contains);
  }

  static bool _checkSpecificSituation(ContentPackage pkg) {
    final t = _allText(pkg);
    final generic = ['toddler behaviour', 'parenting tips', 'good parenting', 'child development'];
    if (generic.any(t.contains)) return false;
    // A specific situation is named by a concrete everyday anchor.
    const anchors = [
      'khana', 'khana', 'phone', 'bath', 'brush', 'shoes', 'kapde', 'sone',
      'neend', 'toys', 'bathroom', 'kitchen', 'tiffin', 'chai', 'screen',
      'chocolate', 'milk', 'park', 'towel', 'hair', 'nails', 'bottle',
    ];
    return anchors.any(t.contains);
  }

  static bool _payoffIsHeldBack(ContentPackage pkg) {
    if (pkg.slides.isEmpty) return false;
    final first = pkg.slides.first;
    final combined = '${first.title} ${first.body}'.toLowerCase();
    const spoilers = ['solution', 'here is how', 'answer', 'just do this', 'fix:', 'try this'];
    return !spoilers.any(combined.contains);
  }

  static bool _looksLikeReference(ContentPackage pkg) =>
      _kReferenceWords.any(_allText(pkg).contains) || pkg.slides.length >= 5;

  static bool _asksToSave(ContentPackage pkg) {
    final c = pkg.cta.toLowerCase();
    return _kSaveWords.any(c.contains) || _kSaveWords.any(pkg.pinnedComment.toLowerCase().contains);
  }

  static bool _asksToShare(ContentPackage pkg) {
    final c = pkg.cta.toLowerCase();
    return _kShareWords.any(c.contains) || _kShareWords.any(pkg.pinnedComment.toLowerCase().contains);
  }

  static bool _hasSpecificMoment(ContentPackage pkg) => _checkSpecificSituation(pkg);

  static bool _endsWithQuestion(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t.contains('?')) return true;
    final lower = t.toLowerCase();
    return ['aap', 'tum', 'comment', 'bataye', 'batao', 'which', 'kaun'].any(lower.contains);
  }

  static final List<QualityRule> _rules = [
    // ==================== HOOK RULES ====================
    QualityRule(
      id: 'hook_length',
      name: 'Hook Length',
      description: 'Hook should be under 125 characters for Instagram',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.hook.length <= 125,
      fixSuggestion: (pkg) => 'Shorten hook to under 125 chars. Remove filler words.',
    ),
    QualityRule(
      id: 'hook_not_empty',
      name: 'Hook Present',
      description: 'Every post must have a scroll-stopping hook',
      severity: QualitySeverity.fail,
      check: (pkg, _) => pkg.hook.trim().isNotEmpty,
      fixSuggestion: (pkg) => 'Add a compelling hook that stops the scroll.',
    ),
    QualityRule(
      id: 'hook_has_emoji_or_question',
      name: 'Hook Engagement',
      description: 'Hook should have emoji or question to drive engagement',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.hook.contains(RegExp(r'[🎯🔍❓😂🤔💡🌟🎉🤯😱🙈🫣👀🤷‍♀️🤷‍♂️]')) || pkg.hook.contains('?'),
      fixSuggestion: (pkg) => 'Add an emoji or question mark to increase curiosity.',
    ),
    QualityRule(
      id: 'hook_brand_voice',
      name: 'Hook Brand Voice',
      description: 'Hook should sound warm and parent-relatable, not corporate',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _checkBrandVoice(pkg.hook),
      fixSuggestion: (pkg) => 'Rewrite in warm, conversational tone. Avoid marketing speak.',
    ),

    // ==================== SLIDES RULES ====================
    QualityRule(
      id: 'slide_count_format',
      name: 'Slide Count Matches Format',
      description: 'Slide count should match format requirements',
      severity: QualitySeverity.warn,
      check: (pkg, formats) {
        final output = formats[pkg.format];
        if (output == null) return true;
        final min = pkg.format.minSlides;
        final max = pkg.format.maxSlides;
        return output.slides.length >= min && output.slides.length <= max;
      },
      fixSuggestion: (pkg) => 'Adjust slide count to ${pkg.format.minSlides}-${pkg.format.maxSlides} for ${pkg.format.label}.',
    ),
    QualityRule(
      id: 'slide_titles_not_empty',
      name: 'Slide Titles Present',
      description: 'Every slide should have a clear headline/title',
      severity: QualitySeverity.fail,
      check: (pkg, _) => pkg.slides.every((s) => s.title.trim().isNotEmpty),
      fixSuggestion: (pkg) => 'Add descriptive titles to all slides.',
    ),
    QualityRule(
      id: 'slide_bodies_not_empty',
      name: 'Slide Content Present',
      description: 'Every slide should have body content',
      severity: QualitySeverity.fail,
      check: (pkg, _) => pkg.slides.every((s) => s.body.trim().isNotEmpty),
      fixSuggestion: (pkg) => 'Add body text to all slides.',
    ),
    QualityRule(
      id: 'slide_body_length',
      name: 'Slide Body Length',
      description: 'Slide body should be concise (under 160 chars for carousel)',
      severity: QualitySeverity.warn,
      check: (pkg, _) {
        if (pkg.format == ContentFormat.carousel) {
          return pkg.slides.every((s) => s.body.length <= 160);
        }
        return true;
      },
      fixSuggestion: (pkg) => 'Shorten slide bodies to under 160 characters for carousel.',
    ),
    QualityRule(
      id: 'slide_visual_prompts',
      name: 'Visual Prompts Present',
      description: 'Every slide must have a detailed visual prompt for image generation',
      severity: QualitySeverity.fail,
      check: (pkg, _) => pkg.slides.every((s) => s.visualPrompt.trim().isNotEmpty),
      fixSuggestion: (pkg) => 'Add detailed visual prompts for all slides.',
    ),
    QualityRule(
      id: 'slide_character_consistency',
      name: 'Character Consistency in Prompts',
      description: 'Visual prompts should reference Ria, Rio, and Cuty correctly',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.slides.every((s) => 
        s.visualPrompt.toLowerCase().contains('ria') || 
        s.visualPrompt.toLowerCase().contains('rio') || 
        s.visualPrompt.toLowerCase().contains('cuty') ||
        s.visualPrompt.toLowerCase().contains('character')
      ),
      fixSuggestion: (pkg) => 'Ensure visual prompts mention Ria, Rio, and/or Cuty by name.',
    ),

    // ==================== CAPTION RULES ====================
    QualityRule(
      id: 'caption_not_empty',
      name: 'Caption Present',
      description: 'Every post must have a caption',
      severity: QualitySeverity.fail,
      check: (pkg, _) => pkg.caption.trim().isNotEmpty,
      fixSuggestion: (pkg) => 'Generate a caption with hook, value, CTA, and hashtags.',
    ),
    QualityRule(
      id: 'caption_has_cta',
      name: 'Caption Has CTA',
      description: 'Caption should include a clear call-to-action',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _hasCTA(pkg.caption),
      fixSuggestion: (pkg) => 'Add a clear CTA like "Save for later!", "Comment below!", "Tag a parent!"',
    ),
    QualityRule(
      id: 'caption_length',
      name: 'Caption Length',
      description: 'Caption should be under 2200 characters (Instagram limit)',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.caption.length <= 2200,
      fixSuggestion: (pkg) => 'Trim caption to under 2200 characters.',
    ),
    QualityRule(
      id: 'caption_has_hashtags',
      name: 'Caption Includes Hashtags',
      description: 'Caption should include the 5 hashtags',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.hashtags.isNotEmpty && pkg.caption.contains('#'),
      fixSuggestion: (pkg) => 'Ensure hashtags are included in the caption.',
    ),

    // ==================== HASHTAG RULES ====================
    QualityRule(
      id: 'hashtag_count',
      name: 'Hashtag Count',
      description: 'Should have exactly 5 hashtags',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.hashtags.length == 5,
      fixSuggestion: (pkg) => 'Adjust to exactly 5 hashtags.',
    ),
    QualityRule(
      id: 'hashtag_brand_included',
      name: 'Brand Hashtag Included',
      description: 'Should include #funlearningwithpalak',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.hashtags.any((h) => h.toLowerCase().contains('funlearningwithpalak')),
      fixSuggestion: (pkg) => 'Add #funlearningwithpalak to hashtags.',
    ),
    QualityRule(
      id: 'hashtag_no_spaces',
      name: 'Hashtag Format',
      description: 'Hashtags should not contain spaces',
      severity: QualitySeverity.fail,
      check: (pkg, _) => pkg.hashtags.every((h) => !h.contains(' ')),
      fixSuggestion: (pkg) => 'Remove spaces from hashtags (use camelCase or underscores).',
    ),

    // ==================== COMMENTS RULES ====================
    QualityRule(
      id: 'pinned_comment_present',
      name: 'Pinned Comment Present',
      description: 'Should have a pinned comment to drive engagement',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.pinnedComment.trim().isNotEmpty,
      fixSuggestion: (pkg) => 'Add a pinned comment asking a question or encouraging saves.',
    ),
    QualityRule(
      id: 'pinned_comment_question',
      name: 'Pinned Comment Drives Engagement',
      description: 'Pinned comment should ask a question or prompt action',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.pinnedComment.contains('?') || 
        pkg.pinnedComment.toLowerCase().contains('comment') ||
        pkg.pinnedComment.toLowerCase().contains('tell us') ||
        pkg.pinnedComment.toLowerCase().contains('share') ||
        pkg.pinnedComment.toLowerCase().contains('save'),
      fixSuggestion: (pkg) => 'Make pinned comment a question or clear CTA.',
    ),
    QualityRule(
      id: 'reply_comments_count',
      name: 'Reply Comments Count',
      description: 'Should have exactly 5 varied reply comments',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.replyComments.length == 5,
      fixSuggestion: (pkg) => 'Generate 5 reply comments with varied styles.',
    ),
    QualityRule(
      id: 'reply_comments_variety',
      name: 'Reply Comments Variety',
      description: 'Reply comments should cover different styles (relatable, emoji, validation, CTA)',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _checkReplyVariety(pkg.replyComments),
      fixSuggestion: (pkg) => 'Ensure 5 distinct styles: relatable parent, non-parent, emoji, validation, CTA.',
    ),

    // ==================== SCRIPT RULES ====================
    QualityRule(
      id: 'script_for_video',
      name: 'Script for Video Formats',
      description: 'Reel and Trial Reel must have a voiceover script',
      severity: QualitySeverity.fail,
      check: (pkg, _) {
        if (pkg.format == ContentFormat.reel || pkg.format == ContentFormat.trialReel) {
          return pkg.caption.isNotEmpty; // Script stored in caption for now
        }
        return true;
      },
      fixSuggestion: (pkg) => 'Generate a voiceover script for video formats.',
    ),
    QualityRule(
      id: 'script_timing',
      name: 'Script Timing Matches Format',
      description: 'Reel script should be 15-30s, Trial Reel ~60s',
      severity: QualitySeverity.warn,
      check: (pkg, _) {
        if (pkg.format == ContentFormat.reel) {
          final wordCount = pkg.caption.split(' ').length;
          final estSeconds = wordCount / 2.5; // ~150 wpm
          return estSeconds >= 10 && estSeconds <= 35;
        }
        if (pkg.format == ContentFormat.trialReel) {
          final wordCount = pkg.caption.split(' ').length;
          final estSeconds = wordCount / 2.5;
          return estSeconds >= 45 && estSeconds <= 75;
        }
        return true;
      },
      fixSuggestion: (pkg) => 'Adjust script length: Reel 15-30s (~60-120 words), Trial Reel ~60s (~150-200 words).',
    ),

    // ==================== BRAND CONSISTENCY ====================
    QualityRule(
      id: 'brand_characters_in_prompts',
      name: 'Brand Characters in Visual Prompts',
      description: 'Visual prompts should maintain character consistency (Ria, Rio, Cuty)',
      severity: QualitySeverity.warn,
      check: (pkg, formats) {
        for (final output in formats.values) {
          for (final prompt in output.imagePrompts) {
            final lower = prompt.toLowerCase();
            if (!lower.contains('ria') && !lower.contains('rio') && !lower.contains('cuty')) {
              return false;
            }
          }
        }
        return true;
      },
      fixSuggestion: (pkg) => 'Add character names (Ria, Rio, Cuty) to all visual prompts.',
    ),
    QualityRule(
      id: 'brand_visual_style',
      name: 'Brand Visual Style in Prompts',
      description: "Visual prompts should reference the brand's 3D Pixar render style",
      severity: QualitySeverity.warn,
      check: (pkg, formats) {
        for (final output in formats.values) {
          for (final prompt in output.imagePrompts) {
            final lower = prompt.toLowerCase();
            if (!lower.contains('pixar') && !lower.contains('3d')) {
              return false;
            }
          }
        }
        return true;
      },
      fixSuggestion: (pkg) =>
          'Add "${BrandDefaults.visualStyle}" to visual prompts.',
    ),
    QualityRule(
      id: 'brand_no_glasses',
      name: 'No Glasses on Characters',
      description: 'Character prompts must not include glasses (Ria and Rio never wear glasses)',
      severity: QualitySeverity.fail,
      check: (pkg, formats) {
        for (final output in formats.values) {
          for (final prompt in output.imagePrompts) {
            if (prompt.toLowerCase().contains('glasses') || prompt.toLowerCase().contains('spectacles')) {
              return false;
            }
          }
        }
        return true;
      },
      fixSuggestion: (pkg) => 'Remove any mention of glasses from visual prompts.',
    ),
    QualityRule(
      id: 'brand_cuty_bow',
      name: 'Cuty Pink Bow',
      description: 'Cuty must always be described as white bunny with pink bow',
      severity: QualitySeverity.warn,
      check: (pkg, formats) {
        for (final output in formats.values) {
          for (final prompt in output.imagePrompts) {
            if (prompt.toLowerCase().contains('cuty') || prompt.toLowerCase().contains('bunny')) {
              if (!prompt.toLowerCase().contains('pink bow')) {
                return false;
              }
            }
          }
        }
        return true;
      },
      fixSuggestion: (pkg) => 'Ensure Cuty is always "small white bunny with pink bow".',
    ),

    // ==================== BUCKET-SPECIFIC ====================
    QualityRule(
      id: 'bucket_structure',
      name: 'Bucket Structure Followed',
      description: 'Slides should follow the bucket\'s template structure',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _checkBucketStructure(pkg),
      fixSuggestion: (pkg) => 'Follow the ${pkg.bucket.name} template: ${pkg.bucket.slideTemplates.take(3).join(" → ")}...',
    ),
    QualityRule(
      id: 'bucket_cta_relevant',
      name: 'Bucket-Appropriate CTA',
      description: 'CTA should match the bucket type',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _checkBucketCTA(pkg),
      fixSuggestion: (pkg) => 'Use ${pkg.bucket.id} appropriate CTA: ${_expectedCTA(pkg.bucket)}',
    ),

    // ==================== ACCESSIBILITY ====================
    QualityRule(
      id: 'alt_text_potential',
      name: 'Alt Text Potential',
      description: 'Visual prompts should be descriptive enough for alt text',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.slides.every((s) => s.visualPrompt.length > 50),
      fixSuggestion: (pkg) => 'Expand visual prompts to be more descriptive for accessibility.',
    ),
    QualityRule(
      id: 'readable_language',
      name: 'Readable Language',
      description: 'Content should use simple language (grade 6 reading level)',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _checkReadability(pkg),
      fixSuggestion: (pkg) => 'Simplify language: shorter words, shorter sentences, avoid jargon.',
    ),

    // ==================== REACH POTENTIAL ====================
    //
    // Ten dimensions from the growth scorecard, folded in here rather than built as a
    // third scorer. The app already had two quality checkers disagreeing with each
    // other; this keeps one gate.
    //
    // Every one is a WARN on purpose. `isReadyToPost` is `failCount == 0`, so a warn
    // can never block a post. These are the model's own opinion of its own output, so
    // they are a prompt to reconsider, never a verdict, and never a view prediction.
    // The UI must label them as an internal heuristic.
    QualityRule(
      id: 'reach_hook_strength',
      name: 'Reach: Hook Strength',
      description: 'Hook is short enough to land in the first second and carries a concrete image',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.hook.trim().isNotEmpty && pkg.hook.trim().length <= 125,
      fixSuggestion: (pkg) => 'Shorten the hook to under 125 characters and name something concrete that happens on screen.',
    ),
    QualityRule(
      id: 'reach_hook_no_intro',
      name: 'Reach: No Opening Filler',
      description: 'Hook starts in the middle of the trouble, not with an introduction',
      severity: QualitySeverity.warn,
      check: (pkg, _) => !_kIntroOpeners.any((o) => pkg.hook.trim().toLowerCase().startsWith(o)),
      fixSuggestion: (pkg) => 'Open on the moment itself. Cut "ek baar ki baat hai", greetings, and any series introduction.',
    ),
    QualityRule(
      id: 'reach_no_bait',
      name: 'Reach: No Bait',
      description: 'No bait the story does not pay off. Hooks must be true of the content',
      severity: QualitySeverity.warn,
      check: (pkg, _) => !_kBaitPhrases.any((b) => pkg.hook.toLowerCase().contains(b)),
      fixSuggestion: (pkg) => 'Remove "wait for the end" / "you will not believe". A hook that is not true of the reel wins one view and loses a follower.',
    ),
    QualityRule(
      id: 'reach_curiosity',
      name: 'Reach: Curiosity Gap',
      description: 'Hook opens a question the content answers later, rather than stating the outcome up front',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _opensAQuestion(pkg.hook) || _withholdsOutcome(pkg.hook),
      fixSuggestion: (pkg) => 'Say what happened, not what it means, and do not answer it in the same line.',
    ),
    QualityRule(
      id: 'reach_non_follower',
      name: 'Reach: Non-Follower Appeal',
      description: 'Hook is understandable to someone who has never seen the page before',
      severity: QualitySeverity.warn,
      check: (pkg, _) => !_kAssumedContext.any((a) => pkg.hook.toLowerCase().contains(a)),
      fixSuggestion: (pkg) => 'Drop references that need prior context ("as you know", "in our last reel", "my series"). A stranger should get it cold.',
    ),
    QualityRule(
      id: 'reach_relatable',
      name: 'Reach: Relatability',
      description: 'Names a specific everyday situation, not a generic parenting problem',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _checkSpecificSituation(pkg),
      fixSuggestion: (pkg) => 'Name the exact moment, e.g. "phone chahiye at meal time", not "toddler behaviour issues".',
    ),
    QualityRule(
      id: 'reach_watchtime',
      name: 'Reach: Watch-Time Potential',
      description: 'Enough beats to hold, and the payoff is not given away in the first beat',
      severity: QualitySeverity.warn,
      check: (pkg, _) => pkg.slides.length >= 3 && _payoffIsHeldBack(pkg),
      fixSuggestion: (pkg) => 'Show the problem first, then the turn. Do not put the solution in the opening slide.',
    ),
    QualityRule(
      id: 'reach_save',
      name: 'Reach: Save Potential',
      description: 'Something a parent returns to, or an explicit reason to save',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _looksLikeReference(pkg) || _asksToSave(pkg),
      fixSuggestion: (pkg) => 'Make it a reference (a list, steps, ages, quantities) or give a concrete reason to save it.',
    ),
    QualityRule(
      id: 'reach_share',
      name: 'Reach: Share Potential',
      description: 'Contains a specific moment a parent would send to another parent',
      severity: QualitySeverity.warn,
      check: (pkg, _) => _asksToShare(pkg) || _hasSpecificMoment(pkg),
      fixSuggestion: (pkg) => 'Name the exact shared moment, e.g. the next time the phone is demanded at dinner.',
    ),
    QualityRule(
      id: 'reach_comment',
      name: 'Reach: Comment Potential',
      description: 'Ends in something a parent would actually answer',
      severity: QualitySeverity.warn,
      check: (pkg, _) =>
          _endsWithQuestion(pkg.cta) || _endsWithQuestion(pkg.pinnedComment) || _endsWithQuestion(pkg.replyComments.lastOrNull ?? ''),
      fixSuggestion: (pkg) => 'Close with one real question. A question gets answered; "follow for more" does not.',
    ),
    QualityRule(
      id: 'reach_originality',
      name: 'Reach: Originality and No Invented Claims',
      description: 'No fabricated statistics, results, clients or personal experience',
      severity: QualitySeverity.warn,
      check: (pkg, _) => !_kFabricatedClaims.any((c) => _allText(pkg).contains(c)),
      fixSuggestion: (pkg) => 'Remove invented numbers and first-person results. Describe the situation instead of claiming an outcome.',
    ),
  ];

  static List<QualityRule> get rules => List.unmodifiable(_rules);

  static QualityReport check(ContentPackage pkg, Map<ContentFormat, FormatOutput> formats) {
    final results = _rules.map((rule) {
      final passed = rule.check(pkg, formats);
      String message;
      if (passed) {
        message = '✓ ${rule.name}';
      } else {
        final suggestion = rule.fixSuggestion?.call(pkg) ?? 'Fix required';
        message = rule.severity == QualitySeverity.fail 
            ? '✗ ${rule.name}: $suggestion'
            : '⚠ ${rule.name}: $suggestion';
      }
      return QualityResult(
        rule: rule,
        passed: passed,
        message: message,
        details: passed ? null : rule.description,
      );
    }).toList();

    return QualityReport(
      package: pkg,
      formats: formats,
      results: results,
      checkedAt: DateTime.now(),
    );
  }

  // ==================== HELPER METHODS ====================
  static bool _checkBrandVoice(String text) {
    final lower = text.toLowerCase();
    // Check for warm, conversational indicators
    final warmWords = ['you', 'your', 'little one', 'child', 'kid', 'try', 'save', 'fun', 'play', 'love', 'cute', 'sweet'];
    final corporateWords = ['optimize', 'leverage', 'synergy', 'solution', 'platform', 'ecosystem', 'streamline', 'maximize'];
    
    final hasWarm = warmWords.any(lower.contains);
    final hasCorporate = corporateWords.any(lower.contains);
    
    return hasWarm && !hasCorporate;
  }

  static bool _hasCTA(String caption) {
    final ctaPatterns = [
      r'save\s+(this|for\s+later)',
      r'comment\s+(below|your)',
      r'tag\s+(a\s+)?(parent|friend|someone)',
      r'follow\s+(for|us)',
      r'try\s+(this|today|now)',
      r'bookmark',
      r'share\s+(with|this)',
      r'what\s+(did|would|is)',
      r'\?',
    ];
    final lower = caption.toLowerCase();
    return ctaPatterns.any((p) => lower.contains(RegExp(p)));
  }

  static bool _checkReplyVariety(List<String> comments) {
    if (comments.length != 5) return false;
    
    final styles = <String>{};
    for (final c in comments) {
      final lower = c.toLowerCase();
      if (lower.contains('my ') || lower.contains('i ') || lower.contains('we ')) styles.add('relatable_parent');
      if (lower.contains('😂') || lower.contains('😭') || lower.contains('😅') || lower.contains('🤣')) styles.add('emoji');
      if (lower.contains('true') || lower.contains('so true') || lower.contains('exactly') || lower.contains('accurate')) styles.add('validation');
      if (lower.contains('?') || lower.contains('comment') || lower.contains('tell') || lower.contains('share')) styles.add('cta');
      if (!lower.contains('my') && !lower.contains('i ') && !lower.contains('we ') && !styles.contains('emoji') && !styles.contains('validation')) styles.add('non_parent');
    }
    
    return styles.length >= 3; // At least 3 distinct styles
  }

  static bool _checkBucketStructure(ContentPackage pkg) {
    final templates = pkg.bucket.slideTemplates;
    if (pkg.slides.length < templates.length) return false;
    
    // Check first slide is cover/hook
    if (templates.isNotEmpty && templates.first.toLowerCase().contains('cover')) {
      if (!pkg.slides.first.title.toLowerCase().contains('cover') && 
          !pkg.slides.first.title.toLowerCase().contains('hook')) {
        return false;
      }
    }
    
    // Check last slide has CTA
    if (templates.isNotEmpty && templates.last.toLowerCase().contains('cta')) {
      if (!pkg.slides.last.title.toLowerCase().contains('action') &&
          !pkg.slides.last.title.toLowerCase().contains('cta') &&
          !pkg.slides.last.title.toLowerCase().contains('save')) {
        return false;
      }
    }
    
    return true;
  }

  static bool _checkBucketCTA(ContentPackage pkg) {
    final cta = pkg.cta.toLowerCase();
    switch (pkg.bucket.id) {
      case 'challenge':
        return cta.contains('comment') || cta.contains('answer') || cta.contains('save');
      case 'conversation':
        return cta.contains('comment') || cta.contains('answer') || cta.contains('save') || cta.contains('try');
      case 'activity':
        return cta.contains('save') || cta.contains('try') || cta.contains('later');
      case 'humor':
        return cta.contains('tag') || cta.contains('comment') || cta.contains('share');
      case 'age_practice':
        return cta.contains('save') || cta.contains('bookmark') || cta.contains('later');
      case 'community':
        return cta.contains('comment') || cta.contains('vote') || cta.contains('tell');
      default:
        return true;
    }
  }

  static String _expectedCTA(ContentBucket bucket) {
    switch (bucket.id) {
      case 'challenge': return '"Comment your answer" or "Save for later"';
      case 'conversation': return '"Comment their answer" or "Save for bedtime"';
      case 'activity': return '"Save for later" or "Try today"';
      case 'humor': return '"Tag a parent" or "Comment your version"';
      case 'age_practice': return '"Bookmark for milestone check" or "Save for later"';
      case 'community': return '"Vote in the comments" or "Tell us your pick"';
      default: return 'Any clear CTA';
    }
  }

  static bool _checkReadability(ContentPackage pkg) {
    // Simple check: average words per sentence < 20, no overly complex words
    final allText = '${pkg.hook} ${pkg.caption} ${pkg.slides.map((s) => '${s.title} ${s.body}').join(' ')}';
    final sentences = allText.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isEmpty) return true;
    
    final avgWordsPerSentence = sentences.map((s) => s.trim().split(' ').length).reduce((a, b) => a + b) / sentences.length;
    
    // Check for complex words (3+ syllables approximated by length > 10)
    final words = allText.split(' ');
    final complexWords = words.where((w) => w.length > 10).length;
    final complexRatio = complexWords / words.length;
    
    return avgWordsPerSentence <= 20 && complexRatio < 0.15;
  }
}