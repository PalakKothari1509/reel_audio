// Concrete AiContentService that wraps the existing AIProvider.
//
// This is where the legacy ContentPackage (v1) is converted to the
// GeneratedContent intermediate, and then to ContentPackageV2 (v2).
// Screens import AiContentService (the abstract boundary) and receive
// an AiContentServiceImpl at runtime — they never touch AIProvider directly.

import 'ai_content_service.dart';
import 'ai_provider.dart';
import 'brand_system.dart';
import 'content_generator.dart';
import 'content_package_v2.dart';

/// Concrete [AiContentService] backed by an existing [AIProvider].
class AiContentServiceImpl extends AiContentServiceImplBase {
  final AIProvider _provider;

  AiContentServiceImpl(this._provider);

  @override
  String get providerName => _provider.providerName;

  @override
  bool get isAvailable => _provider.isAvailable;

  @override
  Future<GeneratedContent> generateContent(GenerationRequest request) async {
    final input = IdeaInput(
      topic: request.hook,
      bucket: _resolveBucket(request),
      targetFormats: _resolveFormats(request),
      brand: BrandContext.defaultContext(),
    );

    try {
      final pkg = await _provider.generate(input);
      return _convert(pkg);
    } on Exception catch (e) {
      throw AiContentFailure('AI generation failed: $e', e);
    }
  }

  ContentBucket _resolveBucket(GenerationRequest request) {
    final goal = request.gateReport.classification.goal;
    if (goal != null) {
      return BucketLibrary.all.firstWhere(
        (b) => b.id == goal.name,
        orElse: () => BucketLibrary.challenge,
      );
    }
    return BucketLibrary.challenge;
  }

  List<ContentFormat> _resolveFormats(GenerationRequest request) {
    return ContentFormat.values;
  }

  GeneratedContent _convert(ContentPackage pkg) {
    final scenes = pkg.slides.asMap().entries.map((entry) {
      return Scene(
        index: entry.key,
        title: entry.value.title,
        description: entry.value.body,
        visualPrompt: entry.value.visualPrompt,
        narration: null,
        dialogue: null,
        overlayText: entry.value.overlayText,
        durationSeconds: null,
      );
    }).toList();

    return GeneratedContent(
      title: pkg.hook,
      hook: pkg.hook,
      script: pkg.slides.map((s) => s.body).join('\n\n'),
      narration: '',
      dialogue: '',
      caption: pkg.caption,
      cta: pkg.cta,
      hashtags: pkg.hashtags,
      scenes: scenes,
      imagePrompts: pkg.visualPrompts,
      shotList: scenes.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return ShotListItem(
          shotNumber: i,
          title: s.title,
          visualDescription: s.visualPrompt,
          cameraMove: '',
          lighting: '',
          durationSeconds: 3,
          characters: [],
        );
      }).toList(),
    );
  }
}
