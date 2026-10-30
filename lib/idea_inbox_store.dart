import 'brand_system.dart';
import 'content_axes.dart';
import 'json_file_store.dart';

class IdeaInboxItem {
  final String id;
  final String title;
  final String rawIdea;
  final String bucketId;
  final String notes;
  final IdeaStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IdeaInboxItem({
    required this.id,
    required this.title,
    required this.rawIdea,
    required this.bucketId,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  IdeaInboxItem copyWith({
    String? title,
    String? rawIdea,
    String? bucketId,
    String? notes,
    IdeaStatus? status,
    DateTime? updatedAt,
  }) => IdeaInboxItem(
    id: id,
    title: title ?? this.title,
    rawIdea: rawIdea ?? this.rawIdea,
    bucketId: bucketId ?? this.bucketId,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'rawIdea': rawIdea,
    'bucketId': bucketId,
    'notes': notes,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory IdeaInboxItem.fromJson(Map<String, dynamic> json) => IdeaInboxItem(
    id: json['id'] as String,
    title: json['title'] as String,
    rawIdea: json['rawIdea'] as String,
    bucketId: json['bucketId'] as String,
    notes: json['notes'] as String,
    status: IdeaStatus.fromLegacy(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  ContentBucket get bucket =>
      BucketLibrary.byId(bucketId) ?? BucketLibrary.challenge;
}

class _IdeaInboxFileStore extends JsonFileStore<IdeaInboxItem> {
  _IdeaInboxFileStore() : super('idea_inbox.json');

  @override
  String idOf(IdeaInboxItem item) => item.id;

  @override
  IdeaInboxItem fromJson(Map<String, dynamic> json) =>
      IdeaInboxItem.fromJson(json);

  @override
  Map<String, dynamic> toJson(IdeaInboxItem item) => item.toJson();
}

class IdeaInboxStore {
  static final _IdeaInboxFileStore _store = _IdeaInboxFileStore();

  static Future<List<IdeaInboxItem>> load() async {
    return _store.loadAll();
  }

  static Future<void> save(List<IdeaInboxItem> items) async {
    await _store.saveAll(items);
  }

  static Future<void> add(IdeaInboxItem item) async {
    final list = await load();
    list.insert(0, item);
    await _store.saveAll(list);
  }

  static Future<void> update(IdeaInboxItem item) async {
    final list = await load();
    final index = list.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      list[index] = item;
      await _store.saveAll(list);
    }
  }

  static Future<void> delete(String id) async {
    final list = await load();
    list.removeWhere((e) => e.id == id);
    await _store.saveAll(list);
  }
}
