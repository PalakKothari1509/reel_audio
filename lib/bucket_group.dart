/// Preferred bucket order for the top-level filter row.
const kBucketOrder = [
  'challenge',
  'conversation',
  'activity',
  'humor',
  'agePractice',
  'community',
];

/// A lightweight pair of bucket id and its items, used for grouping display.
class BucketGroup<T> {
  final String bucketId;
  final List<T> items;
  const BucketGroup(this.bucketId, this.items);
}

/// Groups items by a key extractor, using the preferred order for
/// known buckets and "Other" for unknown ones.
///
/// Returns a list of [BucketGroup] in display order so the calling
/// widget does not need to manage ordering logic.
List<BucketGroup<T>> groupItemsByBucket<T>(
  Iterable<T> items,
  String Function(T) keyOf,
) {
  final grouped = <String, List<T>>{};
  for (final item in items) {
    final k = keyOf(item);
    final bucketId = kBucketOrder.contains(k) ? k : 'other';
    (grouped[bucketId] ??= []).add(item);
  }

  final result = <BucketGroup<T>>[];
  for (final b in kBucketOrder) {
    if (grouped.containsKey(b)) result.add(BucketGroup(b, grouped[b]!));
  }
  if (grouped.containsKey('other')) {
    result.add(BucketGroup('other', grouped['other']!));
  }
  return result;
}
