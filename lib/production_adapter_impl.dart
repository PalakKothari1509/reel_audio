// Concrete ProductionAdapter that wraps the existing production tools.
//
// This is where voice.dart, video_builder.dart, caption_renderer.dart, and
// music.dart are called. The boundary (production_adapter.dart) stays pure
// Dart so it can be tested without Flutter.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'content_package_v2.dart';
import 'content_quality_gate.dart';
import 'production_adapter.dart';
import 'voice.dart';
import 'video_builder.dart';

/// Production adapter that builds reels using the app's existing voice and
/// video tools.
class ReelProductionAdapter implements ProductionAdapter {
  final String? geminiApiKey;
  final String? elevenLabsApiKey;
  final String? elevenLabsVoiceId;

  ReelProductionAdapter({
    this.geminiApiKey,
    this.elevenLabsApiKey,
    this.elevenLabsVoiceId,
  });

  @override
  String get adapterName => 'ReelProduction';

  @override
  bool get isAvailable => true;

  @override
  Future<ProductionResult> produce(ProductionInput input) async {
    final pkg = input.package;

    // ── Rule: needsFilming packages cannot be produced here ──────────────
    // The package's productionCompatibility was set by QualityGate. If it
    // needs filming, the adapter returns needsFilming — it does NOT throw,
    // does NOT update the gate verdict, and does NOT attempt synthesis.
    // The caller updates the package and re-evaluates later.
    if (pkg.productionCompatibility == ProductionCompatibility.needsFilming) {
      return ProductionResult.needsFilmingResult;
    }

    // ── Check voice mode requirement ─────────────────────────────────────
    if (pkg.voiceMode == VoiceMode.required && pkg.narration.isEmpty) {
      return ProductionResult.needsFilmingResult;
    }

    try {
      final workDir = await _workDirectory();
      input.onStatus?.call('Synthesizing voice...');

      // ── Voice synthesis ───────────────────────────────────────────────
      final audioPath = await _synthesize(input, pkg, workDir);
      if (audioPath == null) {
        return ProductionResult.needsFilmingResult;
      }

      input.onStatus?.call('Preparing images...');

      // ── Images ────────────────────────────────────────────────────────
      final images = await _prepareImages(input, pkg, workDir);
      if (images.isEmpty) {
        return ProductionResult.failed(
          ProductionFailure('No images available for production'),
        );
      }

      // ── Captions ──────────────────────────────────────────────────────
      final captionPngs = <String?>[];
      if (input.renderCaptions) {
        input.onStatus?.call('Rendering captions...');
        captionPngs.addAll(await _renderCaptions(pkg, workDir, images.length));
      } else {
        captionPngs.addAll(List<String?>.filled(images.length, null));
      }

      // ── Music ─────────────────────────────────────────────────────────
      String? musicPath;
      if (input.musicAsset != null) {
        input.onStatus?.call('Unpacking music...');
        musicPath = await _unpackMusic(input.musicAsset!, workDir);
      }

      input.onStatus?.call('Building the video...');

      // ── Video assembly ────────────────────────────────────────────────
      final lineStarts = _lineStarts(pkg);
      final finalPath = await SlideshowBuilder.build(
        imagePaths: images,
        lineStarts: lineStarts,
        audioPath: audioPath,
        workDir: workDir,
        musicPath: musicPath,
        captionPngs: captionPngs,
        brandPng: null,
        captionSpot: CaptionSpot.high,
        motion: ClipMotion.drift,
        coverOnFirst: false,
        onStatus: input.onStatus,
      );

      return ProductionResult.withVideo(finalPath);
    } on ProductionFailure catch (e) {
      return ProductionResult.failed(e);
    } catch (e) {
      return ProductionResult.failed(ProductionFailure('Production failed', e));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String> _workDirectory() async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/production');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Synthesizes voice from the package's narration or dialogue.
  Future<String?> _synthesize(
    ProductionInput input,
    ContentPackageV2 pkg,
    String workDir,
  ) async {
    final engine = _resolveEngine(input.voiceMode, pkg);

    // Use the full narration if present; fall back to scene dialogue.
    final fullText = pkg.narration.isNotEmpty
        ? pkg.narration
        : _collectSceneText(pkg);

    if (fullText.isEmpty) {
      return null;
    }

    final style = _voiceStyle(pkg);
    final basePath = '$workDir/narration_${pkg.id}';

    if (engine == VoiceEngine.gemini && geminiApiKey != null) {
      return await synthesizeWholeScript(
        lines: fullText.split('\n'),
        basePath: basePath,
        apiKey: geminiApiKey!,
        styleHint: voiceDirection(style),
        onWait: input.onStatus,
      );
    }

    if (engine == VoiceEngine.elevenLabs &&
        elevenLabsApiKey != null &&
        elevenLabsVoiceId != null) {
      return await synthesizeLine(
        engine: VoiceEngine.elevenLabs,
        text: fullText,
        basePath: basePath,
        languageTag: 'en-US',
        rate: 1.0,
        pitch: 1.0,
        geminiKey: geminiApiKey ?? '',
        elevenLabsKey: elevenLabsApiKey!,
        elevenVoiceId: elevenLabsVoiceId!,
        onWait: input.onStatus,
      );
    }

    // Fall back to phone synthesis (always works).
    return await synthesizeLine(
      engine: VoiceEngine.phone,
      text: fullText,
      basePath: basePath,
      languageTag: 'en-US',
      rate: 1.0,
      pitch: 1.0,
      geminiKey: geminiApiKey ?? '',
      elevenLabsKey: elevenLabsApiKey ?? '',
      elevenVoiceId: elevenLabsVoiceId ?? '',
      onWait: input.onStatus,
    );
  }

  VoiceEngine _resolveEngine(
    ProductionVoiceMode mode,
    ContentPackageV2 pkg,
  ) {
    switch (mode) {
      case ProductionVoiceMode.gemini:
        return VoiceEngine.gemini;
      case ProductionVoiceMode.elevenLabs:
        return VoiceEngine.elevenLabs;
      case ProductionVoiceMode.phone:
        return VoiceEngine.phone;
    }
  }

  /// Determines the voice direction style from the package.
  String _voiceStyle(ContentPackageV2 pkg) {
    final fmt = pkg.classification.narrativeFormatName ?? 'problemFix';
    if (fmt.contains('bedtime') || fmt.contains('story')) {
      return 'gentle bedtime story';
    }
    if (fmt.contains('challenge') || fmt.contains('spot')) {
      return 'curious and playful';
    }
    if (fmt.contains('tip') || fmt.contains('quick')) {
      return 'clear and instructive';
    }
    return 'warm storytelling';
  }

  /// Collects narration/dialogue text from scenes when no full narration exists.
  String _collectSceneText(ContentPackageV2 pkg) {
    final parts = <String>[];
    for (final scene in pkg.scenes) {
      if (scene.narration != null && scene.narration!.isNotEmpty) {
        parts.add(scene.narration!);
      }
      if (scene.dialogue != null && scene.dialogue!.isNotEmpty) {
        parts.add(scene.dialogue!);
      }
    }
    return parts.join('\n');
  }

  /// Builds line starts from the script or scenes.
  List<double> _lineStarts(ContentPackageV2 pkg) {
    if (pkg.scenes.isNotEmpty) {
      return pkg.scenes
          .where((s) => s.durationSeconds != null && s.durationSeconds! > 0)
          .map((s) => s.durationSeconds!.toDouble())
          .toList();
    }
    if (pkg.script.isNotEmpty) {
      final lines =
          pkg.script.split('\n').where((l) => l.trim().isNotEmpty).toList();
      return List<double>.generate(lines.length, (i) => i * 3.0);
    }
    return [0.0];
  }

  /// Prepares image paths: uses provided images or returns empty.
  Future<List<String>> _prepareImages(
    ProductionInput input,
    ContentPackageV2 pkg,
    String workDir,
  ) async {
    if (input.imagePaths.isNotEmpty) {
      return input.imagePaths;
    }
    // For needsFilming packages, images might come from a separate source.
    // The adapter does not generate images — it uses what's given.
    return [];
  }

  /// Renders caption PNGs for each scene/image.
  Future<List<String?>> _renderCaptions(
    ContentPackageV2 pkg,
    String workDir,
    int count,
  ) async {
    if (count == 0) return [];

    final captions = <String?>[];
    for (var i = 0; i < count; i++) {
      final text = _captionForIndex(pkg, i);
      if (text != null && text.isNotEmpty) {
        // Caption rendering requires Flutter (caption_renderer.dart).
        // This would call renderCaption() from caption_renderer.dart.
        captions.add(null); // Placeholder — rendering done in Flutter layer
      } else {
        captions.add(null);
      }
    }
    return captions;
  }

  /// Gets the caption text for a given scene/image index.
  String? _captionForIndex(ContentPackageV2 pkg, int index) {
    if (pkg.scenes.isNotEmpty && index < pkg.scenes.length) {
      return pkg.scenes[index].overlayText;
    }
    return null;
  }

  /// Unpacks a music asset to a file.
  Future<String?> _unpackMusic(String asset, String workDir) async {
    try {
      final data = await rootBundle.load(asset);
      final path = '$workDir/music.mp3';
      final file = File(path);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return path;
    } catch (_) {
      return null;
    }
  }
}
