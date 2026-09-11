import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

// ── Saved character faces ─────────────────────────────────────────────────────
//
// One reference picture per character, kept for good so every future reel uses the
// same faces. The written description in prompts.dart keeps the wording identical;
// these keep the FACE identical, which words alone never manage — describe "toddler
// girl with pigtails" ten times and you get ten different children.
//
// Pictures are copied into the app's own documents folder, not referenced where the
// gallery put them: an image_picker path lives in a cache the phone clears whenever
// it feels like it, and a reference that vanishes next week is worse than none.

class CharacterRef {
  final String name;
  /// Absolute path to the saved copy, or null when no face has been chosen yet.
  final String? imagePath;

  const CharacterRef({required this.name, this.imagePath});

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  CharacterRef withImage(String? path) => CharacterRef(name: name, imagePath: path);

  Map<String, dynamic> toJson() => {'name': name, 'image': imagePath};

  factory CharacterRef.fromJson(Map<String, dynamic> json) => CharacterRef(
        name: json['name'] as String? ?? '',
        imagePath: json['image'] as String?,
      );
}

/// The cast. Matches the names used in the prompt text, which is what ties a saved
/// face to the character it describes.
const kDefaultCharacterNames = ['Ria', 'Rio', 'Cuty'];

class CharacterStore {
  static const _fileName = 'characters.json';
  static const _folder = 'character_faces';

  /// Loads the saved cast, falling back to the three defaults with no pictures yet.
  static Future<List<CharacterRef>> load() async {
    try {
      final file = await _indexFile();
      if (!await file.exists()) return _blankCast();

      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return _blankCast();

      final saved = raw
          .whereType<Map<String, dynamic>>()
          .map(CharacterRef.fromJson)
          .where((c) => c.name.isNotEmpty)
          .toList();

      if (saved.isEmpty) return _blankCast();

      // A picture can go missing if the phone is wiped or the app reinstalled, so
      // check rather than hand back a path that points at nothing.
      final checked = <CharacterRef>[];
      for (final c in saved) {
        final stillThere = c.hasImage && await File(c.imagePath!).exists();
        checked.add(stillThere ? c : c.withImage(null));
      }
      return checked;
    } catch (_) {
      // A corrupt index must not stop the app opening; start the cast again instead.
      return _blankCast();
    }
  }

  static Future<void> save(List<CharacterRef> cast) async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(cast.map((c) => c.toJson()).toList()));
  }

  /// Copies a picked image into permanent storage and returns its new path.
  ///
  /// Named after the character rather than given a unique name on purpose: choosing a
  /// new face for Ria should replace the old one, not leave the phone collecting
  /// every picture ever picked.
  static Future<String> saveFace(String characterName, String pickedPath) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);

    final safeName = characterName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final extension = pickedPath.contains('.') ? pickedPath.split('.').last : 'jpg';
    final target = '${dir.path}/$safeName.$extension';

    // Delete first: writing over a file the image cache is holding shows the old one.
    final existing = File(target);
    if (await existing.exists()) await existing.delete();

    await File(pickedPath).copy(target);
    return target;
  }

  static Future<void> removeFace(CharacterRef character) async {
    if (!character.hasImage) return;
    final file = File(character.imagePath!);
    if (await file.exists()) await file.delete();
  }

  static List<CharacterRef> _blankCast() =>
      kDefaultCharacterNames.map((n) => CharacterRef(name: n)).toList();

  static Future<File> _indexFile() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');
}
