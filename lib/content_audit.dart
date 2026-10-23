// Content Audit model — tracks published Instagram content for the
// Fun Learning With Palak page, enabling duplication checks, performance
// tracking, and format experiment logging.
//
// Built on the existing JsonFileStore<T> infrastructure.

import 'content_axes.dart';
import 'json_file_store.dart';

/// Status of a content item in the audit/Instagram lifecycle.
enum AuditStatus {
  idea('Idea'),
  drafted('Drafted'),
  ready('Ready'),
  posted('Posted'),
  repurpose('Repurpose'),
  retired('Retired');

  final String label;
  const AuditStatus(this.label);
}

/// Metrics tracked for each published piece of content.
class ContentMetrics {
  final int? reach;
  final int? nonFollowerReach;
  final int? plays;
  final int? averageWatchTimeSeconds;
  final int? shares;
  final int? saves;
  final int? profileVisits;
  final int? followsAttributed;

  const ContentMetrics({
    this.reach,
    this.nonFollowerReach,
    this.plays,
    this.averageWatchTimeSeconds,
    this.shares,
    this.saves,
    this.profileVisits,
    this.followsAttributed,
  });

  Map<String, dynamic> toJson() => {
        'reach': reach,
        'nonFollowerReach': nonFollowerReach,
        'plays': plays,
        'averageWatchTimeSeconds': averageWatchTimeSeconds,
        'shares': shares,
        'saves': saves,
        'profileVisits': profileVisits,
        'followsAttributed': followsAttributed,
      };

  factory ContentMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContentMetrics();
    return ContentMetrics(
      reach: json['reach'] as int?,
      nonFollowerReach: json['nonFollowerReach'] as int?,
      plays: json['plays'] as int?,
      averageWatchTimeSeconds: json['averageWatchTimeSeconds'] as int?,
      shares: json['shares'] as int?,
      saves: json['saves'] as int?,
      profileVisits: json['profileVisits'] as int?,
      followsAttributed: json['followsAttributed'] as int?,
    );
  }
}

/// A single audited content item, mapped from the audit's proposed JSON schema.
class ContentAuditItem {
  final String id;
  final String title;
  final ContentPillar pillar;
  final String format;
  final String audienceAge;
  final String language;
  final List<String> characters;
  final String parentProblem;
  final String learningGoal;
  final String hook;
  final List<String> storyBeats;
  final String? narration;
  final List<String> onScreenText;
  final String? caption;
  final List<String> hashtags;
  final String cta;
  final AuditStatus status;
  final List<String> relatedContentIds;
  final String? publishedUrl;
  final ContentMetrics metrics;
  final int experimentCount;
  final List<String> reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentAuditItem({
    required this.id,
    required this.title,
    required this.pillar,
    required this.format,
    required this.audienceAge,
    required this.language,
    required this.characters,
    required this.parentProblem,
    required this.learningGoal,
    required this.hook,
    this.storyBeats = const [],
    this.narration,
    this.onScreenText = const [],
    this.caption,
    this.hashtags = const [],
    this.cta = '',
    this.status = AuditStatus.idea,
    this.relatedContentIds = const [],
    this.publishedUrl,
    this.metrics = const ContentMetrics(),
    this.experimentCount = 0,
    this.reviewNotes = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ContentAuditItem copyWith({
    String? title,
    ContentPillar? pillar,
    String? format,
    String? audienceAge,
    String? language,
    List<String>? characters,
    String? parentProblem,
    String? learningGoal,
    String? hook,
    List<String>? storyBeats,
    String? narration,
    List<String>? onScreenText,
    String? caption,
    List<String>? hashtags,
    String? cta,
    AuditStatus? status,
    List<String>? relatedContentIds,
    String? publishedUrl,
    ContentMetrics? metrics,
    int? experimentCount,
    List<String>? reviewNotes,
    DateTime? updatedAt,
  }) {
    return ContentAuditItem(
      id: id,
      title: title ?? this.title,
      pillar: pillar ?? this.pillar,
      format: format ?? this.format,
      audienceAge: audienceAge ?? this.audienceAge,
      language: language ?? this.language,
      characters: characters ?? this.characters,
      parentProblem: parentProblem ?? this.parentProblem,
      learningGoal: learningGoal ?? this.learningGoal,
      hook: hook ?? this.hook,
      storyBeats: storyBeats ?? this.storyBeats,
      narration: narration ?? this.narration,
      onScreenText: onScreenText ?? this.onScreenText,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      cta: cta ?? this.cta,
      status: status ?? this.status,
      relatedContentIds: relatedContentIds ?? this.relatedContentIds,
      publishedUrl: publishedUrl ?? this.publishedUrl,
      metrics: metrics ?? this.metrics,
      experimentCount: experimentCount ?? this.experimentCount,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pillar': pillar.name,
        'format': format,
        'audienceAge': audienceAge,
        'language': language,
        'characters': characters,
        'parentProblem': parentProblem,
        'learningGoal': learningGoal,
        'hook': hook,
        'storyBeats': storyBeats,
        'narration': narration,
        'onScreenText': onScreenText,
        'caption': caption,
        'hashtags': hashtags,
        'cta': cta,
        'status': status.name,
        'relatedContentIds': relatedContentIds,
        'publishedUrl': publishedUrl,
        'metrics': metrics.toJson(),
        'experimentCount': experimentCount,
        'reviewNotes': reviewNotes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ContentAuditItem.fromJson(Map<String, dynamic> json) => ContentAuditItem(
        id: json['id'] as String,
        title: json['title'] as String,
    pillar: _pillarFromString(json['pillar'] as String? ?? 'play'),
        format: json['format'] as String? ?? 'story_reel',
        audienceAge: json['audienceAge'] as String? ?? '1-4',
        language: json['language'] as String? ?? 'hinglish',
        characters:
            (json['characters'] as List?)?.cast<String>() ?? const [],
        parentProblem: json['parentProblem'] as String? ?? '',
        learningGoal: json['learningGoal'] as String? ?? '',
        hook: json['hook'] as String? ?? '',
        storyBeats:
            (json['storyBeats'] as List?)?.cast<String>() ?? const [],
        narration: json['narration'] as String?,
        onScreenText:
            (json['onScreenText'] as List?)?.cast<String>() ?? const [],
        caption: json['caption'] as String?,
        hashtags:
            (json['hashtags'] as List?)?.cast<String>() ?? const [],
        cta: json['cta'] as String? ?? '',
        status: enumByNameOr(AuditStatus.values, json['status'] as String? ?? 'idea', AuditStatus.idea),
        relatedContentIds:
            (json['relatedContentIds'] as List?)?.cast<String>() ?? const [],
        publishedUrl: json['publishedUrl'] as String?,
        metrics: ContentMetrics.fromJson(
            json['metrics'] as Map<String, dynamic>?),
        experimentCount: json['experimentCount'] as int? ?? 0,
        reviewNotes:
            (json['reviewNotes'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Store for ContentAuditItem, persisting to `content_audit.json`.
class ContentAuditStore extends JsonFileStore<ContentAuditItem> {
  ContentAuditStore() : super('content_audit.json');

  @override
  String idOf(ContentAuditItem item) => item.id;

  @override
  ContentAuditItem fromJson(Map<String, dynamic> json) =>
      ContentAuditItem.fromJson(json);

  @override
  Map<String, dynamic> toJson(ContentAuditItem item) => item.toJson();

  static final ContentAuditStore instance = ContentAuditStore();

  static Future<List<ContentAuditItem>> load() => instance.loadAll();

  static Future<ContentAuditItem?> getById(String id) => instance.loadById(id);

  static Future<void> save(ContentAuditItem item) => instance.add(item);

  static Future<void> update(ContentAuditItem item) async {
    final list = await instance.loadAll();
    final index = list.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      list[index] = item.copyWith(updatedAt: DateTime.now());
      await instance.saveAll(list);
    }
  }

  static Future<void> delete(String id) => instance.deleteById(id);

  static Future<void> recordMetrics(
    String id,
    ContentMetrics metrics,
  ) async {
    final item = await instance.loadById(id);
    if (item == null) return;
    final list = await instance.loadAll();
    final index = list.indexWhere((i) => i.id == id);
    if (index != -1) {
      list[index] = item.copyWith(
        metrics: metrics,
        experimentCount: item.experimentCount + 1,
        updatedAt: DateTime.now(),
      );
      await instance.saveAll(list);
    }
  }

  static Future<void> addReviewNote(
    String id,
    String note,
  ) async {
    final item = await instance.loadById(id);
    if (item == null) return;
    final list = await instance.loadAll();
    final index = list.indexWhere((i) => i.id == id);
    if (index != -1) {
      list[index] = item.copyWith(
        reviewNotes: [...item.reviewNotes, note],
        updatedAt: DateTime.now(),
      );
      await instance.saveAll(list);
    }
  }

  /// Finds items with similar parent problems for duplication detection.
  static Future<List<ContentAuditItem>> findByParentProblem(
    String problem,
  ) async {
    final all = await instance.loadAll();
    return all
        .where((i) =>
            i.parentProblem.isNotEmpty &&
            problem.toLowerCase().contains(i.parentProblem.toLowerCase()) ||
            i.parentProblem.toLowerCase().contains(problem.toLowerCase()))
        .toList();
  }
}

/// Maps audit pillar strings (from the audit document's vocabulary) to
/// the app's canonical ContentPillar values. The audit uses descriptive
/// names like "relatable_toddler_moments"; the app uses PLAY/THINK/DISCOVER/TALK/DO.
ContentPillar _pillarFromString(String raw) {
  final found = ContentPillar.byLabel(raw);
  if (found != null) return found;
  final lower = raw.toLowerCase();
  if (lower.contains('think') || lower.contains('guess')) {
    return ContentPillar.think;
  }
  if (lower.contains('discover') || lower.contains('explore')) {
    return ContentPillar.discover;
  }
  if (lower.contains('talk') || lower.contains('conversation')) {
    return ContentPillar.talk;
  }
  if (lower.contains('activity') || lower.contains('home') ||
      lower.contains('try') || lower.contains('skill') ||
      lower.contains('reference')) {
    return ContentPillar.doIt;
  }
  return ContentPillar.play;
}

// ── Performance Learning (P1) ─────────────────────────────────────────────────
//
// After publishing, the creator records actual results. This class connects those
// results to the creative decisions (hook type, content purpose, format) so the
// creator can see patterns and test more deliberately.

/// A single creative decision linked to its performance.
class CreativeDecision {
  final String hookType;
  final String contentPurpose;
  final String format;
  final int score;

  /// Non-negative performance index: shares + saves + (comments * 2).
  /// Weighted because saves and shares are the actions that extend reach.
  final int strength;

  /// Whether the post cleared the five-test minimum for this combination.
  final bool meetsFiveTestRule;

  const CreativeDecision({
    required this.hookType,
    required this.contentPurpose,
    required this.format,
    required this.score,
    required this.strength,
    required this.meetsFiveTestRule,
  });
}

/// Analyzes published content results to inform future creative decisions.
///
/// Connects actual Instagram metrics to the hook type, content purpose, and
/// format used, then surfaces patterns without making viral claims.
class PerformanceLearn {
  final List<CreativeDecision> decisions;

  const PerformanceLearn(this.decisions);

  /// Groups decisions by hook type and returns average strength per hook.
  ///
  /// Only includes hook types with at least [minSamples] entries, respecting
  /// the five-test principle.
  Map<String, double> averageStrengthByHook({int minSamples = 5}) {
    final sums = <String, int>{};
    final counts = <String, int>{};
    for (final d in decisions) {
      final key = d.hookType;
      sums.update(key, (v) => v + d.strength, ifAbsent: () => d.strength);
      counts.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
    final result = <String, double>{};
    for (final key in sums.keys) {
      if (counts[key]! >= minSamples) {
        result[key] = sums[key]! / counts[key]!;
      }
    }
    return result;
  }

  /// Groups decisions by content purpose and returns average strength per purpose.
  Map<String, double> averageStrengthByPurpose({int minSamples = 5}) {
    final sums = <String, int>{};
    final counts = <String, int>{};
    for (final d in decisions) {
      final key = d.contentPurpose;
      sums.update(key, (v) => v + d.strength, ifAbsent: () => d.strength);
      counts.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
    final result = <String, double>{};
    for (final key in sums.keys) {
      if (counts[key]! >= minSamples) {
        result[key] = sums[key]! / counts[key]!;
      }
    }
    return result;
  }

  /// Identifies recently used hooks to avoid repetition.
  ///
  /// Returns the most common hook types in the last [recentWindow] decisions.
  List<String> recentlyUsedHooks({int recentWindow = 10}) {
    final recent = decisions.take(recentWindow);
    final counts = <String, int>{};
    for (final d in recent) {
      counts.update(d.hookType, (v) => v + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  /// Returns a list of potential patterns to test next.
  ///
  /// Looks for hook types that have performed well but haven't been tested
  /// five times yet, and purposes that are under-represented.
  List<String> recommendedTests({int minSamples = 5}) {
    final recs = <String>[];
    final hookCounts = <String, int>{};
    final hookStrengths = <String, List<int>>{};
    for (final d in decisions) {
      hookCounts.update(d.hookType, (v) => v + 1, ifAbsent: () => 1);
      hookStrengths.putIfAbsent(d.hookType, () => []).add(d.strength);
    }
    for (final entry in hookCounts.entries) {
      if (entry.value < minSamples) {
        final strengths = hookStrengths[entry.key]!;
        final avg = strengths.isEmpty ? 0.0 : strengths.reduce((a, b) => a + b) / strengths.length;
        if (avg > 0) {
          recs.add('Test ${entry.key} hook (${entry.value} tries so far, avg strength ${avg.round()})');
        }
      }
    }
    return recs;
  }
}

/// Builds a [CreativeDecision] from a published [ContentAuditItem] and its
/// recorded metrics.
CreativeDecision buildCreativeDecision(ContentAuditItem item) {
  final metrics = item.metrics;
  final strength = (metrics.shares ?? 0) +
      (metrics.saves ?? 0) +
      ((metrics.plays ?? 0) > 0 ? (metrics.plays! / 100).round() : 0);
  return CreativeDecision(
    hookType: item.hook.isNotEmpty ? item.hook : 'unknown',
    contentPurpose: item.learningGoal.isNotEmpty
        ? item.learningGoal
        : 'unknown',
    format: item.format,
    score: _scoreFromStatus(item),
    strength: strength,
    meetsFiveTestRule: item.experimentCount >= 5,
  );
}

int _scoreFromStatus(ContentAuditItem item) {
  if (item.metrics.shares != null && item.metrics.shares! > 10) return 9;
  if (item.metrics.saves != null && item.metrics.saves! > 5) return 7;
  if (item.metrics.reach != null && item.metrics.reach! > 100) return 6;
  return 3;
}
