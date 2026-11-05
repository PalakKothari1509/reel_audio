import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_library_service.dart';
import 'package:reel_audio/idea_inbox_store.dart';
import 'package:reel_audio/json_file_store.dart';
import 'package:reel_audio/models/quick_idea.dart';
import 'package:reel_audio/plan_data.dart';
import 'package:reel_audio/story_generator_offline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'content_ideas_loader_test',
    );
    JsonFileStore.setTestDirectory(tempDir);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (call) async => tempDir.path,
        );
    ContentLibraryService.instance.invalidateCache();
  });

  tearDown(() async {
    ContentLibraryService.instance.invalidateCache();
    JsonFileStore.clearTestDirectory();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ContentLibraryService.loadBuiltInHooks', () {
    test('loads exactly 122 ideas from JSON', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      expect(hooks.length, 122);
    });

    test('all IDs are unique', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final ids = hooks.map((h) => h.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('IDs are idea_1 through idea_122 (with idea_117 at index 78)', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final expectedIds = <String>[];
      for (var i = 1; i <= 75; i++) expectedIds.add('idea_$i');
      expectedIds.addAll(['idea_76', 'idea_77', 'idea_78', 'idea_117', 'idea_79']);
      for (var i = 80; i <= 116; i++) expectedIds.add('idea_$i');
      expectedIds.addAll(['idea_118', 'idea_119', 'idea_120', 'idea_121', 'idea_122']);
      for (var i = 0; i < 122; i++) {
        expect(hooks[i].id, expectedIds[i]);
      }
    });

    test('idea_121 is the AI-only creator journey idea', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final idea = hooks.firstWhere((hook) => hook.id == 'idea_121');

      expect(idea.id, 'idea_121');
      expect(idea.readyPrompt, contains('AI-generated visuals only'));
      expect(idea.readyPrompt, contains('1,100 followers'));
    });

    test('idea_122 is the consolidated midnight-cuddle reel', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final idea = hooks.firstWhere((hook) => hook.id == 'idea_122');

      expect(idea.id, 'idea_122');
      expect(idea.title, contains('Cuddles'));
      expect(
        idea.opening,
        'Ria ki apni bed hai… par raat hote hi Mumma ki bed yaad aa jaati hai! 😂',
      );
      expect(idea.readyPrompt, contains('Scene 1 — Bedtime (0-5 sec)'));
      expect(idea.readyPrompt, contains('Scene 5 — Ending (25-30 sec)'));
      expect(idea.readyPrompt, contains('AI-generated animated visuals only'));
      expect(idea.readyPrompt, contains('Papa slowly opens one eye'));
      expect(
        idea.readyPrompt,
        contains('DIN BHAR APNI DUNIYA MEIN BUSY'),
      );
    });

    test('idea_117 remains at index 78', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      expect(hooks[78].id, 'idea_117');
    });

    test('archived IDs are idea_43, idea_44, idea_46', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final archived =
          hooks.where((h) => h.archived).map((h) => h.id).toSet();
      expect(
        archived,
        {'idea_43', 'idea_44', 'idea_46'},
      );
    });

    test('idea_41 and idea_42 are not archived', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final idea41 = hooks.firstWhere((h) => h.id == 'idea_41');
      final idea42 = hooks.firstWhere((h) => h.id == 'idea_42');
      expect(idea41.archived, isFalse);
      expect(idea42.archived, isFalse);
    });

    test('idea_120 is custom=true', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final idea120 = hooks.firstWhere((h) => h.id == 'idea_120');
      expect(idea120.custom, isTrue);
    });

    test('repeated loading returns the cached result', () async {
      final first = await ContentLibraryService.loadBuiltInHooks();
      final second = await ContentLibraryService.loadBuiltInHooks();
      expect(second.length, first.length);
      for (var i = 0; i < first.length; i++) {
        expect(second[i].id, first[i].id);
      }
    });

    test('ContentLibraryLoadException is a proper Exception', () {
      final exception = ContentLibraryLoadException('test error');
      expect(exception, isA<Exception>());
      expect(exception.toString(), contains('ContentLibraryLoadException'));
      expect(exception.toString(), contains('test error'));
    });

    test('user edits override built-in ideas via HookStore', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final original = hooks.first;
      final edited = original.copyWith(
        cover: 'User-edited cover',
        storyDetail: 'User-edited story detail',
      );
      await HookStore.save([edited]);

      final loadedHooks = await HookStore.load();
      final found = loadedHooks.firstWhere((h) => h.id == original.id);
      expect(found.cover, 'User-edited cover');
      expect(found.storyDetail, 'User-edited story detail');
    });

    test('Quick Ideas and Idea Inbox remain independent', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      expect(hooks.length, 122);

      final quickIdeas = await QuickIdeaStore.load();
      final inboxItems = await IdeaInboxStore.load();

      final quickIds = quickIdeas.map((q) => q.id).toSet();
      final inboxIds = inboxItems.map((i) => i.id).toSet();
      final hookIds = hooks.map((h) => h.id).toSet();

      expect(quickIds.intersection(hookIds), isEmpty);
      expect(inboxIds.intersection(hookIds), isEmpty);
    });

    test('offline story generation resolves built-in ideas by ID', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final idea = hooks.first;

      final generator = StoryGenerator();
      final story = await generator.generateFromIdea(ContentIdea(
        id: idea.id,
        title: idea.cover,
        category: idea.category,
        collectionId: '',
        format: idea.postFormat,
        problem: idea.problem,
        lesson: idea.lesson,
        opening: idea.opening,
        storyDetail: idea.storyDetail,
        characterIds: [],
        caption: idea.caption,
        isCustom: false,
        status: IdeaStatus.idea,
        notes: '',
        sourceType: 'HookIdea',
      ));

      expect(story, isNotNull);
    });
  });
}
