import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

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

  CharacterRef copyWith({String? name, String? description, String? imagePath, bool clearImage = false}) =>
      CharacterRef(
        name: name ?? this.name,
        description: description ?? this.description,
        imagePath: clearImage ? null : (imagePath ?? this.imagePath),
        assetPath: assetPath,
      );

  // assetPath is deliberately not saved: it comes from the build, not the phone, so
  // reading it back from an old file would pin the app to a picture that has since
  // been renamed or removed.
  Map<String, dynamic> toJson() =>
      {'name': name, 'description': description, 'image': imagePath};

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
const kDefaultCast = <CharacterRef>[
  CharacterRef(
    name: "Ria",
    assetPath: "assets/characters/Ria.jpg",
    description: "toddler girl, light brown hair in two short pigtails tied with pink bows, soft fringe across the forehead, large round dark brown eyes with long lashes, fair skin with rosy cheeks and light freckles, pink short-sleeved tiered dress covered in small gold stars with pink lace trim on each tier, pink mary-jane shoes, chubby toddler body proportions",
  ),
  CharacterRef(
    name: "Rio",
    assetPath: "assets/characters/Rio.jpg",
    description: "toddler boy, tousled medium brown hair, large round amber-brown eyes with long lashes, fair skin with rosy cheeks, thick dark eyebrows, plain blue-grey short-sleeved t-shirt, matching blue-grey shorts with a side pocket, black lace-up sneakers with white soles, chubby toddler body proportions, slightly taller than Ria",
  ),
  CharacterRef(
    name: "Cuty",
    assetPath: "assets/characters/Cuty.jpg",
    description: "fluffy white bunny, long upright ears with soft pink inner colouring, coral-pink fabric bow tied at the neck, very large round dark brown eyes with lashes, small pink nose, pink blush on both cheeks, chubby rounded body standing upright like a toddler",
  ),
  CharacterRef(
    name: "Mumma",
    assetPath: "assets/characters/Mumma.jpg",
    description: "young Indian mother, medium brown hair in a high rounded bun with a few loose strands, fair-medium skin, large dark brown eyes, small red bindi, gold jhumka earrings, mustard-yellow three-quarter-sleeve kurta with white chikankari floral embroidery, blue jeans, brown flip-flop sandals, gentle warm smile",
  ),
  CharacterRef(
    name: "Papa",
    assetPath: "assets/characters/Papa.jpg",
    description: "young Indian father, short spiky black hair, thick dark eyebrows, light stubble beard, warm tan skin, dark brown eyes, light blue full-sleeve kurta with blue and gold embroidery at the mandarin collar and cuffs, matching light blue pyjama trousers, brown embroidered juttis, friendly closed-mouth smile",
  ),
  CharacterRef(
    name: "Daadi",
    assetPath: "assets/characters/Daadi.jpg",
    description: "Indian grandmother, silver-grey hair in a neat bun, warm tan skin with soft wrinkles and laugh lines, dark brown eyes, round gold-rimmed glasses, small red bindi, gold jhumka earrings, cream saree with a gold woven border and small gold floral motifs, cream embroidered juttis, warm affectionate smile",
  ),
  CharacterRef(
    name: "Teacher",
    assetPath: "assets/characters/Teacher.jpg",
    description: "Indian school teacher, dark hair in a low bun with small white gajra flowers, warm tan skin, dark brown eyes, round gold-rimmed glasses, small red bindi, small gold earrings, blue three-quarter-sleeve kurta with white block-printed floral motifs, white leggings, blue juttis, holding a blue hardback book, encouraging smile",
  ),
];

class CharacterStore {
  static const _fileName = 'characters.json';
  static const _folder = 'character_faces';

  /// Loads the saved cast, seeding the defaults the first time the app runs.
  static Future<List<CharacterRef>> load() async {
    try {
      final file = await _indexFile();
      if (!await file.exists()) {
        await save(kDefaultCast);
        return List.of(kDefaultCast);
      }

      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return List.of(kDefaultCast);

      final saved = raw
          .whereType<Map<String, dynamic>>()
          .map(CharacterRef.fromJson)
          .where((c) => c.name.isNotEmpty)
          .toList();

      if (saved.isEmpty) return List.of(kDefaultCast);

      // A picture can go missing if the phone is wiped or the app reinstalled, so
      // check rather than hand back a path that points at nothing. The bundled face
      // is re-attached from the build by name, since it is not saved — that way a
      // character whose picked face has gone falls back to the shipped one instead
      // of showing an empty tile.
      final checked = <CharacterRef>[];
      for (final c in saved) {
        final stillThere = c.hasImage && await File(c.imagePath!).exists();
        final matches = kDefaultCast
            .where((d) => d.name.toLowerCase() == c.name.toLowerCase());
        final bundled = matches.isEmpty ? null : matches.first.assetPath;

        checked.add(CharacterRef(
          name: c.name,
          description: c.description,
          imagePath: stillThere ? c.imagePath : null,
          assetPath: bundled,
        ));
      }
      return checked;
    } catch (_) {
      // A corrupt index must not stop the app opening; start the cast again instead.
      return List.of(kDefaultCast);
    }
  }

  static Future<void> save(List<CharacterRef> cast) async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(cast.map((c) => c.toJson()).toList()));
  }

  /// Copies a picked image into permanent storage and returns its new path.
  ///
  /// An image_picker path lives in a cache the phone clears whenever it likes, so a
  /// reference kept there is gone by next week. Named after the character rather than
  /// given a unique name, so choosing a new face replaces the old one instead of
  /// leaving the phone collecting every picture ever picked.
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

  static Future<File> _indexFile() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');
}
