import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'brand_system.dart';

enum IdeaStatus {
  captured,
  drafted,
  ready,
  posted,
  reused,
  archived,
}

enum IdeaSource {
  manual,
  voiceMemo,
  photoInspiration,
  conversation,
  observation,
  trendingTopic,
  aiSuggested,
}

class IdeaRecord {
  final String id;
  final String title;
  final String rawNote;
  final String? refinedIdea;
  final ContentBucket bucket;
  final ContentFormat? format;
  final IdeaStatus status;
  final IdeaSource source;
  final List<String> tags;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? postedAt;
  final String? generatedPackageId;
  final Map<String, dynamic> metadata;

  IdeaRecord({
    required this.id,
    required this.title,
    required this.rawNote,
    this.refinedIdea,
    required this.bucket,
    this.format,
    required this.status,
    required this.source,
    required this.tags,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.postedAt,
    this.generatedPackageId,
    required this.metadata,
  });

  bool get isCaptured => status == IdeaStatus.captured;
  bool get isDrafted => status == IdeaStatus.drafted;
  bool get isReady => status == IdeaStatus.ready;
  bool get isPosted => status == IdeaStatus.posted;
  bool get isReused => status == IdeaStatus.reused;
  bool get isArchived => status == IdeaStatus.archived;

  bool get canPromoteToDraft => status == IdeaStatus.captured;
  bool get canPromoteToReady => status == IdeaStatus.drafted;
  bool get canMarkPosted => status == IdeaStatus.ready;
  bool get canReuse => status == IdeaStatus.posted;
  bool get canArchive => status != IdeaStatus.archived;

  IdeaRecord copyWith({
    String? title,
    String? rawNote,
    String? refinedIdea,
    ContentBucket? bucket,
    ContentFormat? format,
    IdeaStatus? status,
    IdeaSource? source,
    List<String>? tags,
    int? priority,
    DateTime? updatedAt,
    DateTime? postedAt,
    String? generatedPackageId,
    Map<String, dynamic>? metadata,
  }) {
    return IdeaRecord(
      id: id,
      title: title ?? this.title,
      rawNote: rawNote ?? this.rawNote,
      refinedIdea: refinedIdea ?? this.refinedIdea,
      bucket: bucket ?? this.bucket,
      format: format ?? this.format,
      status: status ?? this.status,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      postedAt: postedAt ?? this.postedAt,
      generatedPackageId: generatedPackageId ?? this.generatedPackageId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'rawNote': rawNote,
        'refinedIdea': refinedIdea,
        'bucket': bucket.id,
        'format': format?.name,
        'status': status.name,
        'source': source.name,
        'tags': tags,
        'priority': priority,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'postedAt': postedAt?.toIso8601String(),
        'generatedPackageId': generatedPackageId,
        'metadata': metadata,
      };

  factory IdeaRecord.fromJson(Map<String, dynamic> json) {
    return IdeaRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      rawNote: json['rawNote'] as String,
      refinedIdea: json['refinedIdea'] as String?,
      bucket: BucketLibrary.byId(json['bucket'] as String? ?? '') ?? BucketLibrary.challenge,
      format: json['format'] != null ? ContentFormat.values.byName(json['format'] as String) : null,
      status: IdeaStatus.values.byName(json['status'] as String? ?? 'captured'),
      source: IdeaSource.values.byName(json['source'] as String? ?? 'manual'),
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      priority: json['priority'] as int? ?? 3,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      postedAt: json['postedAt'] != null ? DateTime.parse(json['postedAt'] as String) : null,
      generatedPackageId: json['generatedPackageId'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  static IdeaRecord create({
    required String title,
    required String rawNote,
    ContentBucket? bucket,
    ContentFormat? format,
    IdeaSource source = IdeaSource.manual,
    List<String> tags = const [],
    int priority = 3,
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return IdeaRecord(
      id: const Uuid().v4(),
      title: title,
      rawNote: rawNote,
      bucket: bucket ?? BucketLibrary.challenge,
      format: format,
      status: IdeaStatus.captured,
      source: source,
      tags: tags,
      priority: priority.clamp(1, 5),
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
  }
}

class IdeaInboxStore {
  static const String _fileName = 'idea_inbox.json';

  static Future<File> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<IdeaRecord>> getAll() async {
    try {
      final file = await _path();
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(IdeaRecord.fromJson).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<List<IdeaRecord>> getByStatus(IdeaStatus status) async {
    final all = await getAll();
    return all.where((i) => i.status == status).toList();
  }

  static Future<List<IdeaRecord>> getByBucket(ContentBucket bucket) async {
    final all = await getAll();
    return all.where((i) => i.bucket == bucket).toList();
  }

  static Future<IdeaRecord?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> add(IdeaRecord idea) async {
    final list = await getAll();
    list.insert(0, idea);
    await _saveAll(list);
  }

  static Future<void> update(IdeaRecord idea) async {
    final list = await getAll();
    final index = list.indexWhere((i) => i.id == idea.id);
    if (index != -1) {
      list[index] = idea.copyWith(updatedAt: DateTime.now());
      await _saveAll(list);
    }
  }

  static Future<void> delete(String id) async {
    final list = await getAll();
    list.removeWhere((i) => i.id == id);
    await _saveAll(list);
  }

  static Future<void> _saveAll(List<IdeaRecord> list) async {
    try {
      final file = await _path();
      await file.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> promoteToDraft(String id, {String? refinedIdea, ContentBucket? bucket, ContentFormat? format}) async {
    final idea = await getById(id);
    if (idea != null && idea.canPromoteToDraft) {
      await update(idea.copyWith(
        status: IdeaStatus.drafted,
        refinedIdea: refinedIdea ?? idea.refinedIdea,
        bucket: bucket ?? idea.bucket,
        format: format ?? idea.format,
      ));
    }
  }

  static Future<void> promoteToReady(String id, {String? generatedPackageId}) async {
    final idea = await getById(id);
    if (idea != null && idea.canPromoteToReady) {
      await update(idea.copyWith(
        status: IdeaStatus.ready,
        generatedPackageId: generatedPackageId ?? idea.generatedPackageId,
      ));
    }
  }

  static Future<void> markPosted(String id) async {
    final idea = await getById(id);
    if (idea != null && idea.canMarkPosted) {
      await update(idea.copyWith(
        status: IdeaStatus.posted,
        postedAt: DateTime.now(),
      ));
    }
  }

  static Future<void> markReused(String id) async {
    final idea = await getById(id);
    if (idea != null && idea.canReuse) {
      await update(idea.copyWith(
        status: IdeaStatus.reused,
      ));
    }
  }

  static Future<void> archive(String id) async {
    final idea = await getById(id);
    if (idea != null && idea.canArchive) {
      await update(idea.copyWith(
        status: IdeaStatus.archived,
      ));
    }
  }

  static Future<int> getCountByStatus(IdeaStatus status) async {
    final all = await getAll();
    return all.where((i) => i.status == status).length;
  }

  static Future<Map<IdeaStatus, int>> getStatusCounts() async {
    final all = await getAll();
    final counts = <IdeaStatus, int>{};
    for (final status in IdeaStatus.values) {
      counts[status] = all.where((i) => i.status == status).length;
    }
    return counts;
  }
}