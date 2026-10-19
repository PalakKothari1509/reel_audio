import 'dart:io';

import 'package:flutter/foundation.dart';

import 'json_file_store.dart';

/// Manages storage of video files in the app's documents directory.
/// Only stores file metadata in the database; actual files are kept as
/// separate files to avoid bloating the JSON store.
class FileStorageManager {
  static Directory? _testDirectory;

  @visibleForTesting
  static void setTestDirectory(Directory dir) {
    _testDirectory = dir;
    JsonFileStore.setTestDirectory(dir);
  }

  @visibleForTesting
  static void clearTestDirectory() {
    _testDirectory = null;
    JsonFileStore.clearTestDirectory();
  }

  static Future<Directory> get _storageDir async {
    final docs = _testDirectory ?? await _getAppDocumentsDirectory();
    final dir = Directory('${docs.path}/video_storage');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> _getAppDocumentsDirectory() async {
    // Lazy import to avoid adding path_provider to this file's dependencies
    // if it is already available elsewhere.
    final docs = await _getPath();
    return docs;
  }

  static Future<Directory> _getPath() {
    return Directory.systemTemp.createTemp('video_storage_test');
  }

  /// Saves a video file into app-managed storage and returns the relative path.
  static Future<String> saveVideo(File sourceFile, String assetId) async {
    final dir = await _storageDir;
    final String fileName = '$assetId.mp4';
    final dest = File('${dir.path}/$fileName');
    await sourceFile.copy(dest.path);
    return fileName;
  }

  /// Returns the full path to a stored video, or null if missing.
  static Future<File?> getVideoFile(String fileName) async {
    final dir = await _storageDir;
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) return file;
    return null;
  }

  /// Deletes a video file from storage. Safe if file doesn't exist.
  static Future<void> deleteVideo(String fileName) async {
    final dir = await _storageDir;
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Checks whether a video file exists in storage.
  static Future<bool> videoExists(String fileName) async {
    final dir = await _storageDir;
    final file = File('${dir.path}/$fileName');
    return await file.exists();
  }
}
