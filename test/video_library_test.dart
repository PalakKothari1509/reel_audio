import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/video_library.dart';
import 'package:reel_audio/video_library_store.dart';

void main() {
  group('VideoLibrary', () {
    setUp(() async {
      VideoLibrary.useDirectory(Directory.systemTemp);
      final all = await VideoLibrary.getAll();
      for (final v in all) {
        await VideoLibrary.delete(v.id);
      }
    });

    tearDown(() {
      VideoLibrary.resetDirectory();
    });

    test('upload and getById persists a video asset', () async {
      final asset = await VideoLibrary.upload(
        contentId: 'FLWP-0001',
        title: 'Main Khud Karungi - v1',
        fileName: 'FLWP-0001_v1.mp4',
        fileSizeBytes: 1024000,
        durationSeconds: 30,
        resolution: '1080x1920',
      );

      final loaded = await VideoLibrary.getById(asset.id);
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Main Khud Karungi - v1');
      expect(loaded.contentId, 'FLWP-0001');
      expect(loaded.fileSizeBytes, 1024000);
      expect(loaded.durationSeconds, 30);
      expect(loaded.version, 1);
      expect(loaded.status, VideoStatus.uploaded);
    });

    test('upload creates incrementing versions for same content', () async {
      await VideoLibrary.upload(
        contentId: 'FLWP-0002',
        title: 'Video v1',
        fileName: 'file1.mp4',
        fileSizeBytes: 100,
      );
      await VideoLibrary.upload(
        contentId: 'FLWP-0002',
        title: 'Video v2',
        fileName: 'file2.mp4',
        fileSizeBytes: 200,
      );

      final assets = await VideoLibrary.getByContentId('FLWP-0002');
      expect(assets.length, 2);
      expect(assets.first.version, 2);
      expect(assets.last.version, 1);
    });

    test('updateStatus changes the video status', () async {
      final asset = await VideoLibrary.upload(
        contentId: 'FLWP-0003',
        title: 'Test',
        fileName: 'test.mp4',
        fileSizeBytes: 100,
      );

      await VideoLibrary.updateStatus(asset.id, VideoStatus.approved);
      final updated = await VideoLibrary.getById(asset.id);
      expect(updated!.status, VideoStatus.approved);
    });

    test('getByStatus filters by status', () async {
      final a1 = await VideoLibrary.upload(
        contentId: 'FLWP-0004',
        title: 'Approved video',
        fileName: 'approved.mp4',
        fileSizeBytes: 100,
      );
      final a2 = await VideoLibrary.upload(
        contentId: 'FLWP-0005',
        title: 'Posted video',
        fileName: 'posted.mp4',
        fileSizeBytes: 100,
      );

      await VideoLibrary.updateStatus(a1.id, VideoStatus.approved);
      await VideoLibrary.updateStatus(a2.id, VideoStatus.posted);

      final approved = await VideoLibrary.getByStatus(VideoStatus.approved);
      final posted = await VideoLibrary.getByStatus(VideoStatus.posted);

      expect(approved.length, 1);
      expect(approved.first.id, a1.id);
      expect(posted.length, 1);
      expect(posted.first.id, a2.id);
    });

    test('delete removes the video asset', () async {
      final asset = await VideoLibrary.upload(
        contentId: 'FLWP-0006',
        title: 'To Delete',
        fileName: 'delete.mp4',
        fileSizeBytes: 100,
      );

      expect(await VideoLibrary.getById(asset.id), isNotNull);
      await VideoLibrary.delete(asset.id);
      expect(await VideoLibrary.getById(asset.id), isNull);
    });

    test('VideoStatus enum round-trips', () {
      expect(VideoStatus.approved.name, 'approved');
      expect(VideoStatus.qualityChecked.name, 'quality_checked');
      expect(VideoStatusExtension.fromName('approved'), VideoStatus.approved);
      expect(VideoStatusExtension.fromName('posted'), VideoStatus.posted);
      expect(VideoStatus.approved.label, 'Approved');
    });
  });
}
