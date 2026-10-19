import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/prompt_vault.dart';

void main() {
  group('PromptVault', () {
    setUp(() async {
      PromptVault.useDirectory(Directory.systemTemp);
      // Clean up any prompts from previous test runs
      final all = await PromptVault.getAll();
      for (final p in all) {
        await PromptVault.delete(p.id);
      }
    });

    tearDown(() {
      PromptVault.resetDirectory();
    });

    test('save and reload persists a SavedPrompt', () async {
      final prompt = SavedPrompt(
        id: 'test-1',
        contentId: 'FLWP-0001',
        title: 'Test Prompt',
        type: PromptType.video,
        promptText: 'This is a test video prompt',
        version: 1,
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 15),
      );

      await PromptVault.save(prompt);
      final loaded = await PromptVault.getById('test-1');

      expect(loaded, isNotNull);
      expect(loaded!.id, 'test-1');
      expect(loaded.contentId, 'FLWP-0001');
      expect(loaded.type, PromptType.video);
      expect(loaded.promptText, 'This is a test video prompt');
      expect(loaded.version, 1);
    });

    test('saveWithVersion creates incrementing versions', () async {
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-0002',
        title: 'Video Prompt',
        type: PromptType.video,
        promptText: 'First version',
      );
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-0002',
        title: 'Video Prompt',
        type: PromptType.video,
        promptText: 'Second version',
      );

      final all = await PromptVault.getByContentId('FLWP-0002');
      expect(all.length, 2);
      expect(all[0].version, 2);
      expect(all[1].version, 1);
    });

    test('getLatest returns highest version for type', () async {
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-0003',
        title: 'Script',
        type: PromptType.script,
        promptText: 'First draft',
      );
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-0003',
        title: 'Script',
        type: PromptType.script,
        promptText: 'Second draft',
      );

      final latest = await PromptVault.getLatest('FLWP-0003', PromptType.script);
      expect(latest, isNotNull);
      expect(latest!.version, 2);
      expect(latest.promptText, 'Second draft');
    });

    test('getByType filters by prompt type', () async {
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-0004',
        title: 'Video',
        type: PromptType.video,
        promptText: 'Video prompt',
      );
      await PromptVault.saveWithVersion(
        contentId: 'FLWP-0004',
        title: 'Image',
        type: PromptType.sceneImage,
        promptText: 'Image prompt',
      );

      final videos = await PromptVault.getByType(PromptType.video);
      expect(videos.length, 1);
      expect(videos.first.type, PromptType.video);
    });

    test('delete removes a prompt', () async {
      final prompt = SavedPrompt(
        id: 'to-delete',
        contentId: 'FLWP-0005',
        title: 'To Delete',
        type: PromptType.video,
        promptText: 'Delete me',
        version: 1,
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 15),
      );

      await PromptVault.save(prompt);
      expect((await PromptVault.getById('to-delete')), isNotNull);

      await PromptVault.delete('to-delete');
      expect((await PromptVault.getById('to-delete')), isNull);
    });

    test('PromptType names round-trip', () {
      expect(PromptType.video.name, 'video');
      expect(PromptType.sceneImage.name, 'scene_image');
      expect(PromptType.qualityCheck.name, 'quality_check');
      expect(PromptTypeExtension.fromName('video'), PromptType.video);
      expect(PromptTypeExtension.fromName('scene_image'), PromptType.sceneImage);
    });

    test('PromptStatus names round-trip', () {
      expect(PromptStatus.approved.name, 'approved');
      expect(PromptStatusExtension.fromName('approved'), PromptStatus.approved);
      expect(PromptStatusExtension.fromName('archived'), PromptStatus.archived);
    });
  });
}
