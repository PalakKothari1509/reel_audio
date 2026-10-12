import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/content_axes.dart';
import 'package:reel_audio/content_service.dart';
import 'package:reel_audio/content_library.dart';
import 'package:reel_audio/quick_content.dart';

void main() {
  group('ContentService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('content_service_test');
      ContentLibraryStore.useDirectory(tempDir);
    });

    tearDown(() {
      ContentLibraryStore.resetDirectory();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('saveIdea creates a ContentLibraryItem visible in getAllItems', () async {
      final item = await ContentService.saveIdea(
        title: 'Rio Says Nahi',
        topic: 'Rio refuses to brush teeth',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );

      expect(item.title, 'Rio Says Nahi');
      expect(item.status, IdeaStatus.idea);

      final all = await ContentService.getAllItems();
      expect(all.length, 1);
      expect(all.first.id, item.id);
    });

    test('saveIdea stores bucket id in tags', () async {
      final item = await ContentService.saveIdea(
        title: 'Test',
        topic: 'Test topic',
        bucket: BucketLibrary.activity,
        status: IdeaStatus.idea,
      );

      expect(item.tags, contains('activity'));
    });

    test('saveIdea with notes includes notes in tags', () async {
      final item = await ContentService.saveIdea(
        title: 'Test',
        topic: 'Test topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
        notes: 'Needs child safety review',
      );

      expect(item.tags, contains('Needs child safety review'));
    });

    test('saveIdea with sourceIdeaId preserves traceability', () async {
      final item = await ContentService.saveIdea(
        title: 'Variation',
        topic: 'Same topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
        sourceIdeaId: 'original-id',
      );

      expect(item.sourceIdeaId, 'original-id');
    });

    test('syncInboxItem creates library item from inbox item', () async {
      final inboxItem = IdeaInboxItem(
        id: 'inbox-1',
        title: 'From Inbox',
        rawIdea: 'Baby distracts during aarti',
        bucketId: 'challenge',
        notes: '',
        status: IdeaStatus.idea,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await IdeaInboxStore.add(inboxItem);
      final synced = await ContentService.syncInboxItem(inboxItem);

      expect(synced.title, 'From Inbox');
      expect(synced.topic, 'Baby distracts during aarti');
      expect(synced.sourceIdeaId, 'inbox-1');
      expect(synced.status, IdeaStatus.idea);
    });

    test('syncInboxItem is idempotent', () async {
      final inboxItem = IdeaInboxItem(
        id: 'inbox-2',
        title: 'Dup Check',
        rawIdea: 'Test idea',
        bucketId: 'activity',
        notes: '',
        status: IdeaStatus.idea,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await IdeaInboxStore.add(inboxItem);
      final first = await ContentService.syncInboxItem(inboxItem);
      final second = await ContentService.syncInboxItem(inboxItem);

      expect(first.id, second.id);
      expect(first.title, second.title);
    });

    test('syncAllInboxItems migrates all inbox items', () async {
      final item1 = IdeaInboxItem(
        id: 'inbox-a',
        title: 'Idea A',
        rawIdea: 'Topic A',
        bucketId: 'challenge',
        notes: '',
        status: IdeaStatus.idea,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final item2 = IdeaInboxItem(
        id: 'inbox-b',
        title: 'Idea B',
        rawIdea: 'Topic B',
        bucketId: 'activity',
        notes: '',
        status: IdeaStatus.idea,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await IdeaInboxStore.add(item1);
      await IdeaInboxStore.add(item2);

      final synced = await ContentService.syncAllInboxItems();
      expect(synced, 2);

      final all = await ContentService.getAllItems();
      expect(all.length, 2);
    });

    test('getItemsByStatus filters correctly', () async {
      await ContentService.saveIdea(
        title: 'Idea A',
        topic: 'Topic A',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );
      await ContentService.saveIdea(
        title: 'Idea B',
        topic: 'Topic B',
        bucket: BucketLibrary.activity,
        status: IdeaStatus.approved,
      );

      final ideas = await ContentService.getItemsByStatus(IdeaStatus.idea);
      final approved = await ContentService.getItemsByStatus(IdeaStatus.approved);

      expect(ideas.length, 1);
      expect(approved.length, 1);
    });

    test('updateStatus changes the item status', () async {
      final item = await ContentService.saveIdea(
        title: 'Test',
        topic: 'Topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );

      await ContentService.updateStatus(item.id, IdeaStatus.generated);

      final updated = await ContentService.getAllItems();
      expect(updated.first.status, IdeaStatus.generated);
    });

    test('updateStatus with postedAt sets posting fields', () async {
      final item = await ContentService.saveIdea(
        title: 'Test',
        topic: 'Topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );

      final postTime = DateTime(2024, 3, 15);
      await ContentService.updateStatus(
        item.id,
        IdeaStatus.posted,
        postedAt: postTime,
        instagramUrl: 'https://instagram.com/p/abc123',
      );

      final updated = await ContentService.getAllItems();
      expect(updated.first.status, IdeaStatus.posted);
      expect(updated.first.postedAt, postTime);
      expect(updated.first.instagramPostUrl, 'https://instagram.com/p/abc123');
    });

    test('recordMetrics stores performance data', () async {
      final item = await ContentService.saveIdea(
        title: 'Test',
        topic: 'Topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.posted,
      );

      await ContentService.recordMetrics(item.id, {
        'reach': 1500,
        'nonFollowerReach': 300,
        'saves': 42,
        'shares': 18,
      });

      final all = await ContentService.getAllItems();
      final metrics = all.first.performanceMetrics;
      expect(metrics['reach'], 1500);
      expect(metrics['nonFollowerReach'], 300);
      expect(metrics['saves'], 42);
      expect(metrics['shares'], 18);
    });

    test('recordMetrics merges into existing metrics', () async {
      final item = await ContentService.saveIdea(
        title: 'Test',
        topic: 'Topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.posted,
      );

      await ContentService.recordMetrics(item.id, {'reach': 100, 'saves': 5});
      await ContentService.recordMetrics(item.id, {'reach': 150, 'shares': 3});

      final all = await ContentService.getAllItems();
      final metrics = all.first.performanceMetrics;
      expect(metrics['reach'], 150);
      expect(metrics['saves'], 5);
      expect(metrics['shares'], 3);
    });

    test('findDuplicates finds exact title match', () async {
      final existing = await ContentService.saveIdea(
        title: 'Rio Says Nahi',
        topic: 'Teeth brushing resistance',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );

      final dupes = await ContentService.findDuplicates(
        'rio says nahi',
        'some other topic',
      );

      expect(dupes.length, 1);
      expect(dupes.first.id, existing.id);
    });

    test('findDuplicates finds similar topic match', () async {
      final existing = await ContentService.saveIdea(
        title: 'Title A',
        topic: 'child refuses to brush teeth every night',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );

      final dupes = await ContentService.findDuplicates(
        'Different Title',
        'child refuses to brush teeth every night',
      );

      expect(dupes.length, 1);
      expect(dupes.first.id, existing.id);
    });

    test('findDuplicates returns empty for unique idea', () async {
      await ContentService.saveIdea(
        title: 'Existing Idea',
        topic: 'totally different topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );

      final dupes = await ContentService.findDuplicates(
        'New Unique Idea',
        'completely unrelated topic',
      );

      expect(dupes, isEmpty);
    });

    test('deleteItem removes from both inbox and library', () async {
      final item = await ContentService.saveIdea(
        title: 'Test',
        topic: 'Topic',
        bucket: BucketLibrary.challenge,
        status: IdeaStatus.idea,
      );

      final inboxItem = IdeaInboxItem(
        id: item.id,
        title: 'Test',
        rawIdea: 'Topic',
        bucketId: 'challenge',
        notes: '',
        status: IdeaStatus.idea,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await IdeaInboxStore.add(inboxItem);

      await ContentService.deleteItem(item.id);

      final libraryItems = await ContentService.getAllItems();
      expect(libraryItems, isEmpty);

      final inboxItems = await IdeaInboxStore.load();
      expect(inboxItems, isEmpty);
    });

    test('getStatusCounts returns counts per status', () async {
      await ContentService.saveIdea(title: 'A', topic: 'T', bucket: BucketLibrary.challenge, status: IdeaStatus.idea);
      await ContentService.saveIdea(title: 'B', topic: 'T', bucket: BucketLibrary.challenge, status: IdeaStatus.idea);
      await ContentService.saveIdea(title: 'C', topic: 'T', bucket: BucketLibrary.challenge, status: IdeaStatus.approved);

      final counts = await ContentService.getStatusCounts();

      expect(counts[IdeaStatus.idea], 2);
      expect(counts[IdeaStatus.approved], 1);
    });

    test('getBucketCounts returns counts per bucket', () async {
      await ContentService.saveIdea(title: 'A', topic: 'T', bucket: BucketLibrary.challenge, status: IdeaStatus.idea);
      await ContentService.saveIdea(title: 'B', topic: 'T', bucket: BucketLibrary.challenge, status: IdeaStatus.idea);
      await ContentService.saveIdea(title: 'C', topic: 'T', bucket: BucketLibrary.activity, status: IdeaStatus.idea);

      final counts = await ContentService.getBucketCounts();

      expect(counts[BucketLibrary.challenge], 2);
      expect(counts[BucketLibrary.activity], 1);
    });
  });
}
