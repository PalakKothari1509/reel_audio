// QuickIdea and the stores that hold it.
//
// These were at the top of quick_content.dart, which put a domain model inside a
// 4,600-line UI file. That is what created the import cycle: content_ideas.dart needs
// QuickIdea to type its kDay14Posts list, and quick_content.dart needs content_ideas.dart
// for the parser and the bucket lookups. Dart allows the cycle, but it drags all of
// quick_content.dart into anything that touches content_ideas.dart — including
// plan_data.dart, which needs only HookIdea.
//
// Nothing here may import quick_content.dart or content_ideas.dart. That constraint is
// the whole point of the file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One saved idea or post package.
///
/// Field names are on-disk format. Renaming one silently resets every saved idea,
/// because [fromJson] defaults a missing key rather than failing.
class QuickIdea {
  final String id;
  final String title;
  final String postType;
  final String audience;
  final String contentGoal;
  final String mood;
  final String hook;
  final String mainIdea;
  final String problem;
  final String lesson;
  final String visualStyle;
  final String imagePrompt;
  final String caption;
  final String cta;
  final String hashtags;
  final List<String> comments;
  final String script;

  /// One image prompt per slide, in slide order.
  ///
  /// Empty for a post whose script is not written slide by slide, because then
  /// there is nothing per slide to make one from.
  final List<String> slidePrompts;
  final DateTime createdAt;
  final String bucket;

  const QuickIdea({
    required this.id,
    required this.title,
    required this.postType,
    required this.audience,
    required this.contentGoal,
    required this.mood,
    required this.hook,
    required this.mainIdea,
    required this.problem,
    required this.lesson,
    required this.visualStyle,
    required this.imagePrompt,
    required this.caption,
    required this.cta,
    required this.hashtags,
    required this.comments,
    required this.script,
    this.slidePrompts = const [],
    required this.createdAt,
    this.bucket = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'postType': postType,
        'audience': audience,
        'contentGoal': contentGoal,
        'mood': mood,
        'hook': hook,
        'mainIdea': mainIdea,
        'problem': problem,
        'lesson': lesson,
        'visualStyle': visualStyle,
        'imagePrompt': imagePrompt,
        'caption': caption,
        'cta': cta,
        'hashtags': hashtags,
        'comments': comments,
        'script': script,
        'slidePrompts': slidePrompts,
        'createdAt': createdAt.toIso8601String(),
        'bucket': bucket,
      };

  /// Every field defaults rather than throws. A hand-edited or partially written file
  /// should degrade to a blank idea, not take the whole library with it.
  factory QuickIdea.fromJson(Map<String, dynamic> json) => QuickIdea(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        postType: json['postType'] as String? ?? 'Carousel',
        audience: json['audience'] as String? ?? 'Indian moms and parents of children aged 1-4',
        contentGoal: json['contentGoal'] as String? ?? 'Build connection',
        mood: json['mood'] as String? ?? 'Relatable',
        hook: json['hook'] as String? ?? '',
        mainIdea: json['mainIdea'] as String? ?? '',
        problem: json['problem'] as String? ?? '',
        lesson: json['lesson'] as String? ?? '',
        visualStyle: json['visualStyle'] as String? ?? 'Bright and playful',
        imagePrompt: json['imagePrompt'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        cta: json['cta'] as String? ?? 'Save this for later',
        hashtags: json['hashtags'] as String? ?? '',
        comments:
            ((json['comments'] as List?) ?? const []).whereType<String>().toList(),
        script: json['script'] as String? ?? '',
        slidePrompts:
            ((json['slidePrompts'] as List?) ?? const []).whereType<String>().toList(),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        bucket: json['bucket'] as String? ?? '',
      );
}

/// Reads a list of ideas, decoding each row on its own so one damaged entry costs
/// that entry rather than everything.
List<QuickIdea> decodeIdeas(String text) {
  try {
    final raw = jsonDecode(text);
    if (raw is! List) return const [];
    final out = <QuickIdea>[];
    for (final row in raw) {
      if (row is! Map) continue;
      try {
        out.add(QuickIdea.fromJson(Map<String, dynamic>.from(row)));
      } catch (e) {
        debugPrint('quick_ideas: skipped one unreadable item — $e');
      }
    }
    return out;
  } catch (e) {
    debugPrint('quick_ideas: could not read the file — $e');
    return const [];
  }
}

/// Saved ideas, kept indefinitely.
class QuickIdeaStore {
  static const _fileName = 'quick_ideas.json';

  static Future<File> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<QuickIdea>> load() async {
    final file = await _path();
    if (!await file.exists()) return const [];
    return decodeIdeas(await file.readAsString());
  }

  static Future<QuickIdea?> getById(String id) async {
    final all = await load();
    for (final i in all) {
      if (i.id == id) return i;
    }
    return null;
  }

  static Future<void> saveAll(List<QuickIdea> ideas) async {
    try {
      final file = await _path();
      await file.writeAsString(
        jsonEncode(ideas.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('quick_ideas: save failed — $e');
    }
  }

  static Future<void> add(QuickIdea idea) async {
    final list = await load();
    await saveAll([idea, ...list]);
  }

  static Future<void> delete(String id) async {
    final list = await load();
    list.removeWhere((i) => i.id == id);
    await saveAll(list);
  }
}

/// A capped window over the same model, for the "recently made" list.
///
/// A second copy of the same objects under a different name and a different retention
/// rule. It exists because the recent list wants a cap and the library does not.
class QuickHistoryStore {
  static const _fileName = 'quick_post_history.json';
  static const maxItems = 50;

  static Future<File> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<QuickIdea>> load() async {
    final file = await _path();
    if (!await file.exists()) return const [];
    return decodeIdeas(await file.readAsString());
  }

  static Future<void> add(QuickIdea idea) async {
    final existing = await load();
    final updated = [idea, ...existing].take(maxItems).toList();
    try {
      final file = await _path();
      await file.writeAsString(
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('quick_post_history: save failed — $e');
    }
  }
}
