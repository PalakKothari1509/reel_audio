import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/idea_inbox_store.dart';
import 'package:reel_audio/json_file_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('idea_inbox_store_test');
    JsonFileStore.setTestDirectory(tempDir);
  });

  tearDown(() async {
    JsonFileStore.clearTestDirectory();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'loads existing inbox JSON with its original fields and status',
    () async {
      final existingJson = {
        'id': 'inbox-legacy-1',
        'title': 'A saved idea',
        'rawIdea': 'Keep the saved inbox data',
        'bucketId': 'activity',
        'notes': 'Do not lose these notes',
        'status': 'reused',
        'createdAt': '2025-03-04T10:11:12.000',
        'updatedAt': '2025-03-05T13:14:15.000',
      };
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}idea_inbox.json',
      );
      await file.writeAsString(jsonEncode([existingJson]));

      final item = (await IdeaInboxStore.load()).single;

      expect(item.id, 'inbox-legacy-1');
      expect(item.title, 'A saved idea');
      expect(item.rawIdea, 'Keep the saved inbox data');
      expect(item.bucketId, 'activity');
      expect(item.notes, 'Do not lose these notes');
      expect(item.status, IdeaStatus.tested);
      expect(item.createdAt, DateTime(2025, 3, 4, 10, 11, 12));
      expect(item.updatedAt, DateTime(2025, 3, 5, 13, 14, 15));
    },
  );

  test('writes and reloads the established inbox JSON shape', () async {
    final item = IdeaInboxItem(
      id: 'inbox-1',
      title: 'Saved idea',
      rawIdea: 'Existing format',
      bucketId: 'activity',
      notes: 'Keep',
      status: IdeaStatus.idea,
      createdAt: DateTime(2025, 3, 4, 10, 11, 12),
      updatedAt: DateTime(2025, 3, 5, 13, 14, 15),
    );

    await IdeaInboxStore.save([item]);

    final file = File(
      '${tempDir.path}${Platform.pathSeparator}idea_inbox.json',
    );
    final stored =
        (jsonDecode(await file.readAsString()) as List).single
            as Map<String, dynamic>;
    expect(stored.keys.toSet(), {
      'id',
      'title',
      'rawIdea',
      'bucketId',
      'notes',
      'status',
      'createdAt',
      'updatedAt',
    });
    expect((await IdeaInboxStore.load()).single.toJson(), item.toJson());
  });
}
