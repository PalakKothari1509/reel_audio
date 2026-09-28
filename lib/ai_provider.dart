import 'brand_system.dart';
import 'content_generator.dart';
import 'regenerator.dart';

import 'package:flutter/foundation.dart';

class IdeaInput {
  final String topic;
  final ContentBucket bucket;
  final List<ContentFormat> targetFormats;
  final BrandContext brand;
  final List<Character> characters;
  final int? slideCount;
  final Map<String, dynamic>? extraContext;

  const IdeaInput({
    required this.topic,
    required this.bucket,
    required this.targetFormats,
    required this.brand,
    this.characters = const [CharacterLibrary.ria, CharacterLibrary.rio, CharacterLibrary.cuty],
    this.slideCount,
    this.extraContext,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'bucket': bucket.id,
        'targetFormats': targetFormats.map((f) => f.name).toList(),
        'characters': characters.map((c) => c.id).toList(),
        'slideCount': slideCount,
        'extraContext': extraContext,
      };
}

abstract class AIProvider {
  Future<ContentPackage> generate(IdeaInput input);
  Future<ContentPackage> regenerate(ContentPackage pkg, RegenerateTarget target, RegenerateStyle style);
  Future<void> testConnection();
  String get providerName;
  bool get isAvailable;
}

class BrandContext {
  final String brandName;
  final String handle;
  final String audience;
  final String tone;
  final String visualStyle;
  final List<String> defaultHashtags;
  final List<String> ctaOptions;
  final List<Character> characters;

  const BrandContext({
    required this.brandName,
    required this.handle,
    required this.audience,
    required this.tone,
    required this.visualStyle,
    required this.defaultHashtags,
    required this.ctaOptions,
    required this.characters,
  });

  static BrandContext defaultContext() {
    return BrandContext(
      brandName: BrandDefaults.name,
      handle: BrandDefaults.handle,
      audience: BrandDefaults.audience,
      tone: BrandDefaults.tone,
      visualStyle: BrandDefaults.visualStyle,
      defaultHashtags: BrandDefaults.hashtagPool.take(BrandDefaults.hashtagCount).toList(),
      ctaOptions: BrandDefaults.ctaOptions,
      characters: CharacterLibrary.all,
    );
  }

  String toPromptString() {
    final charBlock = characters.map((c) => c.fullProfile).join('\n\n');
    return '''
Brand: $brandName ($handle)
Audience: $audience
Tone: $tone
Visual Style: $visualStyle
Default Hashtags: ${defaultHashtags.join(' ')}
CTA Options: ${ctaOptions.join(' | ')}

$charBlock

${CharacterLibrary.characterLockBlock}
''';
  }
}

class AIProviderWithFallback implements AIProvider {
  final AIProvider _primary;
  // ignore: unused_field
  final ContentGenerator _fallback;

  AIProviderWithFallback(this._primary, this._fallback);

  @override
  Future<ContentPackage> generate(IdeaInput input) async {
    try {
      if (!_primary.isAvailable) {
        throw Exception('Primary provider not available');
      }
      return await _primary.generate(input);
    } on Exception catch (e) {
      debugPrint('Primary AI provider failed, falling back to template: $e');
      return _generateFromFallback(input);
    }
  }

  @override
  Future<ContentPackage> regenerate(ContentPackage pkg, RegenerateTarget target, RegenerateStyle style) async {
    try {
      if (!_primary.isAvailable) {
        throw Exception('Primary provider not available');
      }
      return await _primary.regenerate(pkg, target, style);
    } on Exception catch (e) {
      debugPrint('Primary AI regenerate failed, using local regenerator: $e');
      final result = await Regenerator.regenerate(RegenerationRequest(
        originalPackage: pkg,
        target: target,
        style: style,
      ));
      // Apply the regeneration result to create a new package
      return _applyRegeneration(pkg, target, result);
    }
  }

  @override
  Future<void> testConnection() async {
    await _primary.testConnection();
  }

  @override
  String get providerName => '${_primary.providerName} (with fallback)';

  @override
  bool get isAvailable => _primary.isAvailable;

  ContentPackage _generateFromFallback(IdeaInput input) {
    return ContentGenerator.generateFromTemplate(
      input.topic,
      input.bucket,
      input.targetFormats.first,
      input.characters,
      input.slideCount ?? input.targetFormats.first.defaultSlideCount,
    );
  }

  ContentPackage _applyRegeneration(ContentPackage pkg, RegenerateTarget target, RegenerationResult result) {
    switch (target) {
      case RegenerateTarget.hook:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: result.newValue as String,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: pkg.pinnedComment,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.caption:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: result.newValue as String,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: pkg.pinnedComment,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.cta:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: result.newValue as String,
          hashtags: pkg.hashtags,
          pinnedComment: pkg.pinnedComment,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.hashtags:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: result.newValue as List<String>,
          pinnedComment: pkg.pinnedComment,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.pinnedComment:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: result.newValue as String,
          replyComments: pkg.replyComments,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.replyComments:
        return ContentPackage(
          id: pkg.id,
          idea: pkg.idea,
          bucket: pkg.bucket,
          format: pkg.format,
          characters: pkg.characters,
          hook: pkg.hook,
          slides: pkg.slides,
          visualPrompts: pkg.visualPrompts,
          caption: pkg.caption,
          cta: pkg.cta,
          hashtags: pkg.hashtags,
          pinnedComment: pkg.pinnedComment,
          replyComments: result.newValue as List<String>,
          createdAt: pkg.createdAt,
        );
      case RegenerateTarget.slides:
      case RegenerateTarget.singleSlide:
      case RegenerateTarget.visualPrompts:
        // For these, we'd need more complex reconstruction
        // For now return original package
        return pkg;
    }
  }
}

class NoOpAIProvider implements AIProvider {
  @override
  Future<ContentPackage> generate(IdeaInput input) async {
    throw Exception('No AI provider configured');
  }

  @override
  Future<ContentPackage> regenerate(ContentPackage pkg, RegenerateTarget target, RegenerateStyle style) async {
    throw Exception('No AI provider configured');
  }

  @override
  Future<void> testConnection() async {
    throw Exception('No AI provider configured');
  }

  @override
  String get providerName => 'None';

  @override
  bool get isAvailable => false;
}