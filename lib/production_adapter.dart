// Production adapter boundary layer.
//
// AiContentService answers "what content to generate?" and QualityGate answers
// "is this allowed?". ProductionAdapter answers "how do I turn this package into
// media files?".
//
// The boundary is pure Dart so it can be tested and swapped without pulling in
// Flutter or FFmpeg. The concrete implementation lives in production_adapter_impl.dart.
//
// Key rule: ProductionAdapter NEVER touches QualityGate or GateReport.
// A production failure (missing footage, synthesis error) is reported as
// ProductionResult.needsFilming — it updates the package's
// productionCompatibility, NOT the gate verdict.

import 'content_package_v2.dart';

/// Input to the production adapter: the package to produce plus
/// production-specific choices.
class ProductionInput {
  /// The package whose content should be produced into media.
  final ContentPackageV2 package;

  /// Voice engine to use for synthesis.
  final ProductionVoiceMode voiceMode;

  /// Whether captions should be rendered as overlays.
  final bool renderCaptions;

  /// Music track asset name, or null for no music.
  final String? musicAsset;

  /// Pre-generated image paths for scenes, or empty to use imagePrompts.
  final List<String> imagePaths;

  /// Optional callback for status updates during production.
  final void Function(String message)? onStatus;

  const ProductionInput({
    required this.package,
    this.voiceMode = ProductionVoiceMode.gemini,
    this.renderCaptions = true,
    this.musicAsset,
    this.imagePaths = const [],
    this.onStatus,
  });
}

/// Which voice engine to use.
enum ProductionVoiceMode { gemini, elevenLabs, phone }

/// The result of a production attempt.
class ProductionResult {
  /// Whether production succeeded.
  final bool isSuccess;

  /// The produced video file path, when successful.
  final String? videoPath;

  /// Whether the package requires filming to complete.
  final bool needsFilming;

  /// Whether production failed.
  final bool isFailure;

  /// The failure exception, when failed.
  final ProductionFailure? failure;

  const ProductionResult._({
    required this.isSuccess,
    required this.videoPath,
    required this.needsFilming,
    required this.isFailure,
    this.failure,
  });

  /// Production succeeded — videoPath is available.
  static const ProductionResult success = ProductionResult._(
    isSuccess: true,
    videoPath: null,
    needsFilming: false,
    isFailure: false,
  );

  /// Production cannot complete — the package needs filming.
  static const ProductionResult needsFilmingResult = ProductionResult._(
    isSuccess: false,
    videoPath: null,
    needsFilming: true,
    isFailure: false,
  );

  /// Production failed — see [failure] for details.
  static ProductionResult failed(ProductionFailure failure) =>
      ProductionResult._(
        isSuccess: false,
        videoPath: null,
        needsFilming: false,
        isFailure: true,
        failure: failure,
      );

  /// Create a successful result with the given video path.
  static ProductionResult withVideo(String path) => ProductionResult._(
        isSuccess: true,
        videoPath: path,
        needsFilming: false,
        isFailure: false,
      );
}

/// Exception thrown when production fails.
class ProductionFailure implements Exception {
  final String message;
  final Object? cause;

  const ProductionFailure(this.message, [this.cause]);

  @override
  String toString() => 'ProductionFailure: $message';
}

/// The abstract boundary for media production.
///
/// Screens hold a [ProductionAdapter] and call [produce()] with a
/// [ProductionInput]. They never call voice or video tools directly.
abstract class ProductionAdapter {
  /// Produces media from the given input.
  ///
  /// Returns a [ProductionResult]. On success, [ProductionResult.videoPath] is
  /// set. If the package requires filming (e.g. missing video footage), returns
  /// [ProductionResult.needsFilmingResult].
  Future<ProductionResult> produce(ProductionInput input);

  /// A human-readable name for this adapter.
  String get adapterName;

  /// Whether the adapter is available (dependencies installed, keys present).
  bool get isAvailable;
}
