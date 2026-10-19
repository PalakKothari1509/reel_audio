import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content_axes.dart';
import 'content_collections.dart';
import 'content_library.dart';
import 'format_adapter.dart';

/// Lists everything saved into the content library.
///
/// The library previously had a working write path and no reader at all: a generated
/// package could be persisted, and then there was no way to see or reopen it. So a
/// save was real but unreachable, which is the same dead end as no save at all, only
/// quieter.
///
/// Filterable by status, and each row opens the four adapted format outputs rather
/// than showing a summary, because the point of saving a package is copying the
/// finished copy out of it.

class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  List<ContentLibraryItem> _items = const [];
  bool _loading = true;

  /// Empty means "no filter", which is why this is a string and not an enum with an
  /// `all` member: the value comes straight off a filter chip.
  String _statusFilter = '';

  /// Search query that matches across title, topic, and tags.
  String _searchQuery = '';

  /// Collection filter, or null for "all collections".
  String? _selectedCollection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ContentLibraryStore.getAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<ContentLibraryItem> get _visible =>
      _items.where((i) => _matchesFilters(i)).toList();

  bool _matchesFilters(ContentLibraryItem i) {
    if (_statusFilter.isNotEmpty && i.status.name != _statusFilter) {
      return false;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!i.title.toLowerCase().contains(q) &&
          !i.topic.toLowerCase().contains(q) &&
          !i.tags.any((t) => t.toLowerCase().contains(q))) {
        return false;
      }
    }
    if (_selectedCollection != null &&
        _collectionOfItem(i) != _selectedCollection) {
      return false;
    }
    return true;
  }

  String _collectionOfItem(ContentLibraryItem item) {
    final sourceId = item.sourceIdeaId;
    if (sourceId == null || sourceId.isEmpty) return 'mine';
    return collectionOf(sourceId);
  }

  Future<void> _setStatus(ContentLibraryItem item, IdeaStatus status) async {
    await ContentLibraryStore.updateStatus(item.id, status);
    await _load();
  }

  Future<void> _delete(ContentLibraryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text('"${item.title}" will be removed from the library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ContentLibraryStore.delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Library'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              key: const Key('search-field'),
              decoration: InputDecoration(
                hintText: 'Search ideas...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          _collectionChips(),
          _statusChips(),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _collectionChips() {
    final counts = <String, int>{};
    for (final i in _items) {
      final c = _collectionOfItem(i);
      counts[c] = (counts[c] ?? 0) + 1;
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _collectionChip(null, 'All', _items.length, _selectedCollection == null),
          for (final c in kCollections)
            if (c.id != 'mine')
              _collectionChip(
                c.id,
                '${c.emoji} ${c.label}',
                counts[c.id] ?? 0,
                _selectedCollection == c.id,
                dimmed: c.id == 'safety',
              ),
          _collectionChip('mine', '✏️ My Ideas', counts['mine'] ?? 0,
              _selectedCollection == 'mine'),
        ],
      ),
    );
  }

  Widget _collectionChip(
    String? value,
    String label,
    int count,
    bool selected, {
    bool dimmed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(count == 0 && value != null ? label : '$label ($count)'),
        selected: selected,
        onSelected: (_) =>
            setState(() => _selectedCollection = selected ? null : value),
        disabledColor: dimmed ? Colors.grey.shade300 : null,
        labelStyle: TextStyle(
          color: dimmed && !selected ? Colors.grey : null,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _statusChips() {
    final counts = <String, int>{};
    for (final i in _visible) {
      counts[i.status.name] = (counts[i.status.name] ?? 0) + 1;
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _statusChip('', 'All', _visible.length),
          for (final s in IdeaStatus.values)
            _statusChip(s.name, s.label, counts[s.name] ?? 0),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label, int count) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(count == 0 ? label : '$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return _empty(
        'Nothing saved yet',
        'Generate a package and tap "Save to Content Library" on the posting '
            'pack screen.',
      );
    }
    if (_visible.isEmpty) {
      return _empty(
        'No matching items',
        'Try changing your filters.',
      );
    }

    return _groupedByCollection();
  }

  /// Groups _visible items by collection, using the kCollections preferred
  /// order with "My Ideas" last.
  Widget _groupedByCollection() {
    final grouped = <String, List<ContentLibraryItem>>{};
    for (final item in _visible) {
      final c = _collectionOfItem(item);
      (grouped[c] ??= []).add(item);
    }

    final orderedKeys = <String>[];
    for (final c in kCollections) {
      if (c.id != 'mine' && grouped.containsKey(c.id)) {
        orderedKeys.add(c.id);
      }
    }
    if (grouped.containsKey('mine')) orderedKeys.add('mine');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orderedKeys.length,
      itemBuilder: (context, index) {
        final collectionId = orderedKeys[index];
        final items = grouped[collectionId]!;
        final collection = kCollectionById[collectionId];

        return ExpansionTile(
          key: PageStorageKey('col-$collectionId'),
          title: Text(
            '${collection?.emoji ?? '✏️'} '
            '${collection?.label ?? 'My Ideas'} (${items.length})',
          ),
          children: [
            for (final item in items) _itemTile(item),
          ],
        );
      },
    );
  }

  Widget _itemTile(ContentLibraryItem item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.bucket.softColor,
        child: Text(item.bucket.emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            item.status.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          Text(item.status.label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.format.emoji,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(item.format.label),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'delete') {
            _delete(item);
            return;
          }
          _setStatus(item, IdeaStatus.values.byName(value));
        },
        itemBuilder: (context) => [
          for (final s in IdeaStatus.values)
            if (s != item.status)
              PopupMenuItem(value: s.name, child: Text('Move to ${s.label}')),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContentLibraryDetailScreen(itemId: item.id),
          ),
        );
        await _load();
      },
    );
  }

  Widget _empty(String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens one saved package and exposes its four format outputs.
///
/// Loads from the store rather than taking the item directly, so the status changes
/// made on this screen survive, and so a deep link could open it by id later.
class ContentLibraryDetailScreen extends StatefulWidget {
  final String itemId;

  const ContentLibraryDetailScreen({super.key, required this.itemId});

  @override
  State<ContentLibraryDetailScreen> createState() =>
      _ContentLibraryDetailScreenState();
}

class _ContentLibraryDetailScreenState
    extends State<ContentLibraryDetailScreen> {
  ContentLibraryItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final item = await ContentLibraryStore.getById(widget.itemId);
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved package'),
        actions: [
          if (item != null)
            IconButton(
              tooltip: 'Copy all copy blocks',
              onPressed: () => _copyAll(item),
              icon: const Icon(Icons.copy_all),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : item == null
              ? const Center(child: Text('This item no longer exists.'))
              : _detail(item),
    );
  }

  Future<void> _copyAll(ContentLibraryItem item) async {
    final buffer = StringBuffer()
      ..writeln('TOPIC: ${item.topic}')
      ..writeln('HOOK: ${item.contentPackage?.hook ?? ''}');

    for (final entry in item.formatOutputs.entries) {
      buffer
        ..writeln()
        ..writeln('===== ${entry.value.format.label} =====');
      for (final block in entry.value.copyBlocks) {
        if (block.trim().isNotEmpty) buffer.writeln(block);
      }
      if (entry.value.script.trim().isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('SCRIPT:')
          ..writeln(entry.value.script);
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All copy blocks copied')),
    );
  }

  Widget _detail(ContentLibraryItem item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(item.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Topic: ${item.topic}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _tag(item.format.label),
            _tag(item.bucket.shortLabel),
            _tag(item.contentPackage?.hashtags.join(' ') ?? ''),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Format outputs',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final output in item.formatOutputs.values)
          _FormatOutputCard(output: output),
      ],
    );
  }

  Widget _tag(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Chip(label: Text(text), visualDensity: VisualDensity.compact);
  }
}

class _FormatOutputCard extends StatelessWidget {
  final FormatOutput output;

  const _FormatOutputCard({required this.output});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Text(output.format.emoji),
        title: Text(output.format.label),
        subtitle: Text(
          '${output.copyBlocks.length} copy blocks · '
          '${output.slides.length} slides · '
          '${output.imagePrompts.length} prompts',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          for (final block in output.copyBlocks)
            if (block.trim().isNotEmpty)
              _CopyBlock(text: block),
          if (output.script.trim().isNotEmpty)
            _CopyBlock(text: output.script, heading: 'Script'),
          for (final prompt in output.imagePrompts)
            _CopyBlock(text: prompt, heading: 'Image prompt'),
        ],
      ),
    );
  }
}

class _CopyBlock extends StatelessWidget {
  final String text;
  final String? heading;

  const _CopyBlock({required this.text, this.heading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null)
            Text(
              heading!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodySmall),
              ),
              IconButton(
                tooltip: 'Copy',
                iconSize: 18,
                onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}