// Generic JSON file storage base class.
//
// Consolidates the ~450 lines of near-identical storage code across 6+ store
// classes into a single, testable abstraction. Each store class extends this
// to get consistent file-path resolution, error handling, and load/save logic.
//
// Usage:
//
//   class MyStore extends JsonFileStore<MyItem> {
//     MyStore() : super('my_items.json');
//
//     @override
//     MyItem fromJson(Map<String, dynamic> json) => MyItem.fromJson(json);
//
//     @override
//     Map<String, dynamic> toJson(MyItem item) => item.toJson();
//   }
//
// Test seam: set [JsonFileStore.testDirectory] to a temp Directory before
// any store operations. Production code should not set this — it is only for
// tests that cannot access getApplicationDocumentsDirectory.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Base class for JSON file-based stores.
///
/// Each subclass provides the file name, plus encode/decode methods for its
/// item type. The base class handles path resolution (with a test seam),
/// file I/O, JSON parsing, and consistent error handling.
abstract class JsonFileStore<T> {
  final String fileName;

  /// The directory override for tests. When set, all path resolution uses
  /// this directory instead of the app's documents directory.
  static Directory? _testDirectory;

  @visibleForTesting
  static void setTestDirectory(Directory dir) => _testDirectory = dir;

  @visibleForTesting
  static void clearTestDirectory() => _testDirectory = null;

  JsonFileStore(this.fileName);

  /// Creates the file path, creating the directory if needed.
  Future<File> _file() async {
    final dir = _testDirectory ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  /// Reads and decodes the JSON file, returning the raw list.
  ///
  /// Returns an empty list if the file does not exist or is unreadable.
  /// Per-row decoding happens in [decodeAll], not here, so a single corrupted
  /// entry does not lose the whole file.
  Future<List<dynamic>> _readRaw() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final raw = jsonDecode(content);
    if (raw is! List) return [];
    return raw;
  }

  /// Decodes each row independently, skipping any that fail.
  ///
  /// Override [fromJson] to define how each row becomes [T].
  /// Override [shouldKeep] to add filtering (e.g., drop empty entries).
  Future<List<T>> loadAll({bool Function(T item)? shouldKeep}) async {
    try {
      final raw = await _readRaw();
      final items = <T>[];
      for (final row in raw) {
        if (row is! Map<String, dynamic>) continue;
        try {
          items.add(fromJson(row));
        } on Exception catch (e) {
          debugPrint('JsonFileStore<$T>: skipped one unreadable item in $fileName â $e');
        }
      }
      if (shouldKeep != null) {
        items.retainWhere(shouldKeep);
      }
      return items;
    } on Exception catch (e) {
      debugPrint('JsonFileStore<$T>: could not read $fileName â $e');
      return [];
    }
  }

  /// Writes all items, replacing the file contents.
  ///
  /// Throws [StoreFailure] on write error — callers must handle.
  Future<void> saveAll(List<T> items) async {
    final file = await _file();
    final data = jsonEncode(items.map((item) => toJson(item)).toList());
    await file.writeAsString(data, flush: true);
  }

  /// Convenience: add one item to the front of the list and save.
  Future<void> add(T item) async {
    final items = await loadAll();
    items.insert(0, item);
    try {
      await saveAll(items);
    } on Exception catch (e) {
      debugPrint('JsonFileStore<$T>: add failed â $e');
    }
  }

  /// Loads a single item by ID. Returns null if not found.
  Future<T?> loadById(String id) async {
    final items = await loadAll();
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  /// Convenience: remove an item by ID (string field), then save.
  ///
  /// Override [idOf] to specify which field identifies an item.
  Future<void> deleteById(String id) async {
    final items = await loadAll();
    items.removeWhere((item) => idOf(item) == id);
    await saveAll(items);
  }

  /// Returns the ID string of [item], used by [deleteById].
  String idOf(T item);

  /// Decodes one JSON map into [T].
  T fromJson(Map<String, dynamic> json);

  /// Encodes [item] into a JSON map.
  Map<String, dynamic> toJson(T item);
}

/// Exception for storage failures.
class StoreFailure implements Exception {
  final String message;
  final Object? cause;

  const StoreFailure(this.message, [this.cause]);

  @override
  String toString() => 'StoreFailure: $message';
}
