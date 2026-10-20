import 'package:flutter/material.dart';

import 'content_axes.dart';
import 'content_collections.dart';
import 'content_library_service.dart';
import 'theme.dart';

/// Lists every idea in the app — built-in hooks, safety hooks, day-14 posts,
/// and user-added ideas — all in one place.
///
/// This screen is the single home for idea review, editing, and creation.
/// It reads from [ContentLibraryService], which merges HookStore,
/// QuickIdeaStore, IdeaInboxStore, and all built-in const lists into one
/// deduplicated list of [ContentIdea].
class ContentLibraryScreen extends StatefulWidget {
  /// Optional callback when the user taps "Create Content" on an idea.
  /// Passes the idea's stable ID.
  final void Function(String ideaId)? onCreateContent;

  /// Optional callback when the user taps "Add New Idea".
  final VoidCallback? onAddNewIdea;

  const ContentLibraryScreen({super.key, this.onCreateContent, this.onAddNewIdea});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  List<ContentIdea> _ideas = const [];
  bool _loading = true;
  String? _error;

  /// Search query across title, opening, problem, lesson, storyDetail.
  String _searchQuery = '';

  /// Currently selected category filter, or null for "all".
  String? _selectedCategory;

  /// Currently selected format filter, or null for "all".
  String? _selectedFormat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ideas = await ContentLibraryService.instance.getAllIdeas();
      if (!mounted) return;
      setState(() {
        _ideas = ideas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load ideas: $e';
        _loading = false;
      });
    }
  }

  List<ContentIdea> get _visible => _ideas.where(_matchesFilters).toList();

  bool _matchesFilters(ContentIdea i) {
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!i.title.toLowerCase().contains(q) &&
          !i.opening.toLowerCase().contains(q) &&
          !i.problem.toLowerCase().contains(q) &&
          !i.lesson.toLowerCase().contains(q) &&
          !i.storyDetail.toLowerCase().contains(q)) {
        return false;
      }
    }
    if (_selectedCategory != null && i.category != _selectedCategory) return false;
    if (_selectedFormat != null && i.format != _selectedFormat) return false;
    return true;
  }

  List<String> get _categories {
    final cats = <String>{};
    for (final i in _ideas) {
      if (i.category.isNotEmpty) cats.add(i.category);
    }
    return cats.toList()..sort();
  }

  List<String> get _formats {
    final fmts = <String>{};
    for (final i in _ideas) {
      if (i.format.isNotEmpty) fmts.add(i.format);
    }
    return fmts.toList()..sort();
  }

  Future<void> _deleteIdea(ContentIdea idea) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this idea?'),
        content: Text('"${idea.title}" will be removed from your library.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!idea.isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Built-in ideas cannot be deleted.')),
      );
      return;
    }
    await ContentLibraryService.instance.deleteIdea(idea.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Library'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          const _LibraryHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ideas...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          _categoryChips(),
          _formatChips(),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddNewIdea,
        icon: const Icon(Icons.add),
        label: const Text('Add New Idea'),
      ),
    );
  }

  Widget _categoryChips() {
    final cats = _categories;
    if (cats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _filterChip(null, 'All', _selectedCategory == null),
          for (final c in cats)
            _filterChip(c, c, _selectedCategory == c),
        ],
      ),
    );
  }

  Widget _formatChips() {
    final fmts = _formats;
    if (fmts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _filterChip(null, 'All Formats', _selectedFormat == null),
          for (final f in fmts)
            _filterChip(f, f, _selectedFormat == f),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() {
          if (value == null) {
            _selectedCategory = null;
            _selectedFormat = null;
          } else if (_formats.contains(value)) {
            _selectedFormat = selected ? null : value;
          } else {
            _selectedCategory = selected ? null : value;
          }
        }),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
      );
    }
    if (_ideas.isEmpty) {
      return const _EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No ideas yet',
        body: 'Tap "Add New Idea" to get started.',
      );
    }
    if (_visible.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off,
        title: 'No matching ideas',
        body: 'Try changing your filters.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _visible.length,
      separatorBuilder: (_, __
) => const Divider(height: 1),
      itemBuilder: (context, i) => _IdeaCard(
        idea: _visible[i],
        onCreateContent: widget.onCreateContent,
        onEdit: (idea) async {
          await Navigator.pushNamed(
            context,
            '/review-idea',
            arguments: idea.id,
          );
          await _load();
        },
        onDelete: _deleteIdea,
      ),
    );
  }
}

/// Header that shows the screen title and subtitle.
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONTENT LIBRARY', style: AppText.screenTitle),
          SizedBox(height: 4),
          Text('All your content ideas in one place.', style: AppText.hint),
        ],
      ),
    );
  }
}

/// A single idea card with category, problem, characters, and status badges.
class _IdeaCard extends StatelessWidget {
  final ContentIdea idea;
  final void Function(String ideaId)? onCreateContent;
  final void Function(ContentIdea idea)? onEdit;
  final void Function(ContentIdea idea)? onDelete;

  const _IdeaCard({required this.idea, this.onCreateContent, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final collection = kCollectionById[idea.collectionId];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with collection badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    idea.title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (collection != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${collection.emoji} ${collection.label}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Category
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.category_outlined, size: 14, color: AppColors.textSoft),
                Text(idea.category, style: AppText.small),
              ],
            ),
            const SizedBox(height: 4),

            // Problem
            if (idea.problem.isNotEmpty)
              Text(
                idea.problem,
                style: AppText.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (idea.problem.isNotEmpty) const SizedBox(height: 4),

            // Characters
            if (idea.characterIds.isNotEmpty)
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.group_outlined, size: 14, color: AppColors.textSoft),
                  ...idea.characterIds.map((c) => Text(c, style: AppText.small)),
                ],
              ),
            if (idea.characterIds.isNotEmpty) const SizedBox(height: 4),

            // Learning
            if (idea.lesson.isNotEmpty)
              Text(
                idea.lesson,
                style: AppText.bodySmall.copyWith(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Status badge + action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  idea.status.label,
                  style: AppText.small.copyWith(
                    color: _statusColor(idea.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      '/review-idea',
                      arguments: idea.id,
                    );
                  },
                  child: const Text('Review Idea'),
                ),
                TextButton(
                  onPressed: onCreateContent != null
                      ? () => onCreateContent!(idea.id)
                      : null,
                  child: const Text('Create Content'),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit != null
                      ? () => onEdit!(idea)
                      : () async {
                          await Navigator.pushNamed(
                            context,
                            '/review-idea',
                            arguments: idea.id,
                          );
                        },
                ),
                if (idea.isCustom)
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outlined, size: 18, color: AppColors.danger),
                    onPressed: onDelete != null ? () => onDelete!(idea) : null,
                  ),
               ],
             ),
           ],
         ),
       ),
     );
  }

  Color _statusColor(IdeaStatus status) {
    return switch (status) {
      IdeaStatus.idea => AppColors.textSoft,
      IdeaStatus.approved => AppColors.primary,
      IdeaStatus.scripted => AppColors.warning,
      IdeaStatus.imagesReady => AppColors.accent,
      IdeaStatus.generated => AppColors.primary,
      IdeaStatus.posted => AppColors.success,
      IdeaStatus.tested => Colors.blueGrey,
      IdeaStatus.archived => AppColors.textSoft,
    };
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyState({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSoft),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
