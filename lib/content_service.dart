// ContentService — unified service layer for idea creation, library management,
// and content-package generation.
//
// This is the single entry point that ensures the "Idea Vault" workflow
// writes to the canonical Content Library. Previously, adding an idea to
// the IdeaVaultScreen saved to IdeaInboxStore (idea_inbox.json) while the
// Content Library (content_library.json) remained a separate, disconnected
// store. ContentService bridges them so a saved idea is immediately visible
// in both views of the same canonical library.

import 'brand_system.dart';
import 'content_axes.dart';
import 'content_generator.dart';
import 'content_library.dart';
import 'quick_content.dart';

/// A unified service that coordinates IdeaVault, ContentLibraryStore,
/// and content-package creation in one place.
class ContentService {
  /// Returns all items in the canonical Content Library.
  ///
  /// The Content Library IS the source of truth. It stores ideas that have
  /// been captured, ideas that have been generated into packages, and
  /// published content — each as a ContentLibraryItem with a status,
  /// performance metrics, and optional link back to the originating idea.
  static Future<List<ContentLibraryItem>> getAllItems() async {
    return ContentLibraryStore.getAll();
  }

  /// Returns all items filtered by status.
  static Future<List<ContentLibraryItem>> getItemsByStatus(IdeaStatus status) async {
    return ContentLibraryStore.getByStatus(status);
  }

  /// Adds a new idea to the canonical Content Library.
  ///
  /// This is called by the Idea Vault "Save Idea" button. The idea is
  /// persisted as a ContentLibraryItem with status [IdeaStatus.idea],
  /// making it immediately visible in both the Idea Vault and All Content
  /// views.
  ///
  /// The [sourceIdeaId] is set to [sourceId] when this item was generated
  /// from a prior idea (e.g. a variation or reuse), enabling traceability.
  static Future<ContentLibraryItem> saveIdea({
    required String title,
    required String topic,
    required ContentBucket bucket,
    required IdeaStatus status,
    String? sourceIdeaId,
    List<String> tags = const [],
    Map<String, dynamic> performanceMetrics = const {},
    String? notes,
  }) async {
    final now = DateTime.now();
    final item = ContentLibraryItem(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      topic: topic,
      bucket: bucket,
      format: ContentFormat.carousel,
      status: status,
      contentPackage: null,
      formatOutputs: {},
      qualityReport: null,
      tags: [
        ...tags,
        bucket.id,
        if (notes != null && notes.isNotEmpty) notes,
      ],
      createdAt: now,
      updatedAt: now,
      postedAt: null,
      instagramPostUrl: null,
      performanceMetrics: performanceMetrics,
      reuseCount: 0,
      sourceIdeaId: sourceIdeaId,
    );
    await ContentLibraryStore.add(item);
    return item;
  }

  /// Converts an IdeaInboxItem (from the old inbox store) into a
  /// ContentLibraryItem and saves it to the canonical library.
  ///
  /// Used during migration and for real-time sync: when a new idea is
  /// added to the inbox, this method can be called to ensure the idea
  /// also appears in the Content Library.
  ///
  /// Idempotent: if an item with the same [IdeaInboxItem.id] as
  /// sourceIdeaId already exists in the library, the existing item is
  /// returned without creating a duplicate.
  static Future<ContentLibraryItem> syncInboxItem(IdeaInboxItem inboxItem) async {
    final all = await ContentLibraryStore.getAll();
    for (final item in all) {
      if (item.sourceIdeaId == inboxItem.id) {
        return item;
      }
    }

    final bucket = BucketLibrary.byId(inboxItem.bucketId) ?? BucketLibrary.challenge;
    return saveIdea(
      title: inboxItem.title,
      topic: inboxItem.rawIdea,
      bucket: bucket,
      status: inboxItem.status,
      sourceIdeaId: inboxItem.id,
    );
  }

  /// Syncs all existing inbox items into the canonical Content Library.
  ///
  /// Idempotent: items that already exist by ID are skipped.
  static Future<int> syncAllInboxItems() async {
    final inboxItems = await IdeaInboxStore.load();
    var synced = 0;
    for (final item in inboxItems) {
      await syncInboxItem(item);
      synced++;
    }
    return synced;
  }

  /// Creates a ContentLibraryItem from a generated ContentPackage.
  ///
  /// Called by the Create workflow after the AI generates content. The
  /// resulting library item has the package attached and is immediately
  /// visible in All Content and My Content.
  static Future<ContentLibraryItem> saveGeneratedPackage(
    ContentPackage pkg,
    String sourceIdeaId,
  ) async {
    final item = ContentLibraryItem.createFromPackage(
      pkg,
      sourceIdeaId: sourceIdeaId,
    );
    await ContentLibraryStore.add(item);
    return item;
  }

  /// Updates an existing library item's status and optional publishing fields.
  ///
  /// When an idea transitions from "Idea" → "Generated" → "Posted", this
  /// is the method that records it in the canonical library.
  static Future<void> updateStatus(String id, IdeaStatus status, {
    DateTime? postedAt,
    String? instagramUrl,
  }) async {
    await ContentLibraryStore.updateStatus(id, status,
        postedAt: postedAt, instagramUrl: instagramUrl);
  }

  /// Records performance metrics for a published item.
  ///
  /// Called after manually recording Instagram Insights data.
  static Future<void> recordMetrics(String id, Map<String, dynamic> metrics) async {
    final item = await ContentLibraryStore.getById(id);
    if (item == null) return;
    await ContentLibraryStore.update(
      item.copyWith(
        performanceMetrics: {...item.performanceMetrics, ...metrics},
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Deletes a library item and its inbox counterpart.
  ///
  /// This is the authoritative delete: removing an idea from the Idea Vault
  /// also removes it from the Content Library. Published-performance records
  /// are never deleted — they are preserved as part of experiment history.
  static Future<void> deleteItem(String id) async {
    await ContentLibraryStore.delete(id);
    await IdeaInboxStore.delete(id);
  }

  /// Returns status counts for dashboard display.
  static Future<Map<IdeaStatus, int>> getStatusCounts() async {
    return ContentLibraryStore.getStatusCounts();
  }

  /// Returns bucket counts for dashboard display.
  static Future<Map<ContentBucket, int>> getBucketCounts() async {
    return ContentLibraryStore.getBucketCounts();
  }

  /// Finds potential duplicates before saving a new idea.
  ///
  /// Compares the new idea's title and topic against all existing library
  /// items. Returns items with matching titles or very similar topics.
  static Future<List<ContentLibraryItem>> findDuplicates(
    String title,
    String topic,
  ) async {
    final all = await ContentLibraryStore.getAll();
    final matches = <ContentLibraryItem>[];

    final titleLower = title.toLowerCase();
    final topicLower = topic.toLowerCase();

    for (final item in all) {
      final itemTitleLower = item.title.toLowerCase();
      final itemTopicLower = item.topic.toLowerCase();

      if (itemTitleLower == titleLower) {
        matches.add(item);
      } else if (itemTopicLower.isNotEmpty &&
          topicLower.isNotEmpty &&
          _similarity(itemTopicLower, topicLower) > 0.8) {
        matches.add(item);
      }
    }

    return matches;
  }

  /// Simple Jaccard-style similarity for short strings.
  static double _similarity(String a, String b) {
    final setA = a.split(' ').toSet();
    final setB = b.split(' ').toSet();
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return union == 0 ? 0.0 : intersection / union;
  }
}
