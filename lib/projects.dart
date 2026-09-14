import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'plan_data.dart';

// ── Saved stories ─────────────────────────────────────────────────────────────
//
// Nothing used to be saved anywhere. A story lived in one text field, the script in
// a list in memory, and both were gone the moment Gemini returned an error and you
// had to start again — including the story you actually liked, which is the part
// that took the longest and was the hardest to get back.
//
// So everything is written to the phone as it happens. Not a "save" button: a save
// button is only pressed after you already know the work was worth keeping, and the
// work you lose is always the work you had not decided about yet.
//
// One JSON file per story, same shape as characters.dart uses — small, readable, and
// nothing to migrate later.

class Project {
  /// Made from the clock when the story is first written and never changed, so
  /// saving again overwrites the same file instead of leaving copies everywhere.
  final String id;
  final String title;
  final DateTime savedAt;

  /// The story as typed. The part worth protecting.
  final String story;

  /// "0:04|Hinglish line|Devanagari line" per script line, so a script survives with
  /// its timings and its spoken half intact.
  final List<String> script;

  final String style;
  final String language;
  final int seconds;

  /// Where the pictures were when it was saved. They live in the phone's own picker
  /// cache, which Android clears when it likes, so these are checked on the way back
  /// in rather than trusted.
  final List<String> images;

  /// Gemini's reply to the prompts request, saved word for word.
  ///
  /// The prompts screen used to ask Gemini again every single time it was opened,
  /// which meant paying for an identical answer twice — and on a free tier, paying
  /// means running out. Kept here, reopening it costs nothing.
  final String promptsJson;

  /// The script those prompts were written for. Prompts describe one picture per
  /// line, so if the script has changed they no longer match it and are worth
  /// asking for again; if it has not, they are as good as the day they arrived.
  final List<String> promptsScript;

  /// Anything you rewrote yourself, by field name.
  ///
  /// Kept apart from Gemini's reply rather than written over it, so an edit survives
  /// asking for new prompts, and so the original is still there if the edit turns out
  /// worse. What you typed always wins over what was generated.
  final Map<String, String> edits;

  /// Which story text the saved script was written from. Lets the story screen tell
  /// "this story already has a script" apart from "this story was edited since", so it
  /// can reopen the script instead of spending a request writing it again.
  final String scriptStoryKey;

  // ── What has already been made ──────────────────────────────────────────────
  //
  // Each finished thing is kept with a fingerprint of everything it was made from.
  // Same fingerprint, same result — so it is opened, not made again. Change a word,
  // a picture or a setting and the fingerprint changes, and only then is it redone.

  /// The voice engine and voice last used, so reopening does not quietly fall back
  /// to the phone voice and record something you never chose.
  final String engine;
  final String voiceName;

  /// Captions, caption position, movement, end card — remembered per story.
  final Map<String, String> look;

  final String voicePath;
  final String voiceKey;
  /// Where each line starts in that voice, as measured from its pauses. Kept because
  /// measuring again needs the voice file and a pass through FFmpeg for nothing.
  final List<double> lineStarts;

  final String reelPath;
  final String reelKey;
  /// Whether this reel has already been put in the gallery, so the button can say so
  /// instead of inviting a second copy.
  final bool inGallery;

  /// A heading you gave the story yourself. Kept apart from [title], which is worked out
  /// from the first line of the story and rewritten on every autosave — a name typed into
  /// title would be overwritten the next time the story was touched. Empty means none.
  final String name;

  /// What the story is shown as: your name for it, or the automatic title.
  String get displayName => name.trim().isNotEmpty ? name.trim() : title;

  const Project({
    required this.id,
    required this.title,
    required this.savedAt,
    required this.story,
    this.script = const [],
    this.style = '',
    this.language = '',
    this.seconds = 30,
    this.images = const [],
    this.promptsJson = '',
    this.promptsScript = const [],
    this.edits = const {},
    this.scriptStoryKey = '',
    this.engine = '',
    this.voiceName = '',
    this.look = const {},
    this.voicePath = '',
    this.voiceKey = '',
    this.lineStarts = const [],
    this.reelPath = '',
    this.reelKey = '',
    this.inGallery = false,
    this.name = '',
  });

  /// First few words of the story, which is what you will recognise it by.
  static String titleFrom(String story) {
    final lines = story
        .split('\n')
        .map((l) => l.trim())
        // Skip the form's empty labels: "Hook:" on its own tells you nothing in a list.
        .where((l) => l.isNotEmpty && !l.endsWith(':'))
        .toList();
    final firstLine = lines.isEmpty ? '' : lines.first;

    // The label is stripped but what follows it is kept — "Hook: Tractor gayab!"
    // is a much better name for a story than "Hook".
    final withoutLabel = firstLine.contains(': ')
        ? firstLine.substring(firstLine.indexOf(': ') + 2)
        : firstLine;

    final clean = withoutLabel.trim();
    if (clean.isEmpty) return 'Untitled story';
    return clean.length <= 46 ? clean : '${clean.substring(0, 44)}…';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'savedAt': savedAt.toIso8601String(),
        'story': story,
        'script': script,
        'style': style,
        'language': language,
        'seconds': seconds,
        'images': images,
        'promptsJson': promptsJson,
        'promptsScript': promptsScript,
        'edits': edits,
        'scriptStoryKey': scriptStoryKey,
        'engine': engine,
        'voiceName': voiceName,
        'look': look,
        'voicePath': voicePath,
        'voiceKey': voiceKey,
        'lineStarts': lineStarts,
        'reelPath': reelPath,
        'reelKey': reelKey,
        'inGallery': inGallery,
        'name': name,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled story',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime(2020),
        story: json['story'] as String? ?? '',
        script: ((json['script'] as List?) ?? const []).whereType<String>().toList(),
        style: json['style'] as String? ?? '',
        language: json['language'] as String? ?? '',
        seconds: (json['seconds'] as num?)?.toInt() ?? 30,
        images: ((json['images'] as List?) ?? const []).whereType<String>().toList(),
        promptsJson: json['promptsJson'] as String? ?? '',
        promptsScript: ((json['promptsScript'] as List?) ?? const []).whereType<String>().toList(),
        edits: ((json['edits'] as Map?) ?? const {})
            .map((k, v) => MapEntry('$k', '$v')),
        scriptStoryKey: json['scriptStoryKey'] as String? ?? '',
        engine: json['engine'] as String? ?? '',
        voiceName: json['voiceName'] as String? ?? '',
        look: ((json['look'] as Map?) ?? const {})
            .map((k, v) => MapEntry('$k', '$v')),
        voicePath: json['voicePath'] as String? ?? '',
        voiceKey: json['voiceKey'] as String? ?? '',
        lineStarts: ((json['lineStarts'] as List?) ?? const [])
            .whereType<num>().map((n) => n.toDouble()).toList(),
        reelPath: json['reelPath'] as String? ?? '',
        reelKey: json['reelKey'] as String? ?? '',
        inGallery: json['inGallery'] as bool? ?? false,
        name: json['name'] as String? ?? '',
      );

  /// Every field has to be carried through here, including the ones nothing calls
  /// with — a field left out is not left alone, it is silently emptied on the next
  /// save, and the saved prompts would have been wiped by the next keystroke.
  Project copyWith({
    String? title,
    String? story,
    List<String>? script,
    String? style,
    String? language,
    int? seconds,
    List<String>? images,
    String? promptsJson,
    List<String>? promptsScript,
    Map<String, String>? edits,
    String? scriptStoryKey,
    String? engine,
    String? voiceName,
    Map<String, String>? look,
    String? voicePath,
    String? voiceKey,
    List<double>? lineStarts,
    String? reelPath,
    String? reelKey,
    bool? inGallery,
    String? name,
  }) =>
      Project(
        id: id,
        title: title ?? this.title,
        savedAt: DateTime.now(),
        story: story ?? this.story,
        script: script ?? this.script,
        style: style ?? this.style,
        language: language ?? this.language,
        seconds: seconds ?? this.seconds,
        images: images ?? this.images,
        promptsJson: promptsJson ?? this.promptsJson,
        promptsScript: promptsScript ?? this.promptsScript,
        edits: edits ?? this.edits,
        scriptStoryKey: scriptStoryKey ?? this.scriptStoryKey,
        engine: engine ?? this.engine,
        voiceName: voiceName ?? this.voiceName,
        look: look ?? this.look,
        voicePath: voicePath ?? this.voicePath,
        voiceKey: voiceKey ?? this.voiceKey,
        lineStarts: lineStarts ?? this.lineStarts,
        reelPath: reelPath ?? this.reelPath,
        reelKey: reelKey ?? this.reelKey,
        inGallery: inGallery ?? this.inGallery,
        name: name ?? this.name,
      );
}

/// A short fingerprint of some text, the same every time for the same text.
///
/// FNV-1a rather than String.hashCode, because hashCode is not promised to stay the
/// same between runs of the app, and a fingerprint that changes on restart would make
/// every saved voice and reel look out of date the next morning.
String fingerprint(String text) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// Copies a file into the app's own storage and returns the new path.
///
/// Voices, reels and picked pictures all start life in cache folders that Android
/// empties whenever it likes. A story that "has a reel" is only true while the reel
/// is somewhere that does not get cleared behind your back.
Future<String> keepFile(String sourcePath, String folder, String name) async {
  final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/$folder');
  if (!await dir.exists()) await dir.create(recursive: true);
  final target = '${dir.path}/$name';
  if (sourcePath == target) return target;

  final old = File(target);
  if (await old.exists()) await old.delete();
  await File(sourcePath).copy(target);
  return target;
}

/// One story by id, or null.
Future<Project?> loadProject(String id) async {
  if (id.isEmpty) return null;
  final matches = (await ProjectStore.load()).where((p) => p.id == id);
  return matches.isEmpty ? null : matches.first;
}

class ProjectStore {
  static const _folder = 'stories';

  /// Everything saved, newest first.
  static Future<List<Project>> load() async {
    try {
      final dir = await _dir();
      if (!await dir.exists()) return [];

      final out = <Project>[];
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final raw = jsonDecode(await entity.readAsString());
          if (raw is Map<String, dynamic>) out.add(Project.fromJson(raw));
        } catch (_) {
          // One unreadable file must not hide every other story.
        }
      }
      out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Writes one story. Silent on failure by design — this is called on every edit,
  /// and an alert box about a failed autosave in the middle of typing would be worse
  /// than the thing it is warning about.
  static Future<void> save(Project project) => _inTurn(() => _write(project));

  /// Changes one story as a single step: read it fresh, change it, write it.
  ///
  /// Every screen writes to the same file — the story screen, the editor, the voice,
  /// the reel, the caption sheet — and several of them used to read the story, wait on
  /// something, then write back what they had read. Two of those overlapping meant the
  /// second quietly put back what the first had just changed: a cover pick or a saved
  /// voice undone by an autosave that had read the file a moment earlier. Taking turns,
  /// each change starts from whatever the one before it left.
  ///
  /// Returns null when the story is not on the phone.
  static Future<Project?> update(String id, Project Function(Project current) change) =>
      _inTurn(() async {
        final current = await _read(id);
        if (current == null) return null;
        final next = change(current);
        await _write(next);
        return next;
      });

  /// The same, but creates the story from [seed] when it is not saved yet.
  static Future<Project> upsert(Project seed, Project Function(Project current) change) =>
      _inTurn(() async {
        final next = change(await _read(seed.id) ?? seed);
        await _write(next);
        return next;
      });

  static Future<void> _queue = Future.value();

  static Future<T> _inTurn<T>(Future<T> Function() job) {
    final done = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        done.complete(await job());
      } catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }

  static Future<Project?> _read(String id) async {
    try {
      final file = File('${(await _dir()).path}/$id.json');
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      return raw is Map<String, dynamic> ? Project.fromJson(raw) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(Project project) async {
    try {
      final dir = await _dir();
      if (!await dir.exists()) await dir.create(recursive: true);
      await File('${dir.path}/${project.id}.json')
          .writeAsString(jsonEncode(project.toJson()));
    } catch (_) {}

    // The copy in Downloads is the only one that survives an uninstall, so it is kept
    // up to date automatically rather than waiting for anyone to remember a button.
    ProjectBackup.schedule();
  }

  static Future<void> delete(String id) async {
    try {
      final file = File('${(await _dir()).path}/$id.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Drops picture paths that no longer point at anything, so reopening an old story
  /// does not fail later with a missing file halfway through a render.
  static Future<List<String>> existingImages(List<String> paths) async {
    final out = <String>[];
    for (final p in paths) {
      if (await File(p).exists()) out.add(p);
    }
    return out;
  }

  static Future<Directory> _dir() async =>
      Directory('${(await getApplicationDocumentsDirectory()).path}/$_folder');
}

// ── Surviving an uninstall ────────────────────────────────────────────────────
//
// Everything above is written to the app's own folder, and Android deletes that folder
// the moment the app is uninstalled. Reinstalling gives you a clean, empty app —
// stories, scripts, captions and edits all gone, with nothing in the app able to stop
// it from the inside.
//
// Downloads is the one place on the phone that survives. Every save also drops a copy
// of everything there, and Restore reads it back.
//
// The restore is a file picker rather than the app just reading Downloads on its own,
// and that is not laziness: after a reinstall the app no longer owns the file it wrote
// last week and genuinely cannot see it any more. Pointing at it is one tap and needs
// no storage permission at all.

const _mediaChannel = MethodChannel('com.example.reel_audio/media');

class ProjectBackup {
  /// Writes every story to Downloads. Returns where it landed.
  /// "Back up now" and the automatic backup share this one door, so pressing the button
  /// while an automatic one is mid-write waits for it instead of writing over it.
  static Future<String> write() {
    final done = Completer<String>();
    _writeChain = _writeChain.then((_) async {
      try {
        done.complete(await _writeNow());
      } catch (e, s) {
        done.completeError(e, s);
      }
    });
    return done.future;
  }

  static Future<void> _writeChain = Future.value();

  static Future<String> _writeNow() async {
    final all = await ProjectStore.load();
    final json = jsonEncode({
      'app': 'reel_audio',
      'version': 2,
      'savedAt': DateTime.now().toIso8601String(),
      'stories': all.map((p) => p.toJson()).toList(),
      // The plan goes with the stories: a reinstall that brought back the stories but
      // lost your hooks, your posting times and every result you logged would lose
      // the part that takes weeks to build up.
      'hooks': (await HookStore.load()).map((h) => h.toJson()).toList(),
      'schedule': (await ScheduleStore.load()).map((s) => s.toJson()).toList(),
      'posts': (await PostLogStore.load()).map((p) => p.toJson()).toList(),
    });

    final where = await _mediaChannel.invokeMethod<String>(
      'writeBackup', {'json': json});
    return where ?? 'Downloads';
  }

  /// Called after every save, and never allowed to interrupt anything.
  ///
  /// A backup that throws while you are typing would be worse than the problem it
  /// exists to solve, so a failure here is silent — the next save tries again.
  static Future<void> writeQuietly() async {
    try {
      await write();
    } catch (_) {}
  }

  /// Asks for a backup a few seconds from now, once things go quiet.
  ///
  /// It used to be written on every single save — every pause in typing, every setting
  /// tapped — each one a delete and a fresh write in Downloads. Overlapping, two of
  /// those could leave the folder with no backup at all, or with a "(1)" copy that is
  /// the out-of-date one. Now a burst of saves becomes one backup, and a backup already
  /// running is followed by one more rather than run on top of.
  static void schedule() {
    _pending?.cancel();
    _pending = Timer(const Duration(seconds: 8), _runScheduled);
  }

  static Timer? _pending;
  static bool _running = false;
  static bool _wantedAgain = false;

  static Future<void> _runScheduled() async {
    if (_running) { _wantedAgain = true; return; }
    _running = true;
    await writeQuietly();
    _running = false;
    if (_wantedAgain) { _wantedAgain = false; schedule(); }
  }

  /// Reads a backup the user picks and puts the stories back.
  ///
  /// Returns how many were restored, or null if the picker was dismissed. Stories
  /// already on the phone are kept: a restore adds what is missing rather than
  /// replacing what is there, because the commonest mistake is restoring an old
  /// backup over newer work.
  static Future<int?> restore() async {
    final text = await _mediaChannel.invokeMethod<String>('pickBackup');
    if (text == null || text.trim().isEmpty) return null;

    final raw = jsonDecode(text);
    if (raw is! Map || raw['stories'] is! List) {
      throw Exception('That file is not a stories backup.');
    }

    final existing = (await ProjectStore.load()).map((p) => p.id).toSet();
    var added = 0;

    for (final entry in raw['stories'] as List) {
      if (entry is! Map<String, dynamic>) continue;
      final project = Project.fromJson(entry);
      if (project.id.isEmpty || existing.contains(project.id)) continue;

      // Pictures were in a cache folder that is long gone, so drop the paths rather
      // than restore a story that fails at the render with a missing file.
      await ProjectStore.save(project.copyWith(
        images: await ProjectStore.existingImages(project.images)));
      added++;
    }

    // Same rule as the stories: add what is missing, never overwrite what is here.
    if (raw['hooks'] is List) {
      final have = await HookStore.load();
      final ids = have.map((h) => h.id).toSet();
      final incoming = (raw['hooks'] as List).whereType<Map<String, dynamic>>()
          .map(HookIdea.fromJson).where((h) => h.id.isNotEmpty);
      String sig(HookIdea h) => jsonEncode(h.toJson());
      final defaults = {for (final d in kDefaultHooks) d.id: sig(d)};
      final merged = [
        ...have.map((h) {
          final match = incoming.where((i) => i.id == h.id);
          if (match.isEmpty) return h;
          // Untouched here, so the backup's version — with its edits and its "used"
          // date — is the more informed one. Changed here, so this phone's wins.
          return sig(h) == defaults[h.id] ? match.first : h;
        }),
        ...incoming.where((h) => !ids.contains(h.id)),
      ];
      await HookStore.save(merged);
    }
    if (raw['posts'] is List) {
      final have = await PostLogStore.load();
      final ids = have.map((p) => p.id).toSet();
      final incoming = (raw['posts'] as List).whereType<Map<String, dynamic>>()
          .map(PostRecord.fromJson).where((p) => p.id.isNotEmpty && !ids.contains(p.id));
      await PostLogStore.save([...have, ...incoming]);
    }
    // The schedule is one small table, so a backup's copy replaces the default only
    // when nothing here has been changed from the default.
    if (raw['schedule'] is List) {
      final here = await ScheduleStore.load();
      final untouched = jsonEncode(here.map((s) => s.toJson()).toList()) ==
          jsonEncode(kDefaultSchedule.map((s) => s.toJson()).toList());
      final incoming = (raw['schedule'] as List).whereType<Map<String, dynamic>>()
          .map(PostSlot.fromJson).toList();
      if (untouched && incoming.length == 7) await ScheduleStore.save(incoming);
    }
    return added;
  }
}
