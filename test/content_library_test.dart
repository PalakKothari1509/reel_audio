import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_generator.dart';
import 'package:reel_audio/content_library.dart';
import 'package:reel_audio/format_adapter.dart';

/// Covers wiring a generated package into the content library.
///
/// The library was previously dead code: `ContentLibraryStore` had zero call sites in
/// the app, and `posting_pack.dart` showed "Content Library integration coming soon!"
/// on save. So a generated package could be produced, adapted into four formats, and
/// then never kept.
///
/// The store reads through `getApplicationDocumentsDirectory`, which is unavailable in
/// a test, so `useDirectory` redirects it at a temp folder. Without that seam there is
/// no way to distinguish "saved" from "silently failed".

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('content_library_test');
    ContentLibraryStore.useDirectory(tempDir);
  });

  tearDown(() async {
    ContentLibraryStore.resetDirectory();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ContentPackage samplePackage() {
    return ContentPackage(
      id: 'test-idea-1',
      idea: 'Ria refuses to brush her teeth',
      bucket: BucketLibrary.byId('activity') ?? BucketLibrary.all.first,
      format: ContentFormat.reel,
      characters: const [CharacterLibrary.ria, CharacterLibrary.mumma],
      hook: 'Brush nahi karungi!',
      slides: const [],
      visualPrompts: const ['Ria pushing the brush away'],
      caption: 'A one-line caption about brushing.',
      cta: 'Save this for tomorrow morning.',
      hashtags: const ['#toddlerbrush', '#screenfree'],
      pinnedComment: 'Which one is your morning battle?',
      replyComments: const ['Same here', 'Try the song trick'],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  // 1. A generated package saves successfully.
  test('a package can be saved into the library', () async {
    final item = ContentLibraryItem.createFromPackage(samplePackage());
    expect(await ContentLibraryStore.tryAdd(item), isTrue);

    final all = await ContentLibraryStore.getAll();
    expect(all, hasLength(1));
  });

  // 2. All four adapted formats are persisted.
  test('the saved item carries all four adapted format outputs', () async {
    final item = ContentLibraryItem.createFromPackage(samplePackage());
    await ContentLibraryStore.tryAdd(item);

    expect(item.formatOutputs, hasLength(4));
    for (final format in ContentFormat.values) {
      expect(
        item.formatOutputs.containsKey(format),
        isTrue,
        reason: 'missing output for ${format.name}',
      );
    }

    final reloaded = (await ContentLibraryStore.getAll()).single;
    expect(reloaded.formatOutputs.keys.toSet(), ContentFormat.values.toSet());
  });

  // 3. The entry contains the expected metadata and survives a round trip.
  test('metadata survives save and reload', () async {
    final pkg = samplePackage();
    final item = ContentLibraryItem.createFromPackage(pkg);
    await ContentLibraryStore.tryAdd(item);

    final reloaded = (await ContentLibraryStore.getAll()).single;
    expect(reloaded.topic, pkg.idea);
    expect(reloaded.contentPackage?.hook, pkg.hook);
    expect(reloaded.contentPackage?.hashtags, pkg.hashtags);
    expect(reloaded.contentPackage?.pinnedComment, pkg.pinnedComment);
    expect(reloaded.status, IdeaStatus.scripted);
    expect(reloaded.title, pkg.hook);
  });

  test('Instagram workflow metadata survives a library round trip', () async {
    final item = ContentLibraryItem.createFromPackage(
      samplePackage(),
      sourceIdeaId: 'approved-idea-7',
      workflowType: 'storiesSequence',
      workflowData: const {
        'editableText': 'FRAME 1\nTEXT: Try this',
        'scope': 'Account',
        'keywords': ['screen-free play', 'preschool'],
      },
      tags: const ['activity', 'instagram-workflow'],
      status: IdeaStatus.scripted,
    );
    await ContentLibraryStore.add(item);

    final reloaded = (await ContentLibraryStore.getAll()).single;
    expect(reloaded.id, item.id);
    expect(reloaded.sourceIdeaId, 'approved-idea-7');
    expect(reloaded.workflowType, 'storiesSequence');
    expect(reloaded.workflowData['editableText'], 'FRAME 1\nTEXT: Try this');
    expect(
      reloaded.workflowData['keywords'],
      ['screen-free play', 'preschool'],
    );
    expect(reloaded.tags, ['activity', 'instagram-workflow']);
  });

  // 4. A failed save is surfaced rather than reported as success.
  test('a failed write reports failure, not success', () async {
    ContentLibraryStore.resetDirectory();
    // Point the store at a path that cannot be created: a file where a directory
    // would need to be.
    final blocker = File('${tempDir.path}/blocked');
    await blocker.writeAsString('not a directory');
    ContentLibraryStore.useDirectory(Directory('${blocker.path}/nested'));

    final ok = await ContentLibraryStore.tryAdd(
      ContentLibraryItem.createFromPackage(samplePackage()),
    );

    expect(
      ok,
      isFalse,
      reason: 'a write that could not happen must not report success',
    );
  });

  // 5. Repeated saves follow the existing library behaviour: each is its own entry.
  test('saving twice creates two entries, and both can be removed', () async {
    final first = ContentLibraryItem.createFromPackage(samplePackage());
    // Same millisecond would collide on the id, so separate the two entries.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = ContentLibraryItem.createFromPackage(samplePackage());

    await ContentLibraryStore.tryAdd(first);
    await ContentLibraryStore.tryAdd(second);

    final all = await ContentLibraryStore.getAll();
    expect(all, hasLength(2));
    expect(all.map((i) => i.id).toSet(), hasLength(2));

    await ContentLibraryStore.delete(first.id);
    expect(await ContentLibraryStore.getAll(), hasLength(1));
  });

  // 6. The "coming soon" placeholder is gone from the save path.
  //
  // Checks the code, not the file. An earlier version of this test asserted the file
  // did not contain the phrase at all, which failed for the wrong reason: the save
  // method's own comment quotes the old snackbar to explain what it replaced.
  test('the save path calls the library instead of showing a placeholder', () async {
    final source = File('lib/posting_pack.dart').readAsStringSync();

    expect(source, contains('ContentLibraryStore.tryAdd'));
    expect(source, contains('ContentLibraryItem.createFromPackage'));

    // No SnackBar still announcing an unfinished integration.
    final placeholder = RegExp(
      r"SnackBar\(const SnackBar\(content: Text\('Content Library[^']*coming soon",
    );
    expect(placeholder.hasMatch(source), isFalse);
  });

  // Filters read the same store, so a saved item is discoverable.
  test('a saved item is retrievable through the store filters', () async {
    final item = ContentLibraryItem.createFromPackage(samplePackage());
    await ContentLibraryStore.tryAdd(item);

    expect(await ContentLibraryStore.getByStatus(IdeaStatus.scripted), hasLength(1));
    expect(await ContentLibraryStore.getById(item.id), isNotNull);
    expect(await ContentLibraryStore.getByFormat(item.format), hasLength(1));
  });

  // Old persisted data used different spellings; fromLegacy handles them.
  test('legacy status strings are migrated to canonical values on reload', () {
    final item = ContentLibraryItem(
      id: 'legacy-1',
      title: 'Legacy',
      topic: 'topic',
      bucket: BucketLibrary.challenge,
      format: ContentFormat.reel,
      status: IdeaStatus.tested,
      formatOutputs: const {},
      tags: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      reuseCount: 0,
      performanceMetrics: const {},
    );

    final roundTrip = ContentLibraryItem.fromJson(item.toJson());
    expect(roundTrip.status, IdeaStatus.tested);
  });

  test('legacy status strings in JSON migrate via fromLegacy', () {
    final json = {
      'id': 'legacy-2',
      'title': 'Legacy',
      'topic': 'topic',
      'bucket': 'challenge',
      'format': 'reel',
      'status': 'reused',
      'formatOutputs': {},
      'tags': [],
      'createdAt': '2026-01-01T00:00:00',
      'updatedAt': '2026-01-01T00:00:00',
      'performanceMetrics': {},
      'reuseCount': 0,
    };

    final item = ContentLibraryItem.fromJson(json);
    expect(item.status, IdeaStatus.tested);
    expect(item.workflowType, isNull);
    expect(item.workflowData, isEmpty);
  });

  test('QualitySeverity enum index is bounds-checked', () {
    // Simulate corrupted data with an invalid severity index.
    // Must not throw RangeError — the bounds check in _reportFromJson clamps it.
    final json = {
      'id': 'test-id',
      'title': 'Test',
      'topic': 'topic',
      'bucket': 'challenge',
      'format': 'reel',
      'status': 'idea',
      'formatOutputs': {},
      'tags': [],
      'createdAt': '2026-01-01T00:00:00',
      'updatedAt': '2026-01-01T00:00:00',
      'contentPackage': samplePackage().toJson(),
      'qualityReport': {
        'results': [
          {
            'ruleId': 'test-rule',
            'ruleName': 'Test Rule',
            'passed': false,
            'description': 'details',
            'severity': 99, // invalid index — must clamp
            'message': 'Test message',
          }
        ],
        'passCount': 0,
        'warnCount': 0,
        'failCount': 1,
        'score': 0.5,
        'isReadyToPost': false,
        'checkedAt': '2026-01-01T00:00:00',
      },
      'performanceMetrics': {},
      'reuseCount': 0,
    };

    final item = ContentLibraryItem.fromJson(json);
    expect(item.qualityReport, isNotNull);
    expect(item.qualityReport!.failCount, 1);
  });
}