import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_package_v2.dart';
import 'package:reel_audio/content_quality_gate.dart';
import 'package:reel_audio/package_store.dart';
import 'package:reel_audio/package_store_impl.dart';

void main() {
  late Directory tempDir;
  late PackageStoreFile store;
  late String filePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('package_store_test');
    filePath = '${tempDir.path}/packages.json';
    store = PackageStoreFile(filePath);
  });

  tearDown(() async {
    store = PackageStoreFile('');
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ContentPackageV2 samplePackage(String id, String ideaId) {
    return ContentPackageV2(
      id: id,
      ideaId: ideaId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      classification: ClassificationSnapshotV2(
        status: IdeaStatus.approved,
        axisStates: const {},
        capturedAt: DateTime(2025, 1, 1),
      ),
      audience: 'Parents',
      problem: 'Socks missing',
      lesson: 'Check under bed',
      hook: 'Where are your socks?',
      voiceMode: VoiceMode.required,
      cta: 'Save for later',
      reachCandidacy: ReachCandidacy.yes,
      productionCompatibility: ProductionCompatibility.yes,
      title: 'The Sock Hunt',
      script: 'Script here',
      narration: 'Narration here',
      dialogue: 'Dialogue here',
      caption: 'Caption text',
      hashtags: ['#parenting'],
      scenes: [
        Scene(
          index: 0,
          title: 'The Mystery',
          description: 'Socks missing',
          visualPrompt: 'child looking under bed',
          narration: 'Where are socks?',
          dialogue: 'Cuty: I hid them!',
          durationSeconds: 3,
        ),
      ],
      productionMethod: ProductionMethod.characterImages,
      shotList: [],
      imagePrompts: ['child looking under bed'],
    );
  }

  group('PackageStoreFile', () {
    test('isReady is true by default', () {
      expect(store.isReady, isTrue);
    });

    test('storeName returns correct name', () {
      expect(store.storeName, 'PackageStoreFile');
    });
  });

  group('save + loadById round-trip', () {
    test('saving then loading returns the exact package', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      await store.save(pkg);

      final loaded = await store.loadById('pkg-1');
      expect(loaded, isNotNull);
      expect(loaded!.id, 'pkg-1');
      expect(loaded.ideaId, 'idea-1');
      expect(loaded.hook, 'Where are your socks?');
      expect(loaded.narration, 'Narration here');
      expect(loaded.dialogue, 'Dialogue here');
      expect(loaded.caption, 'Caption text');
      expect(loaded.hashtags, ['#parenting']);
      expect(loaded.classification.narrativeFormatName, isNull);
    });

    test('saving twice replaces the old version', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      await store.save(pkg);

      final updated = pkg.copyWith(
        hook: 'Updated hook',
        updatedAt: DateTime(2025, 1, 2),
      );
      await store.save(updated);

      final loaded = await store.loadById('pkg-1');
      expect(loaded!.hook, 'Updated hook');
    });

    test('loadById returns null for nonexistent ID', () async {
      final loaded = await store.loadById('nonexistent');
      expect(loaded, isNull);
    });
  });

  group('trySave', () {
    test('returns success with package ID', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      final result = await store.trySave(pkg);
      expect(result.isSuccess, isTrue);
      expect(result.packageId, 'pkg-1');
    });
  });

  group('loadAll + PackageQuery', () {
    setUp(() async {
      // Seed with packages from different ideas
      await store.save(samplePackage('pkg-1', 'idea-a'));
      await store.save(samplePackage('pkg-2', 'idea-a'));
      await store.save(samplePackage('pkg-3', 'idea-b'));
    });

    test('loadAllPackages returns all packages', () async {
      final all = await store.loadAllPackages();
      expect(all.length, 3);
    });

    test('query by ideaId returns only matching packages', () async {
      final matching = await store.loadAll(const PackageQuery(ideaId: 'idea-a'));
      expect(matching.length, 2);
      expect(matching.every((p) => p.ideaId == 'idea-a'), isTrue);
    });

    test('query by ideaId returns empty for unknown idea', () async {
      final matching = await store.loadAll(const PackageQuery(ideaId: 'unknown'));
      expect(matching, isEmpty);
    });

    test('query by id returns specific package', () async {
      final matching = await store.loadAll(const PackageQuery(id: 'pkg-2'));
      expect(matching.length, 1);
      expect(matching.first.id, 'pkg-2');
    });
  });

  group('delete', () {
    test('delete returns true when package exists', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      await store.save(pkg);

      final deleted = await store.delete('pkg-1');
      expect(deleted, isTrue);
      expect(await store.loadById('pkg-1'), isNull);
    });

    test('delete returns false when package does not exist', () async {
      final deleted = await store.delete('nonexistent');
      expect(deleted, isFalse);
    });

    test('deleting one does not affect others', () async {
      await store.save(samplePackage('pkg-1', 'idea-a'));
      await store.save(samplePackage('pkg-2', 'idea-b'));

      await store.delete('pkg-1');

      final remaining = await store.loadAllPackages();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'pkg-2');
    });
  });

  group('update', () {
    test('update modifies existing package', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      await store.save(pkg);

      final updated = pkg.copyWith(
        hook: 'Updated hook',
        narration: 'Updated narration',
      );
      await store.update(updated);

      final loaded = await store.loadById('pkg-1');
      expect(loaded!.hook, 'Updated hook');
      expect(loaded.narration, 'Updated narration');
    });

    test('update throws StoreFailure for nonexistent package', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      expect(() => store.update(pkg), throwsA(isA<StoreFailure>()));
    });
  });

  group('updateStatus', () {
    test('updates status without changing package content', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      await store.save(pkg);

      await store.updateStatus('pkg-1', PackageStatus.videoBuilt);

      final metadata = await store.loadMetadata('pkg-1');
      expect(metadata!.status, PackageStatus.videoBuilt);
    });

    test('updateStatus throws StoreFailure for nonexistent package', () async {
      expect(
        () => store.updateStatus('nonexistent', PackageStatus.posted),
        throwsA(isA<StoreFailure>()),
      );
    });
  });

  group('count', () {
    test('returns 0 for empty store', () async {
      expect(await store.count(), 0);
    });

    test('returns total count without query', () async {
      await store.save(samplePackage('pkg-1', 'idea-a'));
      await store.save(samplePackage('pkg-2', 'idea-a'));
      await store.save(samplePackage('pkg-3', 'idea-b'));

      expect(await store.count(), 3);
    });

    test('returns filtered count with query', () async {
      await store.save(samplePackage('pkg-1', 'idea-a'));
      await store.save(samplePackage('pkg-2', 'idea-a'));
      await store.save(samplePackage('pkg-3', 'idea-b'));

      expect(await store.count(query: const PackageQuery(ideaId: 'idea-a')), 2);
    });
  });

  group('persistence across instances', () {
    test('packages survive store re-creation', () async {
      final pkg = samplePackage('pkg-1', 'idea-1');
      await store.save(pkg);

      final newStore = PackageStoreFile(filePath);
      final loaded = await newStore.loadById('pkg-1');
      expect(loaded, isNotNull);
      expect(loaded!.ideaId, 'idea-1');
    });

    test('directory is created if it does not exist', () async {
      final nestedPath = '${tempDir.path}/nested/deep/packages.json';
      final nestedStore = PackageStoreFile(nestedPath);
      final pkg = samplePackage('pkg-1', 'idea-1');

      await nestedStore.save(pkg);
      final loaded = await nestedStore.loadById('pkg-1');
      expect(loaded, isNotNull);
    });
  });

  group('corrupted file resilience', () {
    test('loadAllPackages returns empty for non-JSON file', () async {
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString('not json at all');

      final packages = await store.loadAllPackages();
      expect(packages, isEmpty);
    });

    test('loadAllPackages returns empty for non-list JSON', () async {
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString('{"not": "a list"}');

      final packages = await store.loadAllPackages();
      expect(packages, isEmpty);
    });

    test('loadAllPackages returns empty when file is missing', () async {
      final packages = await store.loadAllPackages();
      expect(packages, isEmpty);
    });
  });

  group('PackageMetadata', () {
    test('defaults status to generated', () {
      final meta = PackageMetadata(id: 'x', ideaId: 'y');
      expect(meta.status, PackageStatus.generated);
      expect(meta.videoPath, isNull);
      expect(meta.imagePaths, isEmpty);
    });

    test('copyWith updates status', () {
      final meta = PackageMetadata(id: 'x', ideaId: 'y');
      final updated = meta.copyWith(status: PackageStatus.videoBuilt);
      expect(updated.status, PackageStatus.videoBuilt);
      expect(meta.status, PackageStatus.generated);
    });

    test('copyWith updates video path', () {
      final meta = PackageMetadata(id: 'x', ideaId: 'y');
      final updated = meta.copyWith(videoPath: '/path/to/video.mp4');
      expect(updated.videoPath, '/path/to/video.mp4');
    });

    test('JSON round-trip preserves all fields', () {
      final meta = PackageMetadata(
        id: 'pkg-1',
        ideaId: 'idea-1',
        status: PackageStatus.posted,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        videoPath: '/video.mp4',
        audioPath: '/audio.wav',
        imagePaths: ['/img1.png', '/img2.png'],
      );
      final json = meta.toJson();
      final restored = PackageMetadata.fromJson(json);

      expect(restored.id, 'pkg-1');
      expect(restored.ideaId, 'idea-1');
      expect(restored.status, PackageStatus.posted);
      expect(restored.videoPath, '/video.mp4');
      expect(restored.audioPath, '/audio.wav');
      expect(restored.imagePaths, ['/img1.png', '/img2.png']);
    });
  });

  group('PackageStatus', () {
    test('has correct label for each value', () {
      expect(PackageStatus.generated.label, 'Generated');
      expect(PackageStatus.videoBuilt.label, 'Video Built');
      expect(PackageStatus.posted.label, 'Posted');
    });
  });

  group('StoreResult', () {
    test('success result has correct fields', () {
      final r = StoreResult.success('pkg-1');
      expect(r.isSuccess, isTrue);
      expect(r.packageId, 'pkg-1');
      expect(r.error, isNull);
    });

    test('failure result wraps StoreFailure', () {
      final f = StoreFailure('disk full');
      final r = StoreResult.failure(f);
      expect(r.isSuccess, isFalse);
      expect(r.error, same(f));
    });

    test('info result carries message', () {
      final r = StoreResult.info('saved');
      expect(r.isSuccess, isTrue);
      expect(r.message, 'saved');
    });
  });

  group('PackageQuery', () {
    test('copyWith returns copy with updated fields', () {
      final q1 = const PackageQuery(ideaId: 'a');
      final q2 = q1.copyWith(ideaId: 'b');
      expect(q2.ideaId, 'b');
    });

    test('copyWith can clear fields by passing null', () {
      final q1 = const PackageQuery(ideaId: 'a');
      final q2 = q1.copyWith(ideaId: null);
      expect(q2.ideaId, isNull);
    });
  });
}
