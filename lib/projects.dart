import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
      );
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
  static Future<void> save(Project project) async {
    try {
      final dir = await _dir();
      if (!await dir.exists()) await dir.create(recursive: true);
      await File('${dir.path}/${project.id}.json')
          .writeAsString(jsonEncode(project.toJson()));
    } catch (_) {}

    // The copy in Downloads is the only one that survives an uninstall, so it is kept
    // up to date automatically rather than waiting for anyone to remember a backup
    // button. Not awaited: the story is already safe on the phone by this line, and
    // the editor should not pause for a file write it does not depend on.
    unawaited(ProjectBackup.writeQuietly());
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
  static Future<String> write() async {
    final all = await ProjectStore.load();
    final json = jsonEncode({
      'app': 'reel_audio',
      'version': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'stories': all.map((p) => p.toJson()).toList(),
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
    return added;
  }
}
