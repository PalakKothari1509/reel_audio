import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_audio/brand_system.dart';
import 'package:reel_audio/bucket_group.dart';
import 'package:reel_audio/content_library.dart';
import 'package:reel_audio/content_axes.dart';

void main() {
  group('groupItemsByBucket', () {
    test('items with known buckets are grouped by id', () {
      final items = [
        _item('id-1', BucketLibrary.activity),
        _item('id-2', BucketLibrary.humor),
        _item('id-3', BucketLibrary.activity),
      ];

      final groups = groupItemsByBucket(items, (i) => i.bucket.id);

      expect(groups, hasLength(2));
      expect(groups[0].bucketId, 'activity');
      expect(groups[0].items.map((i) => i.id).toSet(), {'id-1', 'id-3'});
      expect(groups[1].bucketId, 'humor');
      expect(groups[1].items.map((i) => i.id).toSet(), {'id-2'});
    });

    test('items with unknown bucket id go into "Other"', () {
      final items = [
        _item('id-1', BucketLibrary.challenge),
        _customBucketItem('id-2'),
      ];

      final groups = groupItemsByBucket(items, (i) => i.bucket.id);

      expect(groups, hasLength(2));
      expect(groups[0].bucketId, 'challenge');
      expect(groups[1].bucketId, 'other');
      expect(groups[1].items.map((i) => i.id).toSet(), {'id-2'});
    });

    test('preferred order puts challenge before humor', () {
      final items = [
        _item('h-1', BucketLibrary.humor),
        _item('c-1', BucketLibrary.challenge),
      ];

      final groups = groupItemsByBucket(items, (i) => i.bucket.id);

      final challengeIdx =
          groups.indexWhere((g) => g.bucketId == 'challenge');
      final humorIdx = groups.indexWhere((g) => g.bucketId == 'humor');
      expect(challengeIdx, lessThan(humorIdx));
    });

    test('empty list produces no groups', () {
      final groups = groupItemsByBucket([], (i) => '');
      expect(groups, isEmpty);
    });

    test('items from the same bucket are kept together in order', () {
      final items = [
        _item('a-1', BucketLibrary.activity),
        _item('h-1', BucketLibrary.humor),
        _item('a-2', BucketLibrary.activity),
      ];

      final groups = groupItemsByBucket(items, (i) => i.bucket.id);

      expect(groups[0].items, hasLength(2));
      expect(groups[0].items.map((i) => i.id).toList(), ['a-1', 'a-2']);
    });

    test('"Other" always comes last, even when it has items', () {
      final items = [
        _customBucketItem('id-1'),
        _item('id-2', BucketLibrary.challenge),
        _customBucketItem('id-3'),
      ];

      final groups = groupItemsByBucket(items, (i) => i.bucket.id);

      expect(groups.last.bucketId, 'other');
      expect(groups.last.items.map((i) => i.id).toSet(), {'id-1', 'id-3'});
    });
  });
}

ContentLibraryItem _item(String id, ContentBucket bucket) {
  return ContentLibraryItem(
    id: id,
    title: id,
    topic: 'topic',
    bucket: bucket,
    format: ContentFormat.reel,
    status: IdeaStatus.scripted,
    formatOutputs: const {},
    tags: const [],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    reuseCount: 0,
    performanceMetrics: const {},
  );
}

ContentLibraryItem _customBucketItem(String id) {
  return ContentLibraryItem(
    id: id,
    title: id,
    topic: 'topic',
    bucket: ContentBucket(
      id: 'custom-bucket',
      name: 'Custom',
      emoji: '🧪',
      shortLabel: 'Custom',
      description: 'Custom',
      generationPrompt: '',
      color: const Color(0xFF0000FF),
      softColor: const Color(0xFF0000FF),
      exampleHooks: [],
      slideTemplates: [],
    ),
    format: ContentFormat.reel,
    status: IdeaStatus.scripted,
    formatOutputs: const {},
    tags: const [],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    reuseCount: 0,
    performanceMetrics: const {},
  );
}
