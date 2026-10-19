import 'dart:io';

import 'package:flutter/foundation.dart';

import 'json_file_store.dart';
import 'video_library.dart';

enum FindingSeverity {
  critical('Critical', 'Prevents safe or correct use.'),
  major('Major', 'Significantly damages the intended content.'),
  minor('Minor', 'Worthwhile improvement but not a blocker.'),
  suggestion('Suggestion', 'Optional creative enhancement.');

  final String label;
  final String description;
  const FindingSeverity(this.label, this.description);

  String get name => switch (this) {
        FindingSeverity.critical => 'critical',
        FindingSeverity.major => 'major',
        FindingSeverity.minor => 'minor',
        FindingSeverity.suggestion => 'suggestion',
      };

  static FindingSeverity fromName(String name) => switch (name) {
        'critical' => FindingSeverity.critical,
        'major' => FindingSeverity.major,
        'minor' => FindingSeverity.minor,
        'suggestion' => FindingSeverity.suggestion,
        _ => FindingSeverity.minor,
      };
}

class QualityFinding {
  final String id;
  final String checkId;
  final String checkName;
  final FindingSeverity severity;
  final bool passed;
  final String message;
  final String? suggestion;

  const QualityFinding({
    required this.id,
    required this.checkId,
    required this.checkName,
    required this.severity,
    required this.passed,
    required this.message,
    this.suggestion,
  });

  Map<String, dynamic> toJson() => {
          'id': id,
          'checkId': checkId,
          'checkName': checkName,
          'severity': severity.name,
          'passed': passed,
          'message': message,
          'suggestion': suggestion,
        };

  factory QualityFinding.fromJson(Map<String, dynamic> json) => QualityFinding(
        id: json['id'] as String? ?? '',
        checkId: json['checkId'] as String? ?? '',
        checkName: json['checkName'] as String? ?? '',
        severity: FindingSeverityExtension.fromName(
            json['severity'] as String? ?? 'minor'),
        passed: json['passed'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        suggestion: json['suggestion'] as String?,
      );
}

extension FindingSeverityExtension on FindingSeverity {
  static FindingSeverity fromName(String name) =>
      FindingSeverity.fromName(name);
}

enum QualityCheckType { script, prompt, video }

extension QualityCheckTypeExtension on QualityCheckType {
  String get name => switch (this) {
        QualityCheckType.script => 'script',
        QualityCheckType.prompt => 'prompt',
        QualityCheckType.video => 'video',
      };

  String get label => switch (this) {
        QualityCheckType.script => 'Script',
        QualityCheckType.prompt => 'Prompt',
        QualityCheckType.video => 'Video',
      };

  static QualityCheckType fromName(String name) => switch (name) {
        'script' => QualityCheckType.script,
        'prompt' => QualityCheckType.prompt,
        'video' => QualityCheckType.video,
        _ => QualityCheckType.script,
      };
}

class QualityReport2 {
  final String id;
  final String assetId;
  final QualityCheckType assetType;
  final int assetVersion;
  final DateTime checkedAt;
  final List<QualityFinding> findings;
  final String? manualNotes;
  final bool requiresHumanReview;

  QualityReport2({
    required this.id,
    required this.assetId,
    required this.assetType,
    required this.assetVersion,
    DateTime? checkedAt,
    List<QualityFinding>? findings,
    this.manualNotes,
    this.requiresHumanReview = false,
  })  : checkedAt = checkedAt ?? DateTime.now(),
        findings = findings ?? [];

  int get passCount => findings.where((f) => f.passed).length;
  int get criticalCount =>
      findings.where((f) => !f.passed && f.severity == FindingSeverity.critical).length;
  int get majorCount =>
      findings.where((f) => !f.passed && f.severity == FindingSeverity.major).length;
  int get minorCount =>
      findings.where((f) => !f.passed && f.severity == FindingSeverity.minor).length;
  int get suggestionCount =>
      findings.where((f) => !f.passed && f.severity == FindingSeverity.suggestion).length;

  bool get hasCriticalIssues => criticalCount > 0;
  bool get hasMajorIssues => majorCount > 0;

  /// Can this be approved for posting?
  bool get canApprove => !hasCriticalIssues && !hasMajorIssues;

  /// Overall status label.
  String get overallStatus {
    if (hasCriticalIssues) return 'FAIL';
    if (hasMajorIssues) return 'NEEDS REVISION';
    if (minorCount > 0 || suggestionCount > 0) return 'PASS WITH NOTES';
    return 'PASS';
  }

  Map<String, dynamic> toJson() => {
          'id': id,
          'assetId': assetId,
          'assetType': assetType.name,
          'assetVersion': assetVersion,
          'checkedAt': checkedAt.toIso8601String(),
          'findings': findings.map((f) => f.toJson()).toList(),
          'manualNotes': manualNotes,
          'requiresHumanReview': requiresHumanReview,
        };

  factory QualityReport2.fromJson(Map<String, dynamic> json) => QualityReport2(
        id: json['id'] as String? ?? '',
        assetId: json['assetId'] as String? ?? '',
        assetType: QualityCheckTypeExtension.fromName(
            json['assetType'] as String? ?? 'script'),
        assetVersion: (json['assetVersion'] as num?)?.toInt() ?? 1,
        checkedAt: DateTime.tryParse(json['checkedAt'] as String? ?? '') ??
            DateTime.now(),
        findings: (json['findings'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map((f) => QualityFinding.fromJson(
                    Map<String, dynamic>.from(f)))
                .toList() ??
            [],
        manualNotes: json['manualNotes'] as String?,
        requiresHumanReview:
            json['requiresHumanReview'] as bool? ?? false,
      );

  QualityReport2 copyWith({
    List<QualityFinding>? findings,
    String? manualNotes,
    bool? requiresHumanReview,
  }) {
    return QualityReport2(
      id: id,
      assetId: assetId,
      assetType: assetType,
      assetVersion: assetVersion,
      checkedAt: checkedAt,
      findings: findings ?? this.findings,
      manualNotes: manualNotes ?? this.manualNotes,
      requiresHumanReview:
          requiresHumanReview ?? this.requiresHumanReview,
    );
  }
}

class _QualityReportStore extends JsonFileStore<QualityReport2> {
  _QualityReportStore() : super('quality_reports.json');

  @override
  String idOf(QualityReport2 item) => item.id;

  @override
  QualityReport2 fromJson(Map<String, dynamic> json) =>
      QualityReport2.fromJson(json);

  @override
  Map<String, dynamic> toJson(QualityReport2 item) => item.toJson();
}

class QualityCheckCenter {
  static final _QualityReportStore _store = _QualityReportStore();

  @visibleForTesting
  static void useDirectory(Directory dir) =>
      JsonFileStore.setTestDirectory(dir);

  @visibleForTesting
  static void resetDirectory() => JsonFileStore.clearTestDirectory();

  static Future<List<QualityReport2>> getAll() async {
    final items = await _store.loadAll();
    items.sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
    return items;
  }

  static Future<List<QualityReport2>> getByAsset(String assetId) async {
    final all = await getAll();
    return all.where((r) => r.assetId == assetId).toList()
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
  }

  static Future<QualityReport2?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(QualityReport2 report) async {
    final all = await getAll();
    final existingIndex = all.indexWhere((r) => r.id == report.id);
    if (existingIndex != -1) {
      all[existingIndex] = report;
    } else {
      all.insert(0, report);
    }
    await _store.saveAll(all);
  }

  static Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((r) => r.id == id);
    await _store.saveAll(all);
  }

  // ── Script quality check ───────────────────────────────────────────────

  static QualityReport2 checkScript({
    required String contentId,
    required int version,
    required String title,
    required String scriptText,
  }) {
    final findings = <QualityFinding>[];
    final now = DateTime.now();

    // Check: real-life relevance
    final lower = scriptText.toLowerCase();
    final hasRealSituation = lower.contains('school') ||
        lower.contains('khana') ||
        lower.contains('shoes') ||
        lower.contains('phone') ||
        lower.contains('biscuit') ||
        lower.contains('tower') ||
        lower.contains('park');

    findings.add(QualityFinding(
      id: '${contentId}_script_$now',
      checkId: 'real_life_relevance',
      checkName: 'Real-Life Relevance',
      severity: hasRealSituation ? FindingSeverity.minor : FindingSeverity.major,
      passed: hasRealSituation,
      message: hasRealSituation
          ? 'The story reflects a relatable preschool situation.'
          : 'The story does not clearly reference a real-life situation.',
    ));

    // Check: age appropriateness
    final hasAgeInappropriate =
        lower.contains('scary') || lower.contains('fear') || lower.contains('nightmare');
    findings.add(QualityFinding(
      id: '${contentId}_script_age_$now',
      checkId: 'age_appropriateness',
      checkName: 'Age Appropriateness',
      severity: hasAgeInappropriate
          ? FindingSeverity.critical
          : FindingSeverity.minor,
      passed: !hasAgeInappropriate,
      message: hasAgeInappropriate
          ? 'The story contains potentially scary language for young children.'
          : 'The language is appropriate for children aged 1-4.',
    ));

    // Check: natural dialogue (Hinglish)
    final hasHinglish = lower.contains('hai') ||
        lower.contains('kya') ||
        lower.contains('kyun') ||
        lower.contains('par') ||
        lower.contains('aur');
    findings.add(QualityFinding(
      id: '${contentId}_script_lang_$now',
      checkId: 'natural_hinglish',
      checkName: 'Natural Hinglish Dialogue',
      severity: FindingSeverity.minor,
      passed: hasHinglish,
      message: hasHinglish
          ? 'Dialogue includes natural Hinglish phrasing.'
          : 'Dialogue may sound too English; consider adding Hinglish phrases.',
    ));

    // Check: clear resolution
    final hasResolution = lower.contains('resolution:') || lower.contains('moral:');
    findings.add(QualityFinding(
      id: '${contentId}_script_res_$now',
      checkId: 'clear_resolution',
      checkName: 'Clear Resolution',
      severity: hasResolution ? FindingSeverity.minor : FindingSeverity.major,
      passed: hasResolution,
      message: hasResolution
          ? 'The story includes a resolution and moral.'
          : 'The story lacks a clear resolution or moral.',
    ));

    return QualityReport2(
      id: '${contentId}_script_report_$now',
      assetId: contentId,
      assetType: QualityCheckType.script,
      assetVersion: version,
      findings: findings,
      requiresHumanReview: findings.any((f) => !f.passed),
    );
  }

  // ── Prompt quality check ───────────────────────────────────────────────

  static QualityReport2 checkPrompt({
    required String assetId,
    required int version,
    required String promptText,
    required List<String> expectedCharacters,
  }) {
    final findings = <QualityFinding>[];
    final now = DateTime.now();
    final lower = promptText.toLowerCase();

    // Check: characters present
    final missingChars = expectedCharacters.where((c) {
      final desc = _getCharacterDescription(c).toLowerCase();
      return !lower.contains(desc) && !lower.contains(c.toLowerCase());
    }).toList();

    findings.add(QualityFinding(
      id: '${assetId}_prompt_chars_$now',
      checkId: 'characters_present',
      checkName: 'Characters Present',
      severity: missingChars.isEmpty
          ? FindingSeverity.minor
          : FindingSeverity.critical,
      passed: missingChars.isEmpty,
      message: missingChars.isEmpty
          ? 'All expected characters are mentioned in the prompt.'
          : 'Missing character references: ${missingChars.join(', ')}',
      suggestion: missingChars.isNotEmpty
          ? 'Include exact descriptions for: ${missingChars.join(', ')}'
          : null,
    ));

    // Check: duration specified
    final hasDuration = lower.contains('10 second') || lower.contains('10-second');
    findings.add(QualityFinding(
      id: '${assetId}_prompt_dur_$now',
      checkId: 'duration_specified',
      checkName: 'Duration Specified',
      severity: hasDuration ? FindingSeverity.minor : FindingSeverity.major,
      passed: hasDuration,
      message: hasDuration
          ? 'The prompt specifies a 10-second duration.'
          : 'The prompt does not specify clip duration.',
    ));

    // Check: format specified
    final hasFormat = lower.contains('9:19') || lower.contains('vertical') || lower.contains('9:16');
    findings.add(QualityFinding(
      id: '${assetId}_prompt_fmt_$now',
      checkId: 'format_specified',
      checkName: 'Format Specified',
      severity: hasFormat ? FindingSeverity.minor : FindingSeverity.major,
      passed: hasFormat,
      message: hasFormat
          ? 'The prompt specifies vertical 9:16 format.'
          : 'The prompt does not specify the 9:16 aspect ratio.',
    ));

    // Check: negative instructions present
    final hasNegInstructions = lower.contains('negative') || lower.contains('no duplicate');
    findings.add(QualityFinding(
      id: '${assetId}_prompt_neg_$now',
      checkId: 'negative_instructions',
      checkName: 'Negative Instructions',
      severity: FindingSeverity.minor,
      passed: hasNegInstructions,
      message: hasNegInstructions
          ? 'Negative instructions are included.'
          : 'Consider adding negative instructions (no duplicates, etc.)',
    ));

    return QualityReport2(
      id: '${assetId}_prompt_report_$now',
      assetId: assetId,
      assetType: QualityCheckType.prompt,
      assetVersion: version,
      findings: findings,
      requiresHumanReview: findings.any((f) => !f.passed),
    );
  }

  // ── Video quality check ───────────────────────────────────────────────

  static Future<QualityReport2> checkVideo({
    required VideoAsset asset,
    String? filePath,
  }) async {
    final findings = <QualityFinding>[];
    final now = DateTime.now();

    // Technical checks
    if (filePath != null) {
      final file = File(filePath);
      final exists = await file.exists();
      findings.add(QualityFinding(
        id: '${asset.id}_video_readable_$now',
        checkId: 'file_readable',
        checkName: 'File Readable',
        severity: exists ? FindingSeverity.minor : FindingSeverity.critical,
        passed: exists,
        message: exists
            ? 'The video file is accessible.'
            : 'The video file could not be found at the expected path.',
      ));

      if (exists) {
        final size = await file.length();
        final sizeOk = size > 100000; // at least 100KB
        findings.add(QualityFinding(
          id: '${asset.id}_video_size_$now',
          checkId: 'file_size',
          checkName: 'File Size',
          severity: sizeOk ? FindingSeverity.minor : FindingSeverity.major,
          passed: sizeOk,
          message: sizeOk
              ? 'File size is reasonable (${(size / 1024 / 1024).toStringAsFixed(1)} MB).'
              : 'File size is unusually small (${(size / 1024).toStringAsFixed(1)} KB).',
        ));
      }
    } else {
      findings.add(QualityFinding(
        id: '${asset.id}_video_nofile_$now',
        checkId: 'file_available',
        checkName: 'File Available',
        severity: FindingSeverity.major,
        passed: false,
        message: 'No video file path available for technical checks.',
      ));
    }

    // Duration check
    if (asset.durationSeconds != null) {
      final durOk = asset.durationSeconds! >= 25 && asset.durationSeconds! <= 35;
      findings.add(QualityFinding(
        id: '${asset.id}_video_dur_$now',
        checkId: 'duration',
        checkName: 'Duration',
        severity: durOk ? FindingSeverity.minor : FindingSeverity.major,
        passed: durOk,
        message: durOk
            ? 'Duration is within 25-35s range (${asset.durationSeconds}s).'
            : 'Duration (${asset.durationSeconds}s) is outside the expected 25-35s range.',
      ));
    }

    // Aspect ratio check
    final aspectOk = asset.aspectRatio == '9:16';
    findings.add(QualityFinding(
      id: '${asset.id}_video_aspect_$now',
      checkId: 'aspect_ratio',
      checkName: 'Aspect Ratio',
      severity: aspectOk ? FindingSeverity.minor : FindingSeverity.major,
      passed: aspectOk,
      message: aspectOk
          ? 'Aspect ratio is 9:16.'
          : 'Aspect ratio is ${asset.aspectRatio}, expected 9:16.',
    ));

    return QualityReport2(
      id: '${asset.id}_video_report_$now',
      assetId: asset.id,
      assetType: QualityCheckType.video,
      assetVersion: asset.version,
      findings: findings,
      requiresHumanReview: findings.any((f) => !f.passed),
    );
  }

  static String _getCharacterDescription(String name) {
    // Simple lookup — in production, use characterDescription()
    return name;
  }
}
