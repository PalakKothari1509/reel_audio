import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/character_definitions.dart';
import 'package:reel_audio/characters.dart';
import 'package:reel_audio/json_file_store.dart';

void main() {
  group('canonical character definitions', () {
    test(
      'compatibility lists and prompt descriptions derive from definitions',
      () {
        expect(kCharacterOptions, hasLength(kCharacterDefinitions.length));
        expect(kCharacterNames, hasLength(kCharacterDefinitions.length));
        expect(kDefaultCast, hasLength(kCharacterDefinitions.length));

        for (final definition in kCharacterDefinitions) {
          final option = kCharacterOptions.singleWhere(
            (item) => item.id == definition.id,
          );
          final reference = kDefaultCast.singleWhere(
            (item) => item.name == definition.name,
          );

          expect(option.name, definition.name);
          expect(option.emoji, definition.emoji);
          expect(
            characterDescription(definition.name),
            definition.imagePromptDescription,
          );
          expect(reference.description, definition.referenceDescription);
          expect(reference.assetPath, definition.assetPath);
        }
      },
    );

    test('default generation cast remains unchanged', () {
      expect(CharacterLibrary.all.map((character) => character.id), [
        'ria',
        'rio',
        'cuty',
        'mumma',
        'papa',
      ]);
      expect(CharacterLibrary.characterLockBlock, isNot(contains('Robot')));
      expect(CharacterLibrary.characterLockBlock, isNot(contains('Daadi')));
      expect(CharacterLibrary.characterLockBlock, isNot(contains('Teacher')));
      expect(
        CharacterLibrary.mumma.speechPattern,
        'Calm Hinglish, encouraging, warm. Soft terms of endearment such as '
        '"arre mera bachha" and "dekho toh". Never scolding, never impatient.',
      );
      expect(
        CharacterLibrary.ria.appearance,
        'Dark brown hair in two ponytails with pink bows, brown eyes, pink dress, '
        'no glasses, preschool age (3-4). Toofani: round chubby cheeks and a soft '
        'plump build, not thin',
      );
    });

    test('Robot is selectable and its bundled face is registered', () {
      final robot = kDefaultCast.singleWhere(
        (character) => character.name == 'Robot',
      );
      expect(robot.assetPath, 'assets/characters/Robot.jpg');
      expect(CharacterLibrary.byId('robot'), same(CharacterLibrary.robot));
      expect(characterDescription('Robot'), isNotEmpty);
      expect(File(robot.assetPath!).existsSync(), isTrue);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/characters/Robot.jpg'),
      );
    });
  });

  group('CharacterStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('character_store_test');
      JsonFileStore.setTestDirectory(tempDir);
    });

    tearDown(() async {
      JsonFileStore.clearTestDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'adds new canonical characters without replacing saved references',
      () async {
        const savedRia = CharacterRef(
          name: 'Ria',
          description: 'User-preserved Ria description',
        );
        await CharacterStore.save([savedRia]);

        final loaded = await CharacterStore.load();
        final ria = loaded.singleWhere((character) => character.name == 'Ria');
        final robot = loaded.singleWhere(
          (character) => character.name == 'Robot',
        );

        expect(ria.description, 'User-preserved Ria description');
        expect(robot.assetPath, 'assets/characters/Robot.jpg');
        expect(
          loaded.map((character) => character.name).toSet(),
          containsAll(kCharacterNames),
        );
      },
    );
  });
}
