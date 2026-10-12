import 'package:flutter/material.dart';

import 'brand_system.dart';
import 'content_axes.dart';
import 'content_library.dart';
import 'content_service.dart';
import 'theme.dart';

/// My Content — shows all items in the canonical Content Library, grouped by status.
///
/// This is the "All Content" view from the redesign vision: every idea, draft,
/// generated package, and published post lives here as a ContentLibraryItem.
/// The status counts from the Home screen's pipeline overview are derived from this
/// same data.
class MyContentScreen extends StatefulWidget {
  /// Opens the edit/detail flow for a content item.
  final void Function(ContentLibraryItem item)? onItemTap;

  const MyContentScreen({super.key, this.onItemTap});

  @override
  State<MyContentScreen> createState() => _MyContentScreenState();
}

class _MyContentScreenState extends State<MyContentScreen> {
  List<ContentLibraryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ContentService.getAllItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load content: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusSections = _buildStatusSections();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Content'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadItems,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                )
              : _items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          for (final entry in statusSections.entries) ...[
                            _buildStatusSection(entry.key, entry.value),
                            Gap.s,
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: AppColors.textFaint,
          ),
          Gap.m,
          Text(
            'No content yet',
            style: AppText.screenTitle.copyWith(color: AppColors.textSoft),
          ),
          Gap.s,
          Text(
            'Ideas you save from the Idea Vault will appear here.\n'
            'Tap + Add Idea on the Home screen to get started.',
            style: AppText.hint,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<IdeaStatus, List<ContentLibraryItem>> _buildStatusSections() {
    final sections = <IdeaStatus, List<ContentLibraryItem>>{};
    for (final s in IdeaStatus.values) {
      sections[s] = [];
    }
    for (final item in _items) {
      sections.putIfAbsent(item.status, () => []).add(item);
    }
    return Map.fromEntries(
      sections.entries.where((e) => e.value.isNotEmpty),
    );
  }

  Widget _buildStatusSection(IdeaStatus status, List<ContentLibraryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => Row(
            children: [
              Text(
                status.label,
                style: AppText.screenTitle.copyWith(fontSize: 17),
              ),
              Gap.wS,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap.xs,
        ...items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Color _statusColor(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.idea:
        return AppColors.primary;
      case IdeaStatus.approved:
        return AppColors.warning;
      case IdeaStatus.scripted:
        return AppColors.accent;
      case IdeaStatus.imagesReady:
        return const Color(0xFF8E44AD);
      case IdeaStatus.generated:
        return AppColors.primary;
      case IdeaStatus.posted:
        return AppColors.textFaint;
      case IdeaStatus.tested:
        return AppColors.danger;
      case IdeaStatus.archived:
        return AppColors.textSoft;
    }
  }

  Widget _buildItemRow(ContentLibraryItem item) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title.isNotEmpty ? item.title : '(Untitled)',
                      style: AppText.subtitle,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textFaint,
                  ),
                ],
              ),
              Gap.xs,
              Text(
                item.topic,
                style: AppText.hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Gap.s,
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTag(item.bucket.shortLabel, _bucketColor(item.bucket)),
                  _buildTag(item.format.label, AppColors.textSoft),
                  if (item.postedAt != null)
                    _buildTag(
                      'Posted ${_formatDate(item.postedAt!)}',
                      AppColors.primary,
                    ),
                  if (item.performanceMetrics.isNotEmpty)
                    _buildTag(
                      'Has metrics',
                      AppColors.warning,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _bucketColor(ContentBucket bucket) => bucket.color;

  String _formatDate(DateTime date) {
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$mo/$d/${date.year}';
  }
}
