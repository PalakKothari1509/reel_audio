// File-based implementation of PackageStore.
//
// Stores packages as JSON in a single file. Each entry has a metadata
// object and the package content. Pure Dart (uses dart:io, not Flutter),
// so it can run in tests and on the server.

import 'dart:convert';
import 'dart:io';

import 'package_store.dart';
import 'content_package_v2.dart';

/// A single stored entry: metadata + package.
class _StoreEntry {
  final PackageMetadata metadata;
  final ContentPackageV2 package;

  _StoreEntry(this.metadata, this.package);

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'package': package.toJson(),
      };

  factory _StoreEntry.fromJson(Map<String, dynamic> json) {
    return _StoreEntry(
      PackageMetadata.fromJson(Map<String, dynamic>.from(json['metadata'] as Map)),
      ContentPackageV2.fromJson(Map<String, dynamic>.from(json['package'] as Map)),
    );
  }
}

/// File-based [PackageStore] implementation.
///
/// Stores all packages in a single JSON file as a list of entries.
/// Each entry contains metadata + the package content.
class PackageStoreFile implements PackageStore {
  final String filePath;
  bool _ready = true;

  PackageStoreFile(this.filePath);

  @override
  String get storeName => 'PackageStoreFile';

  @override
  bool get isReady => _ready;

  Future<File> _file() async {
    final file = File(filePath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return file;
  }

  Future<List<_StoreEntry>> _readAll() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];

      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];

      final entries = <_StoreEntry>[];
      for (final item in raw) {
        try {
          if (item is! Map) continue;
          entries.add(_StoreEntry.fromJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          // Skip corrupted entries rather than failing the whole load.
          // This mirrors ContentLibraryStore's per-row resilience.
          _ready = false;
        }
      }
      return entries;
    } catch (e) {
      _ready = false;
      return [];
    }
  }

  Future<void> _writeAll(List<_StoreEntry> entries) async {
    final file = await _file();
    final data = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(data, flush: true);
  }

  @override
  Future<void> save(ContentPackageV2 package) async {
    final entries = await _readAll();
    final existingIndex = entries.indexWhere((e) => e.metadata.id == package.id);

    if (existingIndex != -1) {
      // Replace existing
      entries[existingIndex] = _StoreEntry(
        entries[existingIndex].metadata.copyWith(),
        package,
      );
    } else {
      // New entry
      entries.add(_StoreEntry(
        PackageMetadata(
          id: package.id,
          ideaId: package.ideaId,
          status: PackageStatus.generated,
          createdAt: package.createdAt,
          updatedAt: package.updatedAt,
        ),
        package,
      ));
    }

    await _writeAll(entries);
  }

  @override
  Future<StoreResult> trySave(ContentPackageV2 package) async {
    try {
      await save(package);
      return StoreResult.success(package.id);
    } catch (e) {
      return StoreResult.failure(StoreFailure('Save failed', e));
    }
  }

  @override
  Future<ContentPackageV2?> loadById(String id) async {
    final entries = await _readAll();
    for (final entry in entries) {
      if (entry.metadata.id == id) return entry.package;
    }
    return null;
  }

  @override
  Future<List<ContentPackageV2>> loadAll(PackageQuery query) async {
    final entries = await _readAll();
    var filtered = entries.where((e) {
      if (query.ideaId != null && e.metadata.ideaId != query.ideaId) {
        return false;
      }
      if (query.id != null && e.metadata.id != query.id) {
        return false;
      }
      if (query.status != null && e.metadata.status != query.status) {
        return false;
      }
      return true;
    });
    return filtered.map((e) => e.package).toList();
  }

  @override
  Future<List<ContentPackageV2>> loadAllPackages() {
    return loadAll(const PackageQuery());
  }

  @override
  Future<bool> delete(String id) async {
    final entries = await _readAll();
    final originalCount = entries.length;
    entries.removeWhere((e) => e.metadata.id == id);
    if (entries.length == originalCount) return false;
    await _writeAll(entries);
    return true;
  }

  @override
  Future<void> update(ContentPackageV2 package) async {
    final entries = await _readAll();
    final index = entries.indexWhere((e) => e.metadata.id == package.id);
    if (index == -1) {
      throw StoreFailure('Package not found: ${package.id}');
    }
    entries[index] = _StoreEntry(
      entries[index].metadata.copyWith(updatedAt: DateTime.now()),
      package,
    );
    await _writeAll(entries);
  }

  @override
  Future<void> updateStatus(String id, PackageStatus status) async {
    final entries = await _readAll();
    final index = entries.indexWhere((e) => e.metadata.id == id);
    if (index == -1) {
      throw StoreFailure('Package not found: $id');
    }
    entries[index] = _StoreEntry(
      entries[index].metadata.copyWith(status: status),
      entries[index].package,
    );
    await _writeAll(entries);
  }

  @override
  Future<int> count({PackageQuery? query}) async {
    final entries = await _readAll();
    if (query == null) return entries.length;
    return entries
        .where((e) {
          if (query.ideaId != null && e.metadata.ideaId != query.ideaId) {
            return false;
          }
          if (query.id != null && e.metadata.id != query.id) {
            return false;
          }
          if (query.status != null && e.metadata.status != query.status) {
            return false;
          }
          return true;
        })
        .length;
  }

  /// Gets metadata for a package, without loading the full package.
  Future<PackageMetadata?> loadMetadata(String id) async {
    final entries = await _readAll();
    for (final entry in entries) {
      if (entry.metadata.id == id) return entry.metadata;
    }
    return null;
  }
}
