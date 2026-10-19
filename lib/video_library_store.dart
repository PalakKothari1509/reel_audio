import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'file_storage.dart';
import 'json_file_store.dart';
import 'video_library.dart';

class _VideoAssetStore extends JsonFileStore<VideoAsset> {
  _VideoAssetStore() : super('video_assets.json');

  @override
  String idOf(VideoAsset item) => item.id;

  @override
  VideoAsset fromJson(Map<String, dynamic> json) =>
      VideoAsset.fromJson(json);

  @override
  Map<String, dynamic> toJson(VideoAsset item) => item.toJson();
}

class VideoLibrary {
  static final _VideoAssetStore _store = _VideoAssetStore();

  @visibleForTesting
  static void useDirectory(Directory dir) => JsonFileStore.setTestDirectory(dir);

  @visibleForTesting
  static void resetDirectory() => JsonFileStore.clearTestDirectory();

  static Future<List<VideoAsset>> getAll() async {
    final items = await _store.loadAll();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  static Future<List<VideoAsset>> getByContentId(String contentId) async {
    final all = await getAll();
    return all.where((v) => v.contentId == contentId).toList()..sort(
        (a, b) => b.version.compareTo(a.version),
      );
  }

  static Future<List<VideoAsset>> getByStatus(VideoStatus status) async {
    final all = await getAll();
    return all.where((v) => v.status == status).toList();
  }

  static Future<VideoAsset?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<VideoAsset?> getApprovedForContent(String contentId) async {
    final all = await getByContentId(contentId);
    final approved = all.where((v) => v.status == VideoStatus.approved);
    if (approved.isEmpty) return null;
    return approved.reduce((a, b) => a.version >= b.version ? a : b);
  }

  static Future<VideoAsset> upload({
    required String contentId,
    required String title,
    required String fileName,
    required int fileSizeBytes,
    int? durationSeconds,
    String? resolution,
    String aspectRatio = '9:16',
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final existing = await getByContentId(contentId);
    final nextVersion = existing.isEmpty ? 1 : existing.first.version + 1;

    final asset = VideoAsset(
      id: '${contentId}_v$nextVersion',
      contentId: contentId,
      title: title,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      resolution: resolution,
      aspectRatio: aspectRatio,
      version: nextVersion,
      status: VideoStatus.uploaded,
      createdAt: now,
      updatedAt: now,
      uploadedAt: now,
      metadata: metadata ?? {},
    );

    final all = await getAll();
    all.insert(0, asset);
    await _store.saveAll(all);
    return asset;
  }

  static Future<VideoAsset?> pickAndUpload({
    required String contentId,
    required String title,
    String aspectRatio = '9:16',
    Map<String, dynamic>? metadata,
  }) async {
    final xFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (xFile == null) return null;

    final file = File(xFile.path);
    final size = await file.length();
    final storedName = await FileStorageManager.saveVideo(file, contentId);

    final all = await getAll();
    final existing = all.where((v) => v.contentId == contentId).toList();
    existing.sort((a, b) => b.version.compareTo(a.version));
    final nextVersion = existing.isEmpty ? 1 : existing.first.version + 1;

    final asset = VideoAsset(
      id: '${contentId}_v$nextVersion',
      contentId: contentId,
      title: title,
      fileName: storedName,
      fileSizeBytes: size,
      aspectRatio: aspectRatio,
      version: nextVersion,
      status: VideoStatus.uploaded,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      uploadedAt: DateTime.now(),
      metadata: metadata ?? {},
    );

    all.insert(0, asset);
    await _store.saveAll(all);
    return asset;
  }

  static Future<void> update(VideoAsset asset) async {
    final all = await getAll();
    final index = all.indexWhere((v) => v.id == asset.id);
    if (index != -1) {
      all[index] = asset;
      await _store.saveAll(all);
    }
  }

  static Future<void> updateStatus(String id, VideoStatus status) async {
    final asset = await getById(id);
    if (asset != null) {
      await update(asset.copyWith(status: status));
    }
  }

  static Future<void> approveVersion(String id) async {
    final asset = await getById(id);
    if (asset == null) return;
    final contentAssets = await getByContentId(asset.contentId);
    for (final a in contentAssets) {
      if (a.id == id) {
        await update(a.copyWith(
          status: VideoStatus.approved,
          approvedVersionId: null, // self-approved
        ));
      } else {
        await update(a.copyWith(
          approvedVersionId: id,
        ));
      }
    }
  }

  static Future<void> markPosted(String id) async {
    await updateStatus(id, VideoStatus.posted);
    final asset = await getById(id);
    if (asset != null) {
      await update(asset.copyWith(
        status: VideoStatus.posted,
        postedAt: DateTime.now(),
      ));
    }
  }

  static Future<void> delete(String id) async {
    final asset = await getById(id);
    if (asset != null) {
      await FileStorageManager.deleteVideo(asset.fileName);
    }
    final all = await getAll();
    all.removeWhere((v) => v.id == id);
    await _store.saveAll(all);
  }

  static Future<void> deleteByContentId(String contentId) async {
    final toDelete = await getByContentId(contentId);
    for (final asset in toDelete) {
      await FileStorageManager.deleteVideo(asset.fileName);
    }
    final all = await getAll();
    all.removeWhere((v) => v.contentId == contentId);
    await _store.saveAll(all);
  }
}
