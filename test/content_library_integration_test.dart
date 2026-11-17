import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_library_service.dart';
import 'package:reel_audio/json_file_store.dart';

/// Phase 3.1.4 / 3.1.5 — real asset-to-service integration tests.
///
/// These exercise the production [ContentLibraryService] against the actual
/// `assets/data/content_ideas.json` fixture (122 built-in ideas). No mocks and
/// no HookStore writes: the fixture is the single source of truth.

/// Builds a minimal valid [HookIdea] for validator testing.
HookIdea _buildHook({
  String id = 'idea_1',
  String category = 'Test',
  String cover = 'Cover',
  String opening = 'Opening',
  String problem = 'Problem',
  String lesson = 'Lesson',
  String title = 'Title',
  bool archived = false,
}) => HookIdea(
      id: id,
      category: category,
      cover: cover,
      opening: opening,
      problem: problem,
      lesson: lesson,
      title: title,
      postFormat: 'Reel',
      strategy: '',
      caption: '',
      pinnedComment: '',
      forApp: true,
      usedOn: '',
      custom: false,
      archived: archived,
      storyDetail: '',
      setting: '',
      sceneDetail: '',
      dialogue: '',
      mess: '',
      innerThought: '',
      endingBeat: '',
      defaultCast: ['Ria', 'Rio', 'Cuty'],
      keepMoralOffScreen: false,
      quote: '',
      detail: '',
      punchline: '',
      readyPrompt: '',
      score: 0,
      band: '',
      reviewedOn: '',
    );

/// Builds a list of 122 valid hooks (idea_1 through idea_122).
List<HookIdea> _buildValidHookList() => List.generate(122, (i) => _buildHook(id: 'idea_${i + 1}', archived: i + 1 == 43 || i + 1 == 44 || i + 1 == 46));

/// Builds a minimal valid JSON fixture for loadBuiltInHooks testing.
/// [overrides] maps index -> field overrides for specific items.
Map<String, dynamic> _buildJsonFixture({
  Map<int, Map<String, dynamic>> overrides = const {},
  int count = 122,
}) {
  final ideas = <Map<String, dynamic>>[];
  for (var i = 0; i < count; i++) {
    final idx = i + 1;
    final item = <String, dynamic>{
      'id': 'idea_$idx',
      'category': 'Test',
      'cover': 'Cover $idx',
      'opening': 'Opening $idx',
      'problem': 'Problem $idx',
      'lesson': 'Lesson $idx',
      'title': 'Title $idx',
      'postFormat': 'Reel',
      'strategy': '',
      'caption': '',
      'pinnedComment': '',
      'forApp': true,
      'usedOn': '',
      'custom': false,
      'archived': idx == 43 || idx == 44 || idx == 46,
      'storyDetail': '',
      'setting': '',
      'sceneDetail': '',
      'dialogue': '',
      'mess': '',
      'innerThought': '',
      'endingBeat': '',
      'defaultCast': ['Ria', 'Rio', 'Cuty'],
      'keepMoralOffScreen': false,
      'quote': '',
      'detail': '',
      'punchline': '',
      'readyPrompt': '',
      'score': 0,
      'band': '',
      'reviewedOn': '',
    };
    final override = overrides[i];
    if (override != null) {
      item.addAll(override);
    }
    ideas.add(item);
  }
  return {
    'version': '2.0.4',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'ideas': ideas,
  };
}

/// Runs loadBuiltInHooks against a temporary JSON fixture at the test CWD.
Future<List<HookIdea>> _validateViaLoadBuiltInHooks(
  Map<String, dynamic> fixture,
) async {
  final originalCwd = Directory.current;
  final testDir = await Directory.systemTemp.createTemp(
    'content_library_validator_test',
  );
  Directory.current = testDir;
  final testFile = File('assets/data/content_ideas.json');
  await testFile.create(recursive: true);
  await testFile.writeAsString(jsonEncode(fixture));
  addTearDown(() async {
    Directory.current = originalCwd;
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });
  return ContentLibraryService.loadBuiltInHooks();
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const assetChannel = MethodChannel('flutter/assets');
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'content_library_integration_test',
    );
    JsonFileStore.setTestDirectory(tempDir);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
    ContentLibraryService.clearAllCaches();
  });

  tearDown(() async {
    ContentLibraryService.clearAllCaches();
    JsonFileStore.clearTestDirectory();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 3.1.5 — validation edge cases', () {
    test('loadBuiltInHooks parses the real fixture into 122 unique ideas',
        () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();

      expect(hooks.length, 122);
      final ids = hooks.map((h) => h.id).toSet();
      expect(ids.length, 122);
      expect(ids.contains('idea_1'), isTrue);
      expect(ids.contains('idea_122'), isTrue);
    });

    test('loadBuiltInHooks marks the three retired ideas as archived', () async {
      final hooks = await ContentLibraryService.loadBuiltInHooks();
      final archived = hooks.where((h) => h.archived).map((h) => h.id).toSet();

      expect(archived, {'idea_43', 'idea_44', 'idea_46'});
    });

    test('loadBuiltInHooks returns an empty list when the asset cannot load',
        () async {
      // Force rootBundle to fail so the loader falls through to the filesystem,
      // then point the process at an empty directory so the file fallback also
      // misses. The loader must degrade to an empty list, not throw.
      final originalCwd = Directory.current;
      final emptyDir = await Directory.systemTemp.createTemp(
        'content_library_missing_asset',
      );
      Directory.current = emptyDir;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(assetChannel, (call) async {
        throw MissingPluginException('asset unavailable in test');
      });
      addTearDown(() async {
        Directory.current = originalCwd;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(assetChannel, null);
        if (await emptyDir.exists()) {
          await emptyDir.delete(recursive: true);
        }
      });

      final hooks = await ContentLibraryService.loadBuiltInHooks();

      expect(hooks, isEmpty);
    });

    test('loadBuiltInHooks falls back to empty on malformed JSON', () async {
      final originalCwd = Directory.current;
      final badDir = await Directory.systemTemp.createTemp(
        'content_library_bad_json',
      );
      Directory.current = badDir;
      final badFile = File('assets/data/content_ideas.json');
      await badFile.create(recursive: true);
      await badFile.writeAsString('{ this is not valid json');
      addTearDown(() async {
        Directory.current = originalCwd;
        if (await badDir.exists()) {
          await badDir.delete(recursive: true);
        }
      });

      final hooks = await ContentLibraryService.loadBuiltInHooks();

      expect(hooks, isEmpty);
    });

    test('validator rejects duplicate IDs', () {
      final hooks = _buildValidHookList();
      // Introduce duplicate: change idea_2 to idea_1
      hooks[1] = _buildHook(id: 'idea_1');
      expect(ContentLibraryService.validateJsonHooksForTest(hooks), isFalse);
    });

    test('validator rejects missing required IDs', () {
      final hooks = _buildValidHookList();
      // Remove idea_1 by changing it to an unexpected ID
      hooks[0] = _buildHook(id: 'unexpected_id');
      expect(ContentLibraryService.validateJsonHooksForTest(hooks), isFalse);
    });

    test('validator rejects empty IDs', () {
      final hooks = _buildValidHookList();
      hooks[0] = _buildHook(id: '');
      expect(ContentLibraryService.validateJsonHooksForTest(hooks), isFalse);
    });

    test('validator rejects non-sequential IDs (invalid format)', () {
      // The validator requires exactly the set {idea_1, ..., idea_122}.
      // Any deviation (wrong prefix, wrong number, missing numbers) fails.
      for (final invalidId in ['invalid_id', 'idea_abc', 'idea_0', 'idea_123']) {
        final hooks = _buildValidHookList();
        hooks[0] = _buildHook(id: invalidId);
        expect(ContentLibraryService.validateJsonHooksForTest(hooks), isFalse,
            reason: 'invalid ID "$invalidId" should be rejected');
      }
    });

    test('validator rejects wrong count', () {
      // Fewer than 122
      expect(ContentLibraryService.validateJsonHooksForTest(_buildValidHookList()..removeLast()), isFalse);
      // More than 122
      expect(ContentLibraryService.validateJsonHooksForTest(_buildValidHookList()..add(_buildHook(id: 'extra'))), isFalse);
      // Empty
      expect(ContentLibraryService.validateJsonHooksForTest([]), isFalse);
    });

    test('validator accepts valid sequential fixture', () {
      final hooks = _buildValidHookList();
      expect(ContentLibraryService.validateJsonHooksForTest(hooks), isTrue);
    });

    test('JSON parsing rejects missing required field: category', () async {
      final fixture = _buildJsonFixture(overrides: {0: {'category': ''}});
      final hooks = await _validateViaLoadBuiltInHooks(fixture);
      expect(hooks, isEmpty);
    });

    test('JSON parsing rejects missing required field: cover', () async {
      final fixture = _buildJsonFixture(overrides: {0: {'cover': ''}});
      final hooks = await _validateViaLoadBuiltInHooks(fixture);
      expect(hooks, isEmpty);
    });

    test('JSON parsing rejects missing required field: opening', () async {
      final fixture = _buildJsonFixture(overrides: {0: {'opening': ''}});
      final hooks = await _validateViaLoadBuiltInHooks(fixture);
      expect(hooks, isEmpty);
    });

    test('JSON parsing rejects missing required field: problem', () async {
      final fixture = _buildJsonFixture(overrides: {0: {'problem': ''}});
      final hooks = await _validateViaLoadBuiltInHooks(fixture);
      expect(hooks, isEmpty);
    });

    test('JSON parsing rejects missing required field: lesson', () async {
      final fixture = _buildJsonFixture(overrides: {0: {'lesson': ''}});
      final hooks = await _validateViaLoadBuiltInHooks(fixture);
      expect(hooks, isEmpty);
    });

    test('JSON parsing rejects missing required field: id', () async {
      final fixture = _buildJsonFixture(overrides: {0: {'id': ''}});
      final hooks = await _validateViaLoadBuiltInHooks(fixture);
      expect(hooks, isEmpty);
    });
  });

  group('Phase 3.1.4 — real asset-to-service', () {
    test('getAllIdeas returns every built-in idea as a ContentIdea', () async {
      final ideas = await ContentLibraryService.instance.getAllIdeas();

      expect(ideas.length, 122);
      expect(ideas.every((i) => i.sourceType == 'HookIdea'), isTrue);
      // Three fixture ideas carry custom=true (idea_120..idea_122); the rest
      // are built-in. Both paths must surface through getAllIdeas.
      expect(ideas.where((i) => !i.isCustom).length, 119);
    });

    test('getIdeaById finds a built-in idea by id', () async {
      final idea = await ContentLibraryService.instance.getIdeaById('idea_1');

      expect(idea, isNotNull);
      expect(idea!.id, 'idea_1');
      expect(idea.title, isNotEmpty);
      expect(idea.opening, isNotEmpty);
      expect(idea.problem, isNotEmpty);
      expect(idea.lesson, isNotEmpty);
    });

    test('getIdeaById returns null for an unknown id', () async {
      final idea =
          await ContentLibraryService.instance.getIdeaById('does_not_exist');

      expect(idea, isNull);
    });

    test('searchIdeas matches on title, opening, problem or lesson', () async {
      final all = await ContentLibraryService.instance.getAllIdeas();
      final target = all.first;
      final needle = target.title;

      final results = await ContentLibraryService.instance.searchIdeas(needle);

      expect(results, isNotEmpty);
      expect(results.any((i) => i.id == target.id), isTrue);
    });

    test('searchIdeas with an empty query returns the full library', () async {
      final all = await ContentLibraryService.instance.getAllIdeas();
      final results = await ContentLibraryService.instance.searchIdeas('');

      expect(results.length, all.length);
    });

    test('getIdeasByCategory filters the real library', () async {
      final all = await ContentLibraryService.instance.getAllIdeas();
      final category = all.first.category;

      final results =
          await ContentLibraryService.instance.getIdeasByCategory(category);

      expect(results, isNotEmpty);
      expect(results.every((i) => i.category == category), isTrue);
    });

    test('getCategories and getCollections are non-empty and sorted', () async {
      final categories = await ContentLibraryService.instance.getCategories();
      final collections = await ContentLibraryService.instance.getCollections();

      expect(categories, isNotEmpty);
      expect(categories, orderedEquals(categories.toList()..sort()));
      expect(collections, isNotEmpty);
      expect(collections, orderedEquals(collections.toList()..sort()));
    });

    test('getRelatedIdeas returns other ideas from the same collection/category',
        () async {
      final all = await ContentLibraryService.instance.getAllIdeas();
      final target = all.first;

      final related =
          await ContentLibraryService.instance.getRelatedIdeas(target.id);

      expect(related, isNotEmpty);
      expect(related.every((i) => i.id != target.id), isTrue);
    });
  });
}