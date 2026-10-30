import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/content_ideas.dart';
import 'package:reel_audio/content_library_service.dart';
import 'package:reel_audio/json_file_store.dart';
import 'package:reel_audio/plan_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'content_library_service_test',
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

  test(
    'persisted edits to a built-in idea win when the library reloads',
    () async {
      final original = kDefaultHooksWithRewrite.first;
      final edited = original.copyWith(
        cover: 'User-edited cover',
        category: 'User-edited category',
        opening: 'User-edited opening',
        problem: 'User-edited problem',
        lesson: 'User-edited lesson',
        caption: 'User-edited caption',
        storyDetail: 'User-edited story detail',
      );
      await HookStore.save([edited]);

      final library = ContentLibraryService.instance;
      final idea = await library.getIdeaById(original.id);

      expect(idea, isNotNull);
      expect(idea!.id, original.id);
      expect(idea.title, 'User-edited cover');
      expect(idea.category, 'User-edited category');
      expect(idea.opening, 'User-edited opening');
      expect(idea.problem, 'User-edited problem');
      expect(idea.lesson, 'User-edited lesson');
      expect(idea.caption, 'User-edited caption');
      expect(idea.storyDetail, 'User-edited story detail');

      library.invalidateCache();
      final reloaded = await library.getIdeaById(original.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.id, original.id);
      expect(reloaded.title, 'User-edited cover');
      expect(reloaded.category, 'User-edited category');
      expect(reloaded.opening, 'User-edited opening');
      expect(reloaded.problem, 'User-edited problem');
      expect(reloaded.lesson, 'User-edited lesson');
      expect(reloaded.caption, 'User-edited caption');
      expect(reloaded.storyDetail, 'User-edited story detail');
    },
  );
}
