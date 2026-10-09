import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/json_file_store.dart';

/// Simple model for testing JsonFileStore.
class TestItem {
  final String id;
  final String title;

  TestItem(this.id, this.title);

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        json['id'] as String,
        json['title'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem && runtimeType == other.runtimeType && id == other.id && title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

class TestStore extends JsonFileStore<TestItem> {
  TestStore(String fileName) : super(fileName);

  @override
  String idOf(TestItem item) => item.id;

  @override
  TestItem fromJson(Map<String, dynamic> json) => TestItem.fromJson(json);

  @override
  Map<String, dynamic> toJson(TestItem item) => item.toJson();
}

void main() {
  late TestStore store;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('json_filestore_test');
    JsonFileStore.setTestDirectory(tempDir);
    store = TestStore('test_items.json');
  });

  tearDown(() {
    JsonFileStore.clearTestDirectory();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('JsonFileStore', () {
    test('loadAll returns empty when file does not exist', () async {
      final items = await store.loadAll();
      expect(items, isEmpty);
    });

    test('saveAll writes items and loadAll reads them back', () async {
      final items = [TestItem('1', 'First'), TestItem('2', 'Second')];
      await store.saveAll(items);

      final loaded = await store.loadAll();
      expect(loaded, equals(items));
    });

    test('saveAll replaces existing file contents', () async {
      await store.saveAll([TestItem('1', 'Old')]);
      await store.saveAll([TestItem('2', 'New')]);

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, equals('2'));
    });

    test('loadAll skips corrupted rows but returns valid ones', () async {
      final file = File('${tempDir.path}/test_items.json');
      await file.writeAsString('[null, {"id":"1","title":"A"}, "junk", {"id":"2","title":"B"}]');

      final loaded = await store.loadAll();
      expect(loaded, hasLength(2));
      expect(loaded.map((i) => i.id), equals(['1', '2']));
    });

    test('loadAll returns empty for non-list JSON', () async {
      final file = File('${tempDir.path}/test_items.json');
      await file.writeAsString('{"not": "a list"}');

      final loaded = await store.loadAll();
      expect(loaded, isEmpty);
    });

    test('loadAll returns empty for empty file', () async {
      final file = File('${tempDir.path}/test_items.json');
      await file.writeAsString('');

      final loaded = await store.loadAll();
      expect(loaded, isEmpty);
    });

    test('loadById returns the matching item', () async {
      await store.saveAll([TestItem('1', 'A'), TestItem('2', 'B')]);
      final item = await store.loadById('2');
      expect(item, isNotNull);
      expect(item!.id, equals('2'));
      expect(item.title, equals('B'));
    });

    test('loadById returns null for nonexistent ID', () async {
      await store.saveAll([TestItem('1', 'A')]);
      final item = await store.loadById('999');
      expect(item, isNull);
    });

    test('add inserts item at the front', () async {
      await store.saveAll([TestItem('1', 'A')]);
      await store.add(TestItem('2', 'B'));

      final loaded = await store.loadAll();
      expect(loaded, hasLength(2));
      expect(loaded.first.id, equals('2'));
    });

    test('deleteById removes the matching item', () async {
      await store.saveAll([TestItem('1', 'A'), TestItem('2', 'B'), TestItem('3', 'C')]);
      await store.deleteById('2');

      final loaded = await store.loadAll();
      expect(loaded, hasLength(2));
      expect(loaded.map((i) => i.id), equals(['1', '3']));
    });

    test('loadAll with shouldKeep filters items', () async {
      final items = [TestItem('1', 'A'), TestItem('2', 'B'), TestItem('3', 'Skip')];
      await store.saveAll(items);

      final loaded = await store.loadAll(shouldKeep: (item) => item.id != '3');
      expect(loaded, hasLength(2));
    });
  });
}
