import 'package:flutter/material.dart';

import 'content_axes.dart';
import 'content_library.dart';
import 'content_service.dart';
import 'theme.dart';

/// Insights — shows performance metrics for published content,
/// with a summary card and per-item breakdown.
///
/// This screen reads from the canonical Content Library, filtering for items
/// that have postedAt set and performance metrics recorded.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
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

  List<ContentLibraryItem> get _publishedItems => _items.where(
    (i) => i.status == IdeaStatus.posted || i.performanceMetrics.isNotEmpty,
  ).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
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
              : _publishedItems.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _buildSummaryCard(),
                          Gap.l,
                          _buildBucketBreakdown(),
                          Gap.l,
                          const Text('Published content', style: AppText.subtitle),
                          Gap.s,
                          ..._publishedItems.map((item) => _buildItemMetricsRow(item)),
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
            Icons.insights_outlined,
            size: 64,
            color: AppColors.textFaint,
          ),
          Gap.m,
          Text(
            'No published content yet',
            style: AppText.screenTitle.copyWith(color: AppColors.textSoft),
          ),
          Gap.s,
          Text(
            'Once you publish content and record metrics,\n'
            'insights will appear here.',
            style: AppText.hint,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalReach = _sumMetric('reach');
    final totalSaves = _sumMetric('saves');
    final totalShares = _sumMetric('shares');
    final totalPlays = _sumMetric('plays');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All-time totals',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSoft,
              letterSpacing: 0.8,
            ),
          ),
          Gap.s,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricCard('Reach', totalReach, Icons.bar_chart),
              _buildMetricCard('Impressions', totalPlays, Icons.play_circle_outline),
              _buildMetricCard('Saves', totalSaves, Icons.bookmark_outline),
              _buildMetricCard('Shares', totalShares, Icons.share_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBucketBreakdown() {
    final bucketCounts = <String, int>{};
    final bucketReach = <String, int>{};
    for (final item in _publishedItems) {
      final bucketName = item.bucket.shortLabel;
      bucketCounts.update(bucketName, (v) => v + 1, ifAbsent: () => 1);
      final reach = item.performanceMetrics['reach'] as int? ?? 0;
      bucketReach.update(bucketName, (v) => v + reach, ifAbsent: () => reach);
    }

    final entries = bucketCounts.entries.toList()
      ..sort((a, b) => bucketReach[b.key]!.compareTo(bucketReach[a.key]!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By bucket',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSoft,
            letterSpacing: 0.8,
          ),
        ),
        Gap.s,
        ...entries.map((e) {
          final reach = bucketReach[e.key] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: AppText.body),
                    Text(
                      '${e.value} items · $reach reach',
                      style: AppText.small,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildItemMetricsRow(ContentLibraryItem item) {
    final reach = item.performanceMetrics['reach'] as int? ?? 0;
    final saves = item.performanceMetrics['saves'] as int? ?? 0;
    final shares = item.performanceMetrics['shares'] as int? ?? 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
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
                  if (item.postedAt != null)
                    Text(
                      _formatDate(item.postedAt!),
                      style: AppText.small,
                    ),
                ],
              ),
              Gap.xs,
              Text(
                item.bucket.shortLabel,
                style: AppText.hint,
              ),
              Gap.s,
              Wrap(
                spacing: 8,
                children: [
                  _buildInlineMetric('Reach', reach),
                  _buildInlineMetric('Saves', saves),
                  _buildInlineMetric('Shares', shares),
                ],
              ),
              if (item.performanceMetrics['nonFollowerReach'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Non-follower reach: ${item.performanceMetrics['nonFollowerReach']}',
                    style: AppText.small,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineMetric(String label, int value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  int _sumMetric(String key) {
    var total = 0;
    for (final item in _publishedItems) {
      final m = item.performanceMetrics[key];
      if (m is int) {
        total += m;
      } else if (m is double) {
        total += m.toInt();
      }
    }
    return total;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
