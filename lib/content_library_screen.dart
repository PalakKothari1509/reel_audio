import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  List<ContentLibraryItem> get _visible => _statusFilter.isEmpty
      ? _items
      : _items.where((i) => i.status.name == _statusFilter).toList();

  Future<void> _setStatus(ContentLibraryItem item, ContentStatus status) async {
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
          _statusChips(),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _statusChips() {
    final counts = <String, int>{};
    for (final i in _items) {
      counts[i.status.name] = (counts[i.status.name] ?? 0) + 1;
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip('', 'All', _items.length),
          for (final s in ContentStatus.values)
            _chip(s.name, _label(s), counts[s.name] ?? 0),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, int count) {
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

  /// Human labels. The enum names are storage values and read as plumbing.
  String _label(ContentStatus s) {
    switch (s) {
      case ContentStatus.idea:
        return 'Idea';
      case ContentStatus.draft:
        return 'Draft';
      case ContentStatus.ready:
        return 'Ready';
      case ContentStatus.posted:
        return 'Posted';
      case ContentStatus.reused:
        return 'Reused';
      case ContentStatus.archived:
        return 'Archived';
    }
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
        'No ${_label(ContentStatus.values.byName(_statusFilter)).toLowerCase()} '
            'items',
        'Try a different filter.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _visible.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _visible[index];
        return ListTile(
          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.format.label} · ${item.bucket.shortLabel} · '
            '${item.formatOutputs.length} formats',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _delete(item);
                return;
              }
              _setStatus(item, ContentStatus.values.byName(value));
            },
            itemBuilder: (context) => [
              for (final s in ContentStatus.values)
                if (s != item.status)
                  PopupMenuItem(value: s.name, child: Text('Move to ${_label(s)}')),
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