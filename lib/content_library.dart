import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'brand_system.dart';
import 'content_generator.dart';
import 'format_adapter.dart';
import 'quality_check.dart';

enum ContentStatus {
  idea,
  draft,
  ready,
  posted,
  reused,
  archived,
}

class ContentLibraryItem {
  final String id;
  final String title;
  final String topic;
  final ContentBucket bucket;
  final ContentFormat format;
  final ContentStatus status;
  final ContentPackage? contentPackage;
  final Map<ContentFormat, FormatOutput> formatOutputs;
  final QualityReport? qualityReport;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? postedAt;
  final String? instagramPostUrl;
  final Map<String, dynamic> performanceMetrics;
  final int reuseCount;
  final String? sourceIdeaId;

  ContentLibraryItem({
    required this.id,
    required this.title,
    required this.topic,
    required this.bucket,
    required this.format,
    required this.status,
    this.contentPackage,
    required this.formatOutputs,
    this.qualityReport,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.postedAt,
    this.instagramPostUrl,
    required this.performanceMetrics,
    required this.reuseCount,
    this.sourceIdeaId,
  });

  ContentLibraryItem copyWith({
    String? title,
    String? topic,
    ContentBucket? bucket,
    ContentFormat? format,
    ContentStatus? status,
    ContentPackage? contentPackage,
    Map<ContentFormat, FormatOutput>? formatOutputs,
    QualityReport? qualityReport,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? postedAt,
    String? instagramPostUrl,
    Map<String, dynamic>? performanceMetrics,
    int? reuseCount,
  }) {
    return ContentLibraryItem(
      id: id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      bucket: bucket ?? this.bucket,
      format: format ?? this.format,
      status: status ?? this.status,
      contentPackage: contentPackage ?? this.contentPackage,
      formatOutputs: formatOutputs ?? this.formatOutputs,
      qualityReport: qualityReport ?? this.qualityReport,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      postedAt: postedAt ?? this.postedAt,
      instagramPostUrl: instagramPostUrl ?? this.instagramPostUrl,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      reuseCount: reuseCount ?? this.reuseCount,
      sourceIdeaId: sourceIdeaId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'bucket': bucket.id,
        'format': format.name,
        'status': status.name,
        'contentPackage': contentPackage?.toJson(),
        'formatOutputs': formatOutputs.map((k, v) => MapEntry(k.name, v.toJson())),
        'qualityReport': qualityReport != null ? {
          'passCount': qualityReport!.passCount,
          'warnCount': qualityReport!.warnCount,
          'failCount': qualityReport!.failCount,
          'score': qualityReport!.score,
          'isReadyToPost': qualityReport!.isReadyToPost,
          'results': qualityReport!.results.map((r) => {
            'ruleId': r.rule.id,
            'ruleName': r.rule.name,
            'passed': r.passed,
            'severity': r.severity.index,
            'message': r.message,
            'details': r.details,
          }).toList(),
          'checkedAt': qualityReport!.checkedAt.toIso8601String(),
        } : null,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'postedAt': postedAt?.toIso8601String(),
        'instagramPostUrl': instagramPostUrl,
        'performanceMetrics': performanceMetrics,
        'reuseCount': reuseCount,
        'sourceIdeaId': sourceIdeaId,
      };

  factory ContentLibraryItem.fromJson(Map<String, dynamic> json) {
    // Read into locals first. The quality report used to be rebuilt inline, and it
    // needs this item's own package and formats to exist — which an inline
    // constructor argument list cannot see. It also read
    // `qualityReport['package']` and `['formats']`, keys `toJson` never wrote, so
    // every item that had a report threw on reload and `getAll` turned that into an
    // empty library.
    final package = json['contentPackage'] != null
        ? ContentPackage.fromJson(Map<String, dynamic>.from(json['contentPackage']))
        : null;
    final formats = (json['formatOutputs'] as Map?)?.map((k, v) => MapEntry(
          ContentFormat.values.byName(k as String),
          FormatOutput.fromJson(Map<String, dynamic>.from(v as Map)),
        )) ??
        <ContentFormat, FormatOutput>{};

    return ContentLibraryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      topic: json['topic'] as String,
      bucket: BucketLibrary.byId(json['bucket'] as String? ?? '') ?? BucketLibrary.challenge,
      format: ContentFormat.values.byName(json['format'] as String? ?? 'carousel'),
      status: ContentStatus.values.byName(json['status'] as String? ?? 'idea'),
      contentPackage: package,
      formatOutputs: formats,
      qualityReport: _reportFromJson(json['qualityReport'], package, formats),
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      postedAt: json['postedAt'] != null ? DateTime.parse(json['postedAt'] as String) : null,
      instagramPostUrl: json['instagramPostUrl'] as String?,
      performanceMetrics: (json['performanceMetrics'] as Map?)?.cast<String, dynamic>() ?? {},
      reuseCount: json['reuseCount'] as int? ?? 0,
      sourceIdeaId: json['sourceIdeaId'] as String?,
    );
  }

  /// Rebuilds a [QualityReport] from what was saved, reusing this item's package and
  /// formats rather than saving them twice.
  ///
  /// Returns null rather than throwing when the saved report cannot be read. A report
  /// is a cache of a judgement, not the content itself, so the cheapest correct
  /// behaviour on a damaged report is to drop it and let the checker run again. What
  /// it must not do is take the whole library down with it.
  static QualityReport? _reportFromJson(
    Object? raw,
    ContentPackage? package,
    Map<ContentFormat, FormatOutput> formats,
  ) {
    if (raw is! Map || package == null) return null;
    final j = Map<String, dynamic>.from(raw);
    final results = (j['results'] as List?) ?? const [];
    return QualityReport(
      package: package,
      formats: formats,
      results: results.whereType<Map>().map((r) {
        final m = Map<String, dynamic>.from(r);
        return QualityResult(
          rule: QualityRule(
            id: m['ruleId'] as String? ?? '',
            name: m['ruleName'] as String? ?? '',
            description: m['details'] as String? ?? '',
            severity: QualitySeverity.values[(m['severity'] as num?)?.toInt() ?? 0],
            check: (_, _) => true,
            fixSuggestion: (_) => m['details'] as String?,
          ),
          passed: m['passed'] as bool? ?? false,
          message: m['message'] as String? ?? '',
          details: m['details'] as String?,
        );
      }).toList(),
      checkedAt: DateTime.tryParse(j['checkedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static ContentLibraryItem createFromPackage(ContentPackage pkg, {String? sourceIdeaId}) {
    final formats = FormatAdapter.adaptAll(pkg);
    return ContentLibraryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: pkg.hook.isNotEmpty ? pkg.hook : pkg.idea,
      topic: pkg.idea,
      bucket: pkg.bucket,
      format: pkg.format,
      status: ContentStatus.draft,
      contentPackage: pkg,
      formatOutputs: formats,
      tags: [pkg.bucket.id],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      performanceMetrics: {},
      reuseCount: 0,
      sourceIdeaId: sourceIdeaId,
    );
  }
}

class ContentLibraryStore {
  static const String _fileName = 'content_library.json';

  static Future<File> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Loads every saved item.
  ///
  /// Each row is decoded on its own so one damaged entry costs you that entry rather
  /// than the whole library. It used to decode inside a single try around the entire
  /// file, so a single unreadable row returned `[]` — the failure was invisible and it
  /// looked exactly like having never saved anything.
  static Future<List<ContentLibraryItem>> getAll() async {
    try {
      final file = await _path();
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];

      final items = <ContentLibraryItem>[];
      for (final row in raw) {
        if (row is! Map) continue;
        try {
          items.add(ContentLibraryItem.fromJson(Map<String, dynamic>.from(row)));
        } catch (e) {
          debugPrint('ContentLibrary: skipped one unreadable item — $e');
        }
      }
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } catch (e) {
      debugPrint('ContentLibrary: could not read the library file — $e');
      return [];
    }
  }

  static Future<List<ContentLibraryItem>> getByStatus(ContentStatus status) async {
    final all = await getAll();
    return all.where((i) => i.status == status).toList();
  }

  static Future<List<ContentLibraryItem>> getByBucket(ContentBucket bucket) async {
    final all = await getAll();
    return all.where((i) => i.bucket == bucket).toList();
  }

  static Future<List<ContentLibraryItem>> getByFormat(ContentFormat format) async {
    final all = await getAll();
    return all.where((i) => i.format == format).toList();
  }

  static Future<ContentLibraryItem?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> add(ContentLibraryItem item) async {
    final list = await getAll();
    list.insert(0, item);
    await _saveAll(list);
  }

  static Future<void> update(ContentLibraryItem item) async {
    final list = await getAll();
    final index = list.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      list[index] = item.copyWith(updatedAt: DateTime.now());
      await _saveAll(list);
    }
  }

  static Future<void> delete(String id) async {
    final list = await getAll();
    list.removeWhere((i) => i.id == id);
    await _saveAll(list);
  }

  static Future<void> _saveAll(List<ContentLibraryItem> list) async {
    try {
      final file = await _path();
      await file.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> updateStatus(String id, ContentStatus newStatus, {DateTime? postedAt, String? instagramUrl}) async {
    final item = await getById(id);
    if (item != null) {
      await update(item.copyWith(
        status: newStatus,
        postedAt: postedAt ?? (newStatus == ContentStatus.posted ? DateTime.now() : item.postedAt),
        instagramPostUrl: instagramUrl ?? item.instagramPostUrl,
      ));
    }
  }

  static Future<void> markReused(String id) async {
    final item = await getById(id);
    if (item != null) {
      await update(item.copyWith(
        status: ContentStatus.reused,
        reuseCount: item.reuseCount + 1,
      ));
    }
  }

  static Future<void> updateQualityReport(String id, QualityReport report) async {
    final item = await getById(id);
    if (item != null) {
      await update(item.copyWith(qualityReport: report));
    }
  }

  static Future<Map<ContentStatus, int>> getStatusCounts() async {
    final all = await getAll();
    final counts = <ContentStatus, int>{};
    for (final status in ContentStatus.values) {
      counts[status] = all.where((i) => i.status == status).length;
    }
    return counts;
  }

  static Future<Map<ContentBucket, int>> getBucketCounts() async {
    final all = await getAll();
    final counts = <ContentBucket, int>{};
    for (final bucket in BucketLibrary.all) {
      counts[bucket] = all.where((i) => i.bucket == bucket).length;
    }
    return counts;
  }
}