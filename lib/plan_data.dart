import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'content_ideas.dart';

// ── The content plan, kept on the phone ───────────────────────────────────────
//
// Three things that used to live in chat windows and get lost: the hooks worth using,
// when to post, and how each post actually did. All three are written to the phone and
// go into the Downloads backup with the stories, so a reinstall keeps them.
//
// The posting times are a starting guess, not a fact, and the results log is what
// turns them into one. Nobody outside Instagram knows when your followers are awake;
// your own numbers after a few weeks will.

/// Called after any hook, schedule or result is saved, so the Downloads backup picks
/// it up. Set once at startup rather than imported, because the backup code already
/// imports this file and the two importing each other would tie them in a knot.
void Function()? onPlanSaved;

/// Rewrites the bucket ids that were in use before the buckets were unified.
///
/// Entries saved on the phone still hold the old ids, which no longer resolve, so
/// they would show up as plain uncoloured text in the plan. Applied on read rather
/// than by rewriting the saved file, which means an old backup still restores
/// correctly and nothing is lost if the mapping is ever changed again.
String migrateBucketId(String id) => const {
      'puzzle': 'challenge',
      'talk': 'conversation',
      'skill': 'age_practice',
      'wrap': 'community',
    }[id] ??
    id;

// ── Hooks ──────────────────────────────────────────────────────────────────────
//
// HookIdea and the built-in hook list moved to content_ideas.dart, where the rest
// of the content ideas live. This file keeps the stores that save them to the phone.

class HookStore {
  static const _file = 'hooks.json';

  /// Your list: built-in hooks with your edits applied, then the ones you added.
  /// New built-in hooks from an update appear without touching anything you changed.
  static Future<List<HookIdea>> load() async {
    final saved = <String, HookIdea>{};
    try {
      final f = await _path(_file);
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is List) {
          for (final e in raw.whereType<Map<String, dynamic>>()) {
            final h = HookIdea.fromJson(e);
            if (h.id.isNotEmpty) saved[h.id] = h;
          }
        }
      }
    } catch (_) {}

    return [
      ...kDefaultHooks.map((d) => saved[d.id] ?? d),
      ...saved.values.where((h) => h.custom),
    ];
  }

  static Future<void> save(List<HookIdea> hooks) async {
    try {
      final f = await _path(_file);
      await f.writeAsString(jsonEncode(hooks.map((h) => h.toJson()).toList()));
    } catch (_) {}
    // Hooks, times and results belong in the backup too; see onPlanSaved.
    onPlanSaved?.call();
  }

  static Future<void> markUsed(String id) async {
    final all = await load();
    await save(all.map((h) => h.id == id
        ? h.copyWith(usedOn: DateTime.now().toIso8601String()) : h).toList());
  }
}

// ── When to post ──────────────────────────────────────────────────────────────

class PostSlot {
  /// 1 is Monday, 7 is Sunday, matching DateTime.weekday.
  final int weekday;
  /// "13:30" in 24-hour time.
  final String first;
  final String backup;
  final String focus;
  const PostSlot(this.weekday, this.first, this.backup, this.focus);

  Map<String, dynamic> toJson() =>
      {'weekday': weekday, 'first': first, 'backup': backup, 'focus': focus};
  factory PostSlot.fromJson(Map<String, dynamic> j) => PostSlot(
        (j['weekday'] as num?)?.toInt() ?? 1,
        j['first'] as String? ?? '13:30',
        j['backup'] as String? ?? '20:45',
        j['focus'] as String? ?? '');
}

const kDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Built around a parent of a 2 to 6 year old rather than an office worker: the
/// afternoon lull after school pick-up and lunch, and the half hour after the children
/// are asleep. A reasoned guess — the results log is what should replace it.
const kDefaultSchedule = <PostSlot>[
  PostSlot(1, '13:30', '20:45', 'Everyday problem story'),
  PostSlot(2, '14:00', '21:00', 'Routine story'),
  PostSlot(3, '13:30', '20:45', 'Most relatable story of the week'),
  PostSlot(4, '14:00', '20:45', 'Gentle lesson story'),
  PostSlot(5, '13:30', '21:15', 'Light, funny story'),
  PostSlot(6, '10:30', '21:30', 'Fun or chaos story'),
  PostSlot(7, '11:00', '20:30', 'Warm story with a question for parents'),
];

class ScheduleStore {
  static const _file = 'schedule.json';

  static Future<List<PostSlot>> load() async {
    try {
      final f = await _path(_file);
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is List && raw.length == 7) {
          return raw.whereType<Map<String, dynamic>>().map(PostSlot.fromJson).toList();
        }
      }
    } catch (_) {}
    return List.of(kDefaultSchedule);
  }

  static Future<void> save(List<PostSlot> slots) async {
    try {
      await (await _path(_file))
          .writeAsString(jsonEncode(slots.map((s) => s.toJson()).toList()));
    } catch (_) {}
    // Hooks, times and results belong in the backup too; see onPlanSaved.
    onPlanSaved?.call();
  }
}

/// The next posting time from now, in words: "Today 8:45 PM" or "Tomorrow 1:30 PM".
String nextPostingTime(List<PostSlot> schedule, [DateTime? from]) {
  final now = from ?? DateTime.now();
  for (var offset = 0; offset < 8; offset++) {
    final day = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
    final slot = schedule.firstWhere((s) => s.weekday == day.weekday,
        orElse: () => kDefaultSchedule[day.weekday - 1]);
    for (final t in [slot.first, slot.backup]) {
      final parts = t.split(':');
      final at = day.add(Duration(
        hours: int.tryParse(parts.first) ?? 0,
        minutes: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0));
      if (at.isAfter(now)) {
        final when = offset == 0 ? 'Today' : offset == 1 ? 'Tomorrow' : kDayNames[day.weekday - 1];
        return '$when ${formatClock(t)} — ${slot.focus}';
      }
    }
  }
  return '';
}

/// "20:45" → "8:45 PM".
String formatClock(String hhmm) {
  final parts = hhmm.split(':');
  var h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  final pm = h >= 12;
  h = h % 12 == 0 ? 12 : h % 12;
  return '$h:$m ${pm ? 'PM' : 'AM'}';
}

// ── How each post did ─────────────────────────────────────────────────────────

class PostRecord {
  final String id;
  final String title;
  final String projectId;
  final String hookId;
  final String bucket;
  final DateTime postedAt;
  /// Filled in by hand from Instagram a day or two after posting. Zero means not yet.
  final int views, likes, comments, saves, shares;

  const PostRecord({
    required this.id,
    required this.title,
    required this.postedAt,
    this.projectId = '',
    this.hookId = '',
    this.bucket = '',
    this.views = 0, this.likes = 0, this.comments = 0, this.saves = 0, this.shares = 0,
  });

  PostRecord copyWith({DateTime? postedAt, int? views, int? likes, int? comments,
      int? saves, int? shares, String? bucket}) =>
      PostRecord(
        id: id, title: title, projectId: projectId, hookId: hookId,
        bucket: bucket ?? this.bucket,
        postedAt: postedAt ?? this.postedAt,
        views: views ?? this.views, likes: likes ?? this.likes,
        comments: comments ?? this.comments, saves: saves ?? this.saves,
        shares: shares ?? this.shares,
      );

  bool get hasResults => views > 0;

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'projectId': projectId, 'hookId': hookId,
        'bucket': bucket, 'postedAt': postedAt.toIso8601String(),
        'views': views, 'likes': likes, 'comments': comments,
        'saves': saves, 'shares': shares,
      };

  factory PostRecord.fromJson(Map<String, dynamic> j) => PostRecord(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        projectId: j['projectId'] as String? ?? '',
        hookId: j['hookId'] as String? ?? '',
        bucket: migrateBucketId(j['bucket'] as String? ?? ''),
        postedAt: DateTime.tryParse(j['postedAt'] as String? ?? '') ?? DateTime.now(),
        views: (j['views'] as num?)?.toInt() ?? 0,
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        comments: (j['comments'] as num?)?.toInt() ?? 0,
        saves: (j['saves'] as num?)?.toInt() ?? 0,
        shares: (j['shares'] as num?)?.toInt() ?? 0,
      );
}

class PostLogStore {
  static const _file = 'posts.json';

  static Future<List<PostRecord>> load() async {
    try {
      final f = await _path(_file);
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is List) {
          final out = raw.whereType<Map<String, dynamic>>().map(PostRecord.fromJson).toList()
            ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
          return out;
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<void> save(List<PostRecord> posts) async {
    try {
      await (await _path(_file))
          .writeAsString(jsonEncode(posts.map((p) => p.toJson()).toList()));
    } catch (_) {}
    // Hooks, times and results belong in the backup too; see onPlanSaved.
    onPlanSaved?.call();
  }

  static Future<void> add(PostRecord post) async {
    final all = await load();
    await save([post, ...all]);
  }
}

/// A time of day a post went out in, broad enough that a handful of posts can say
/// something. By the hour, a month of posting would still be one post per bucket.
String timeBucket(DateTime t) {
  final h = t.hour;
  if (h < 6) return 'Late night (12–6 AM)';
  if (h < 11) return 'Morning (6–11 AM)';
  if (h < 16) return 'Afternoon (11 AM–4 PM)';
  if (h < 20) return 'Evening (4–8 PM)';
  return 'Night (8 PM–12 AM)';
}

class TimeBucketResult {
  final String bucket;
  final int posts;
  final double avgViews, avgSaves, avgComments, avgShares;
  const TimeBucketResult(this.bucket, this.posts, this.avgViews, this.avgSaves,
      this.avgComments, this.avgShares);
}

/// Average results per time of day, best first, from posts with numbers filled in.
List<TimeBucketResult> resultsByTime(List<PostRecord> posts) {
  final groups = <String, List<PostRecord>>{};
  for (final p in posts.where((p) => p.hasResults)) {
    groups.putIfAbsent(timeBucket(p.postedAt), () => []).add(p);
  }
  double avg(List<PostRecord> g, int Function(PostRecord) f) =>
      g.map(f).fold<int>(0, (a, b) => a + b) / g.length;

  return groups.entries
      .map((e) => TimeBucketResult(e.key, e.value.length,
          avg(e.value, (p) => p.views), avg(e.value, (p) => p.saves),
          avg(e.value, (p) => p.comments), avg(e.value, (p) => p.shares)))
      .toList()
    ..sort((a, b) => b.avgViews.compareTo(a.avgViews));
}

// ── Content Bucket Results ────────────────────────────────────────────────────

class ContentBucketResult {
  final String bucket;
  final int posts;
  final double avgViews, avgSaves, avgComments, avgShares;
  final int totalSaves;
  final int totalComments;
  final int totalShares;

  const ContentBucketResult({
    required this.bucket,
    required this.posts,
    required this.avgViews,
    required this.avgSaves,
    required this.avgComments,
    required this.avgShares,
    required this.totalSaves,
    required this.totalComments,
    required this.totalShares,
  });
}

/// Average results per content bucket, best first, from posts with numbers filled in.
List<ContentBucketResult> resultsByBucket(List<PostRecord> posts) {
  final groups = <String, List<PostRecord>>{};
  for (final p in posts.where((p) => p.hasResults && p.bucket.isNotEmpty)) {
    groups.putIfAbsent(p.bucket, () => []).add(p);
  }
  double avg(List<PostRecord> g, int Function(PostRecord) f) =>
      g.map(f).fold<int>(0, (a, b) => a + b) / g.length;

  return groups.entries
      .map((e) => ContentBucketResult(
          bucket: e.key,
          posts: e.value.length,
          avgViews: avg(e.value, (p) => p.views),
          avgSaves: avg(e.value, (p) => p.saves),
          avgComments: avg(e.value, (p) => p.comments),
          avgShares: avg(e.value, (p) => p.shares),
          totalSaves: e.value.fold(0, (sum, p) => sum + p.saves),
          totalComments: e.value.fold(0, (sum, p) => sum + p.comments),
          totalShares: e.value.fold(0, (sum, p) => sum + p.shares),
        ))
      .toList()
    ..sort((a, b) => b.avgViews.compareTo(a.avgViews));
}

Future<File> _path(String name) async =>
    File('${(await getApplicationDocumentsDirectory()).path}/$name');
