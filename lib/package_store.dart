// Package storage boundary layer.
//
// Stores and retrieves ContentPackageV2 objects. The boundary is pure Dart
// so it can be tested without Flutter. The file-based implementation lives
// in package_store_impl.dart.
//
// This is the storage layer that sits between ProductionAdapter (which
// produces media) and the UI (which needs to recall saved packages).

import 'content_package_v2.dart';

/// Filters available for querying package stores.
class PackageQuery {
  final String? ideaId;
  final String? id;
  final PackageStatus? status;

  const PackageQuery({this.ideaId, this.id, this.status});

  /// Sentinel to distinguish "no value passed" from "pass null to clear".
  static const Object _unset = Object();

  PackageQuery copyWith({
    Object? ideaId = _unset,
    Object? id = _unset,
    Object? status = _unset,
  }) {
    return PackageQuery(
      ideaId: ideaId == _unset ? this.ideaId : ideaId as String?,
      id: id == _unset ? this.id : id as String?,
      status: status == _unset ? this.status : status as PackageStatus?,
    );
  }
}

/// Status of a package in the production pipeline.
enum PackageStatus {
  generated('Generated'),
  voiceReady('Voice Ready'),
  imagesReady('Images Ready'),
  videoBuilt('Video Built'),
  posted('Posted'),
  archived('Archived');

  final String label;
  const PackageStatus(this.label);
}

/// Storage result with success/failure info.
class StoreResult {
  final bool isSuccess;
  final String? packageId;
  final String? message;
  final StoreFailure? error;

  const StoreResult._({
    required this.isSuccess,
    this.packageId,
    this.message,
    this.error,
  });

  static StoreResult success(String id) => StoreResult._(
        isSuccess: true,
        packageId: id,
      );

  static StoreResult failure(StoreFailure failure) => StoreResult._(
        isSuccess: false,
        error: failure,
      );

  static StoreResult info(String msg) => StoreResult._(
        isSuccess: true,
        message: msg,
      );
}

/// Exception for storage failures.
class StoreFailure implements Exception {
  final String message;
  final Object? cause;

  const StoreFailure(this.message, [this.cause]);

  @override
  String toString() => 'StoreFailure: $message';
}

/// Abstract boundary for package persistence.
///
/// Screens depend on this interface. The concrete implementation (file-based)
/// is injected at runtime. This is the V2 equivalent of ContentLibraryStore,
/// but designed for the new pipeline architecture.
abstract class PackageStore {
  /// Saves a package. If a package with the same ID exists, it is replaced.
  ///
  /// Throws [StoreFailure] on write errors.
  Future<void> save(ContentPackageV2 package);

  /// Saves a package and returns a result (success or failure).
  ///
  /// Like [save] but never throws — suitable for UI paths.
  Future<StoreResult> trySave(ContentPackageV2 package);

  /// Loads a single package by ID. Returns null if not found.
  Future<ContentPackageV2?> loadById(String id);

  /// Loads all packages matching the given query.
  Future<List<ContentPackageV2>> loadAll(PackageQuery query);

  /// Loads all packages (no filter).
  Future<List<ContentPackageV2>> loadAllPackages();

  /// Deletes a package by ID. Returns true if deleted, false if not found.
  Future<bool> delete(String id);

  /// Updates an existing package. Throws [StoreFailure] if not found.
  Future<void> update(ContentPackageV2 package);

  /// Updates the status of a package without rewriting the whole thing.
  Future<void> updateStatus(String id, PackageStatus status);

  /// Number of packages in the store (optionally filtered).
  Future<int> count({PackageQuery? query});

  /// Whether the store is ready for use.
  bool get isReady;

  /// Human-readable name for this store.
  String get storeName;
}

/// Metadata stored alongside each package — tracks production status
/// without modifying ContentPackageV2 itself.
class PackageMetadata {
  final String id;
  final String ideaId;
  final PackageStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? videoPath;
  final String? audioPath;
  final List<String> imagePaths;

  PackageMetadata({
    required this.id,
    required this.ideaId,
    this.status = PackageStatus.generated,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.videoPath,
    this.audioPath,
    this.imagePaths = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  PackageMetadata copyWith({
    PackageStatus? status,
    String? videoPath,
    String? audioPath,
    List<String>? imagePaths,
    DateTime? updatedAt,
  }) {
    return PackageMetadata(
      id: id,
      ideaId: ideaId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      videoPath: videoPath ?? this.videoPath,
      audioPath: audioPath ?? this.audioPath,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ideaId': ideaId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'videoPath': videoPath,
        'audioPath': audioPath,
        'imagePaths': imagePaths,
      };

  factory PackageMetadata.fromJson(Map<String, dynamic> json) => PackageMetadata(
        id: json['id'] as String? ?? '',
        ideaId: json['ideaId'] as String? ?? '',
        status: PackageStatus.values.byName(
            json['status'] as String? ?? 'generated'),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        videoPath: json['videoPath'] as String?,
        audioPath: json['audioPath'] as String?,
        imagePaths:
            (json['imagePaths'] as List?)?.cast<String>() ?? const [],
      );
}
