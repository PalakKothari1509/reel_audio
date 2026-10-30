import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'character_definitions.dart';
import 'json_file_store.dart';

// ── The cast ──────────────────────────────────────────────────────────────────
//
// Every character the stories use, saved on the phone with a description and a face,
// and reused in every prompt from now on.
//
// Two halves, and you need both. The DESCRIPTION is repeated word for word in every
// prompt — that repetition is what keeps the clothes, the hair and the colours the
// same, and it only works if the wording never drifts. The FACE is the part words
// can never pin down: describe "toddler girl with pigtails" ten times and you get
// ten different children.

class CharacterRef {
  final String name;

  /// Pasted into every prompt exactly as written. Rewording it breaks the likeness.
  final String description;

  /// Absolute path to a face picked from the gallery, or null when none was picked.
  final String? imagePath;

  /// A face shipped inside the app, used when nothing has been picked.
  ///
  /// Means the cast has faces from the moment the app is installed — nothing to set
  /// up, and they survive a reinstall or a new phone, which a picked one does not.
  /// A picked face still wins, so any of them can be swapped without a new build.
  final String? assetPath;

  const CharacterRef({
    required this.name,
    this.description = '',
    this.imagePath,
    this.assetPath,
  });

  /// True when there is a face to show, from either source.
  bool get hasFace => hasImage || (assetPath != null && assetPath!.isNotEmpty);

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  CharacterRef copyWith({
    String? name,
    String? description,
    String? imagePath,
    bool clearImage = false,
  }) => CharacterRef(
    name: name ?? this.name,
    description: description ?? this.description,
    imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    assetPath: assetPath,
  );

  // assetPath is deliberately not saved: it comes from the build, not the phone, so
  // reading it back from an old file would pin the app to a picture that has since
  // been renamed or removed.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'image': imagePath,
  };

  factory CharacterRef.fromJson(Map<String, dynamic> json) => CharacterRef(
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    imagePath: json['image'] as String?,
  );
}

/// The starting cast, ready to use before anyone sets anything up.
///
/// Ria, Rio and Cuty are worded exactly as the reels already use them. Mum and Dad
/// are here because the stories mention them and a character with no description
/// comes out looking different in every picture.
final List<CharacterRef> kDefaultCast = List.unmodifiable([
  for (final definition in kCharacterDefinitions)
    CharacterRef(
      name: definition.name,
      assetPath: definition.assetPath,
      description: definition.referenceDescription,
    ),
]);

class _CharacterFileStore extends JsonFileStore<CharacterRef> {
  _CharacterFileStore() : super('characters.json');

  @override
  String idOf(CharacterRef item) => item.name;

  @override
  CharacterRef fromJson(Map<String, dynamic> json) =>
      CharacterRef.fromJson(json);

  @override
  Map<String, dynamic> toJson(CharacterRef item) => item.toJson();
}

class CharacterStore {
  static const _folder = 'character_faces';

  /// Internal store instance handling JSON file I/O.
  static final _CharacterFileStore _store = _CharacterFileStore();

  /// Loads the saved cast, seeding the defaults the first time the app runs.
  static Future<List<CharacterRef>> load() async {
    try {
      final saved = await _store.loadAll(shouldKeep: (c) => c.name.isNotEmpty);
      if (saved.isEmpty) {
        await save(kDefaultCast);
        return List.of(kDefaultCast);
      }

      // A picture can go missing if the phone is wiped or the app reinstalled, so
      // check rather than hand back a path that points at nothing. The bundled face
      // is re-attached from the build by name, since it is not saved â that way a
      // character whose picked face has gone falls back to the shipped one instead
      // of showing an empty tile.
      final checked = <CharacterRef>[];
      for (final c in saved) {
        final stillThere = c.hasImage && await File(c.imagePath!).exists();
        final matches = kDefaultCast.where(
          (d) => d.name.toLowerCase() == c.name.toLowerCase(),
        );
        final bundled = matches.isEmpty ? null : matches.first.assetPath;

        checked.add(
          CharacterRef(
            name: c.name,
            description: c.description,
            imagePath: stillThere ? c.imagePath : null,
            assetPath: bundled,
          ),
        );
      }
      final savedNames = checked
          .map((character) => character.name.toLowerCase())
          .toSet();
      for (final character in kDefaultCast) {
        if (savedNames.add(character.name.toLowerCase())) {
          checked.add(character);
        }
      }
      return checked;
    } catch (_) {
      // A corrupt index must not stop the app opening; start the cast again instead.
      return List.of(kDefaultCast);
    }
  }

  static Future<void> save(List<CharacterRef> cast) async {
    await _store.saveAll(cast);
  }

  /// Copies a picked image into permanent storage and returns its new path.
  ///
  /// An image_picker path lives in a cache the phone clears whenever it likes, so a
  /// reference kept there is gone by next week. Named after the character rather than
  /// given a unique name, so choosing a new face replaces the old one instead of
  /// leaving the phone collecting every picture ever picked.
  static Future<String> saveFace(
    String characterName,
    String pickedPath,
  ) async {
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/$_folder',
    );
    if (!await dir.exists()) await dir.create(recursive: true);

    final safeName = characterName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '_',
    );
    final extension = pickedPath.contains('.')
        ? pickedPath.split('.').last
        : 'jpg';
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
}

typedef CharOption = ({String id, String name, String emoji});

final List<CharOption> kCharacterOptions = List.unmodifiable(
  kCharacterDefinitions.map(
    (definition) =>
        (id: definition.id, name: definition.name, emoji: definition.emoji),
  ),
);

final List<String> kCharacterNames = List.unmodifiable(
  kCharacterDefinitions.map((definition) => definition.name),
);

final Map<String, String> kCharacterDescriptions = Map.unmodifiable({
  for (final definition in kCharacterDefinitions)
    definition.name: definition.imagePromptDescription,
});

String characterDescription(String name) =>
    kCharacterDescriptions[name] ?? 'standard character appearance';

/// Speech quirks per character — used by the generator so each person
/// actually sounds like themselves, not like one narrator.
final Map<String, String> kCharacterVoices = Map.unmodifiable({
  for (final definition in kCharacterDefinitions)
    if (definition.voice.isNotEmpty) definition.name: definition.voice,
});

/// Returns a voice hint for the given character name, or empty string.
String characterVoice(String name) => kCharacterVoices[name] ?? '';

/// Short, one-line speech pattern used for prompt injection.
/// This is distinct from [characterVoice]: it gives a 2-3 word
/// speech style tag, while [characterVoice] gives a longer example.
final Map<String, String> kSpeechPatterns = Map.unmodifiable({
  for (final definition in kCharacterDefinitions)
    if (definition.promptSpeechPattern.isNotEmpty)
      definition.name: definition.promptSpeechPattern,
});

/// Returns a short speech pattern tag for the given character name,
/// or empty string when unknown.
String speechPattern(String name) => kSpeechPatterns[name] ?? '';
