import 'file_storage.dart';

enum VideoStatus { draft, uploaded, qualityChecked, approved, posted, archived }

extension VideoStatusExtension on VideoStatus {
  String get name => switch (this) {
        VideoStatus.draft => 'draft',
        VideoStatus.uploaded => 'uploaded',
        VideoStatus.qualityChecked => 'quality_checked',
        VideoStatus.approved => 'approved',
        VideoStatus.posted => 'posted',
        VideoStatus.archived => 'archived',
      };

  String get label => switch (this) {
        VideoStatus.draft => 'Draft',
        VideoStatus.uploaded => 'Uploaded',
        VideoStatus.qualityChecked => 'Quality Checked',
        VideoStatus.approved => 'Approved',
        VideoStatus.posted => 'Posted',
        VideoStatus.archived => 'Archived',
      };

  static VideoStatus fromName(String name) => switch (name) {
        'draft' => VideoStatus.draft,
        'uploaded' => VideoStatus.uploaded,
        'quality_checked' => VideoStatus.qualityChecked,
        'approved' => VideoStatus.approved,
        'posted' => VideoStatus.posted,
        'archived' => VideoStatus.archived,
        _ => VideoStatus.draft,
      };
}

class VideoAsset {
  final String id;
  final String contentId;
  final String title;
  final String fileName;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final String? resolution;
  final String aspectRatio;
  final int version;
  final VideoStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedVersionId;
  final String? qualityReportId;
  final DateTime? uploadedAt;
  final DateTime? postedAt;
  final String? notes;
  final Map<String, dynamic> metadata;

  VideoAsset({
    required this.id,
    required this.contentId,
    required this.title,
    required this.fileName,
    this.fileSizeBytes,
    this.durationSeconds,
    this.resolution,
    this.aspectRatio = '9:16',
    this.version = 1,
    this.status = VideoStatus.uploaded,
    required this.createdAt,
    required this.updatedAt,
    this.approvedVersionId,
    this.qualityReportId,
    this.uploadedAt,
    this.postedAt,
    this.notes,
    this.metadata = const {},
  });

  VideoAsset copyWith({
    VideoStatus? status,
    String? qualityReportId,
    DateTime? postedAt,
    String? notes,
    Map<String, dynamic>? metadata,
    String? approvedVersionId,
  }) {
    return VideoAsset(
      id: id,
      contentId: contentId,
      title: title,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      resolution: resolution,
      aspectRatio: aspectRatio,
      version: version,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      approvedVersionId: approvedVersionId ?? this.approvedVersionId,
      qualityReportId: qualityReportId ?? this.qualityReportId,
      uploadedAt: uploadedAt,
      postedAt: postedAt ?? this.postedAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
          'id': id,
          'contentId': contentId,
          'title': title,
          'fileName': fileName,
          'fileSizeBytes': fileSizeBytes,
          'durationSeconds': durationSeconds,
          'resolution': resolution,
          'aspectRatio': aspectRatio,
          'version': version,
          'status': status.name,
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': updatedAt.toIso8601String(),
          'approvedVersionId': approvedVersionId,
          'qualityReportId': qualityReportId,
          'uploadedAt': uploadedAt?.toIso8601String(),
          'postedAt': postedAt?.toIso8601String(),
          'notes': notes,
          'metadata': metadata,
        };

  factory VideoAsset.fromJson(Map<String, dynamic> json) => VideoAsset(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        title: json['title'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        resolution: json['resolution'] as String?,
        aspectRatio: json['aspectRatio'] as String? ?? '9:16',
        version: (json['version'] as num?)?.toInt() ?? 1,
        status:
            VideoStatusExtension.fromName(json['status'] as String? ?? 'uploaded'),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        approvedVersionId: json['approvedVersionId'] as String?,
        qualityReportId: json['qualityReportId'] as String?,
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'] as String)
            : null,
        postedAt: json['postedAt'] != null
            ? DateTime.tryParse(json['postedAt'] as String)
            : null,
        notes: json['notes'] as String?,
        metadata:
            (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
      );

  /// Checks whether the video file exists in storage.
  Future<bool> checkFileExists() => FileStorageManager.videoExists(fileName);
}
