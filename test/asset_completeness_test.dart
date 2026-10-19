import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/asset_completeness_service.dart';
import 'package:reel_audio/prompt_vault.dart';
import 'package:reel_audio/quality_check_center.dart';
import 'package:reel_audio/video_library.dart';
import 'package:reel_audio/video_library_store.dart';

void main() {
  group('AssetCompletenessService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asset_completeness_test');
      PromptVault.useDirectory(tempDir);
      VideoLibrary.useDirectory(tempDir);
      QualityCheckCenter.useDirectory(tempDir);
    });

    tearDown(() {
      PromptVault.resetDirectory();
      VideoLibrary.resetDirectory();
      QualityCheckCenter.resetDirectory();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('checkContentId returns all false when no assets exist', () async {
      final result = await AssetCompletenessService.checkContentId('h01');
      expect(result.contentId, 'h01');
      expect(result.hasScript, isFalse);
      expect(result.hasVideoPrompt, isFalse);
      expect(result.hasVideoAsset, isFalse);
      expect(result.hasQualityReport, isFalse);
      expect(result.isReadyToPost, isFalse);
    });

    test('checkContentId detects existing script prompt', () async {
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-test1',
        title: 'Test Script',
        type: PromptType.script,
        promptText: 'Some script content',
      );
      final result = await AssetCompletenessService.checkContentId('FLWP-test1');
      expect(result.hasScript, isTrue);
      expect(result.isReadyToPost, isFalse);
    });

    test('checkContentId detects existing video prompt', () async {
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-test2',
        title: 'Test Video Prompt',
        type: PromptType.video,
        promptText: 'Some video prompt content',
      );
      final result = await AssetCompletenessService.checkContentId('FLWP-test2');
      expect(result.hasVideoPrompt, isTrue);
    });

    test('checkContentId detects video asset and quality report together',
        () async {
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-test3',
        title: 'Script',
        type: PromptType.script,
        promptText: 'script',
      );
      await VideoLibrary.upload(
        contentId: 'FLWP-test3',
        title: 'My Video',
        fileName: 'FLWP-test3_v1.mp4',
        fileSizeBytes: 1024,
      );
      await QualityCheckCenter.save(QualityReport2(
        id: 'FLWP-test3_001',
        contentId: 'FLWP-test3',
        assetId: 'FLWP-test3_v1',
        assetType: QualityCheckType.video,
        assetVersion: 1,
        findings: [],
      ));

      final result = await AssetCompletenessService.checkContentId('FLWP-test3');
      expect(result.hasScript, isTrue);
      expect(result.hasVideoAsset, isTrue);
      expect(result.hasQualityReport, isTrue);
      expect(result.isReadyToPost, isTrue);
    });

    test('checkAll includes built-in ideas', () async {
      final results = await AssetCompletenessService.checkAll();
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.contentId, isNotEmpty);
        expect(r.title, isNotEmpty);
      }
    });

    test('getMissing returns only incomplete items', () async {
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-missing1',
        title: 'Only Script',
        type: PromptType.script,
        promptText: 'script',
      );
      final missing = await AssetCompletenessService.getMissing();
      expect(missing.any((m) => m.contentId == 'FLWP-missing1'), isTrue);
    });

    test('AssetCompleteness.isReadyToPost is false when missing video', () async {
      final completeness = AssetCompleteness(
        contentId: 'test',
        title: 'Test',
        hasScript: true,
        hasVideoPrompt: true,
        hasVideoAsset: false,
        hasQualityReport: true,
      );
      expect(completeness.isReadyToPost, isFalse);
    });

    test('AssetCompleteness.isReadyToPost is false when missing quality report',
        () async {
      final completeness = AssetCompleteness(
        contentId: 'test',
        title: 'Test',
        hasScript: true,
        hasVideoPrompt: true,
        hasVideoAsset: true,
        hasQualityReport: false,
      );
      expect(completeness.isReadyToPost, isFalse);
    });

    test('AssetCompleteness.copyWith updates fields', () async {
      final original = AssetCompleteness(
        contentId: 'test',
        title: 'Test',
        hasScript: false,
        hasVideoPrompt: false,
        hasVideoAsset: false,
        hasQualityReport: false,
      );
      final updated = original.copyWith(hasScript: true, hasVideoAsset: true);
      expect(updated.hasScript, isTrue);
      expect(updated.hasVideoAsset, isTrue);
      expect(updated.hasVideoPrompt, isFalse);
    });
  });
}
