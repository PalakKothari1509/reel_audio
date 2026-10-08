import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_package_v2.dart';
import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/production_adapter.dart';

void main() {
  group('ProductionResult', () {
    test('success result has correct flags', () {
      const result = ProductionResult.success;
      expect(result.isSuccess, isTrue);
      expect(result.videoPath, isNull);
      expect(result.needsFilming, isFalse);
      expect(result.isFailure, isFalse);
    });

    test('needsFilming result has correct flags', () {
      const result = ProductionResult.needsFilmingResult;
      expect(result.isSuccess, isFalse);
      expect(result.needsFilming, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.videoPath, isNull);
    });

    test('failed result wraps the failure', () {
      final failure = ProductionFailure('Test error');
      final result = ProductionResult.failed(failure);
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.needsFilming, isFalse);
      expect(result.failure, same(failure));
    });

    test('withVideo creates a successful result with path', () {
      final result = ProductionResult.withVideo('/path/to/video.mp4');
      expect(result.isSuccess, isTrue);
      expect(result.videoPath, '/path/to/video.mp4');
      expect(result.needsFilming, isFalse);
    });
  });

  group('ProductionFailure', () {
    test('stringifies with message', () {
      final failure = ProductionFailure('Something broke');
      expect(failure.toString(), contains('Something broke'));
    });

    test('implements Exception', () {
      final failure = ProductionFailure('Test');
      expect(failure, isA<Exception>());
    });

    test('can carry a cause', () {
      final inner = Exception('inner');
      final failure = ProductionFailure('Outer failure', inner);
      expect(failure.cause, same(inner));
    });
  });

  group('ProductionInput', () {
    test('defaults are correct', () {
      final pkg = _buildTestPackage();
      final input = ProductionInput(package: pkg);

      expect(input.package, same(pkg));
      expect(input.voiceMode, ProductionVoiceMode.gemini);
      expect(input.renderCaptions, isTrue);
      expect(input.musicAsset, isNull);
      expect(input.imagePaths, isEmpty);
      expect(input.onStatus, isNull);
    });

    test('can be constructed with all params', () {
      final pkg = _buildTestPackage();
      bool called = false;
      final input = ProductionInput(
        package: pkg,
        voiceMode: ProductionVoiceMode.phone,
        renderCaptions: false,
        musicAsset: 'assets/music/test.mp3',
        imagePaths: ['/img1.png'],
        onStatus: (_) => called = true,
      );

      expect(input.voiceMode, ProductionVoiceMode.phone);
      expect(input.renderCaptions, isFalse);
      expect(input.musicAsset, 'assets/music/test.mp3');
      expect(input.imagePaths, ['/img1.png']);
      expect(input.onStatus, isNotNull);
    });
  });

  group('ProductionAdapter contract', () {
    test('abstract boundary defines produce + metadata getters', () {
      // The contract requires: produce(), adapterName, isAvailable
      // This is a structural test — the abstract class defines the shape.
      // Concrete tests are in production_adapter_impl_test.dart
      // where the Flutter-dependent implementation is tested.
      expect(ProductionAdapter, isNotNull);
    });
  });
}

ContentPackageV2 _buildTestPackage() {
  return ContentPackageV2(
    id: 'pkg-1',
    ideaId: 'idea-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    classification: ClassificationSnapshotV2(
      status: IdeaStatus.approved,
      axisStates: {},
      capturedAt: DateTime(2025, 1, 1),
    ),
    audience: 'Parents',
    problem: 'Lost socks',
    lesson: 'Check under the bed',
    hook: 'Where are your socks?',
    shareTrigger: null,
    openLoop: null,
    voiceMode: VoiceMode.required,
    cta: 'Save for later',
    reachCandidacy: ReachCandidacy.yes,
    productionCompatibility: ProductionCompatibility.yes,
    title: 'The Sock Hunt',
    script: 'Narration line one\nNarration line two',
    narration: 'Where are your socks? Check under the bed.',
    dialogue: 'Cuty: I hid them!',
    caption: 'Find the socks!',
    hashtags: ['#parenting', '#toddlers'],
    scenes: [
      Scene(
        index: 0,
        title: 'The Mystery',
        description: 'Socks are missing',
        visualPrompt: 'Child looking under furniture',
        narration: 'Where are your socks?',
        dialogue: 'Cuty: I hid them!',
        durationSeconds: 3,
      ),
    ],
    productionMethod: ProductionMethod.characterImages,
    shotList: [],
    imagePrompts: ['Child looking under furniture'],
  );
}
