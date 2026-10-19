import 'dart:io';

import 'package:flutter/foundation.dart';

import 'json_file_store.dart';

enum PromptType {
  story,
  script,
  character,
  sceneImage,
  video,
  voice,
  caption,
  qualityCheck,
  custom,
}

extension PromptTypeExtension on PromptType {
  String get name => switch (this) {
        PromptType.story => 'story',
        PromptType.script => 'script',
        PromptType.character => 'character',
        PromptType.sceneImage => 'scene_image',
        PromptType.video => 'video',
        PromptType.voice => 'voice',
        PromptType.caption => 'caption',
        PromptType.qualityCheck => 'quality_check',
        PromptType.custom => 'custom',
      };

  static PromptType fromName(String name) => switch (name) {
        'story' => PromptType.story,
        'script' => PromptType.script,
        'character' => PromptType.character,
        'scene_image' => PromptType.sceneImage,
        'video' => PromptType.video,
        'voice' => PromptType.voice,
        'caption' => PromptType.caption,
        'quality_check' => PromptType.qualityCheck,
        'custom' => PromptType.custom,
        _ => PromptType.custom,
      };
}

enum PromptStatus { draft, saved, approved, archived }

extension PromptStatusExtension on PromptStatus {
  String get name => switch (this) {
        PromptStatus.draft => 'draft',
        PromptStatus.saved => 'saved',
        PromptStatus.approved => 'approved',
        PromptStatus.archived => 'archived',
      };

  static PromptStatus fromName(String name) => switch (name) {
        'draft' => PromptStatus.draft,
        'saved' => PromptStatus.saved,
        'approved' => PromptStatus.approved,
        'archived' => PromptStatus.archived,
        _ => PromptStatus.saved,
      };
}

class SavedPrompt {
  final String id;
  final String contentId;
  final String title;
  final PromptType type;
  final String promptText;
  final int version;
  final PromptStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sourceScriptVersion;
  final Map<String, dynamic> metadata;

  SavedPrompt({
    required this.id,
    required this.contentId,
    required this.title,
    required this.type,
    required this.promptText,
    required this.version,
    this.status = PromptStatus.saved,
    required this.createdAt,
    required this.updatedAt,
    this.sourceScriptVersion,
    this.metadata = const {},
  });

  SavedPrompt copyWith({
    PromptStatus? status,
    String? promptText,
    Map<String, dynamic>? metadata,
  }) {
    return SavedPrompt(
      id: id,
      contentId: contentId,
      title: title,
      type: type,
      promptText: promptText ?? this.promptText,
      version: version,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      sourceScriptVersion: sourceScriptVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
          'id': id,
          'contentId': contentId,
          'title': title,
          'type': type.name,
          'promptText': promptText,
          'version': version,
          'status': status.name,
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': updatedAt.toIso8601String(),
          'sourceScriptVersion': sourceScriptVersion,
          'metadata': metadata,
        };

  factory SavedPrompt.fromJson(Map<String, dynamic> json) => SavedPrompt(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        title: json['title'] as String,
        type: PromptTypeExtension.fromName(
            json['type'] as String? ?? 'custom'),
        promptText: json['promptText'] as String,
        version: (json['version'] as num?)?.toInt() ?? 1,
        status: PromptStatusExtension.fromName(
            json['status'] as String? ?? 'saved'),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        sourceScriptVersion: json['sourceScriptVersion'] as String?,
        metadata:
            (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}

class _PromptVaultStore extends JsonFileStore<SavedPrompt> {
  _PromptVaultStore() : super('saved_prompts.json');

  @override
  String idOf(SavedPrompt item) => item.id;

  @override
  SavedPrompt fromJson(Map<String, dynamic> json) =>
      SavedPrompt.fromJson(json);

  @override
  Map<String, dynamic> toJson(SavedPrompt item) => item.toJson();
}

class PromptVault {
  static final _PromptVaultStore _store = _PromptVaultStore();

  @visibleForTesting
  static void useDirectory(Directory dir) => JsonFileStore.setTestDirectory(dir);

  @visibleForTesting
  static void resetDirectory() => JsonFileStore.clearTestDirectory();

  static Future<List<SavedPrompt>> getAll() async {
    final items = await _store.loadAll();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  static Future<List<SavedPrompt>> getByContentId(String contentId) async {
    final all = await getAll();
    return all.where((p) => p.contentId == contentId).toList();
  }

  static Future<List<SavedPrompt>> getByType(PromptType type) async {
    final all = await getAll();
    return all.where((p) => p.type == type).toList();
  }

  static Future<SavedPrompt?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<SavedPrompt?> getLatest(String contentId, PromptType type) async {
    final matches = await getByContentId(contentId);
    final filtered = matches.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.version.compareTo(a.version));
    return filtered.first;
  }

  static Future<void> save(SavedPrompt prompt) async {
    await _store.saveAll([prompt]);
  }

  static Future<void> saveWithVersion({
    required String contentId,
    required String title,
    required PromptType type,
    required String promptText,
    String? sourceScriptVersion,
    Map<String, dynamic>? metadata,
  }) async {
    final existing = await getByContentId(contentId);
    final sameType = existing.where((p) => p.type == type).toList();
    sameType.sort((a, b) => b.version.compareTo(a.version));
    final nextVersion = sameType.isEmpty ? 1 : sameType.first.version + 1;

    final prompt = SavedPrompt(
      id: '${contentId}_${type.name}_v$nextVersion',
      contentId: contentId,
      title: title,
      type: type,
      promptText: promptText,
      version: nextVersion,
      sourceScriptVersion: sourceScriptVersion,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final all = await getAll();
    all.insert(0, prompt);
    await _store.saveAll(all);
  }

  static Future<void> updateStatus(String id, PromptStatus status) async {
    final all = await getAll();
    final index = all.indexWhere((p) => p.id == id);
    if (index != -1) {
      all[index] = all[index].copyWith(status: status);
      await _store.saveAll(all);
    }
  }

  static Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((p) => p.id == id);
    await _store.saveAll(all);
  }

  static Future<void> deleteByContentId(String contentId) async {
    final all = await getAll();
    all.removeWhere((p) => p.contentId == contentId);
    await _store.saveAll(all);
  }

  static Future<bool> trySave(SavedPrompt prompt) async {
    try {
      await save(prompt);
      return true;
    } catch (e) {
      debugPrint('PromptVault: save failed — $e');
      return false;
    }
  }
}
