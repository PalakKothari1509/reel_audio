import 'package:flutter/material.dart';

import 'asset_completeness_service.dart';
import 'brand_system.dart';
import 'content_axes.dart';
import 'content_audit.dart';
import 'content_library.dart';
import 'content_library_service.dart';
import 'package_store.dart';
import 'theme.dart';

/// Dashboard screen — gives an at-a-glance view of content health.
///
/// Shows four key summaries:
/// 1. Ideas by Pillar — how the content library is distributed across PLAY/THINK/DISCOVER/TALK/DO
/// 2. Ready to Produce — ideas with approved classification that haven't been generated yet
/// 3. Published by Format — carousel vs reel vs trial reel counts for posted items
/// 4. Formats Tested < 5 Times — flags narrative formats that lack sufficient data
///    (the five-test rule) so the creator knows what needs more testing.
class DashboardScreen extends StatefulWidget {
  final PackageStore? packageStore;

  /// Callbacks provided by the parent (main.dart / home_screen.dart).
  final VoidCallback? onReviewAllIdeas;
  final VoidCallback? onAddNewIdea;
  final VoidCallback? onCreateContent;
  final VoidCallback? onManageVideos;

  const DashboardScreen({
    super.key,
    this.packageStore,
    this.onReviewAllIdeas,
    this.onAddNewIdea,
    this.onCreateContent,
    this.onManageVideos,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ContentLibraryItem> _items = [];
  List<ContentAuditItem> _auditItems = [];
  List<PackageMetadata> _packages = [];
  List<AssetCompleteness> _completeness = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final libraryItems = await ContentLibraryStore.getAll();
      final auditItems = await ContentAuditStore.instance.loadAll();
      final packages = await _loadPackages();
      final completeness = await AssetCompletenessService.checkAll();

      if (!mounted) return;
      setState(() {
        _items = libraryItems;
        _auditItems = auditItems;
        _packages = packages;
        _completeness = completeness;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load dashboard: $e';
        _loading = false;
      });
    }
  }

  Future<List<PackageMetadata>> _loadPackages() async {
    final store = widget.packageStore;
    if (store == null) return [];
    try {
      final pkgs = await store.loadAllPackages();
      return pkgs.map((pkg) => PackageMetadata(
        id: pkg.id,
        ideaId: pkg.ideaId,
        status: pkg.publishedAt != null
            ? PackageStatus.posted
            : PackageStatus.videoBuilt,
        experimentCount: pkg.testCount ?? 0,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Data aggregations ────────────────────────────────────────────────

  Map<ContentPillar, int> _pillarsByIdea() {
    final counts = <ContentPillar, int>{};
    for (final item in _items) {
      final tags = item.tags;
      ContentPillar pillar = ContentPillar.play;
      for (final tag in tags) {
        final found = ContentPillar.byLabel(tag);
        if (found != null) {
          pillar = found;
          break;
        }
      }
      counts[pillar] = (counts[pillar] ?? 0) + 1;
    }
    return counts;
  }

  Map<ContentPillar, int> _pillarsByAudit() {
    final counts = <ContentPillar, int>{};
    for (final item in _auditItems) {
      counts[item.pillar] = (counts[item.pillar] ?? 0) + 1;
    }
    return counts;
  }

  /// Items that are ready to produce: approved/scripted/generated status
  /// but not yet posted or tested.
  List<ContentLibraryItem> _itemsReadyToProduce() {
    return _items.where((i) =>
        i.status == IdeaStatus.approved ||
        i.status == IdeaStatus.scripted ||
        i.status == IdeaStatus.generated ||
        i.status == IdeaStatus.imagesReady).toList();
  }

  /// Published items grouped by format.
  Map<ContentFormat, int> _publishedByFormat() {
    final counts = <ContentFormat, int>{};
    for (final item in _items) {
      if (item.status == IdeaStatus.posted || item.status == IdeaStatus.tested) {
        counts[item.format] = (counts[item.format] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Audit items that are posted, grouped by format.
  Map<String, int> _postedFormatsFromAudit() {
    final counts = <String, int>{};
    for (final item in _auditItems) {
      if (item.status == AuditStatus.posted) {
        counts[item.format] = (counts[item.format] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Formats tested fewer than 5 times, from package experiment counts.
  Map<String, int> _undertestedFormats() {
    final counts = <String, int>{};
    for (final pkg in _packages) {
      counts[pkg.ideaId] = (counts[pkg.ideaId] ?? 0) + 1;
    }
    return Map.fromEntries(
      counts.entries.where((e) => e.value < 5),
    );
  }

  // ── Dashboard metric helpers (from ContentLibraryService) ──────────────

  int _totalIdeas = 0;
  int _needReview = 0;
  int _inProduction = 0;
  int _readyToPost = 0;
  int _posted = 0;
  bool _ideaCountsLoaded = false;

  Future<void> _loadIdeaCounts() async {
    try {
      final service = ContentLibraryService.instance;
      final ideas = await service.getAllIdeas();
      final completeness = await AssetCompletenessService.checkAll();

      int needReview = 0;
      int inProduction = 0;
      int posted = 0;
      for (final idea in ideas) {
        if (idea.status == IdeaStatus.idea) needReview++;
        if (idea.status.index > IdeaStatus.idea.index &&
            idea.status != IdeaStatus.posted &&
            idea.status != IdeaStatus.archived) {
          inProduction++;
        }
        if (idea.status == IdeaStatus.posted) posted++;
      }

      int ready = 0;
      for (final a in completeness) {
        if (a.isReadyToPost) ready++;
      }

      if (!mounted) return;
      setState(() {
        _totalIdeas = ideas.length;
        _needReview = needReview;
        _inProduction = inProduction;
        _readyToPost = ready;
        _posted = posted;
        _ideaCountsLoaded = true;
      });
    } catch (_) {
      // File stores may not be available in test context; counts stay at 0.
      if (!mounted) return;
      setState(() {
        _ideaCountsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              _loadDashboardData();
              _loadIdeaCounts();
            },
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
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadDashboardData();
                    await _loadIdeaCounts();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcome(),
                        Gap.l,

                      // Section A — Main Actions
                      _buildSectionHeader('Main Actions'),
                      Gap.s,
                      _buildMainActions(),
                      Gap.l,

                      // Section B — Your Content Progress
                      _buildSectionHeader('Your Content Progress'),
                      Gap.s,
                      _buildContentProgress(),
                      Gap.l,

                      // Section C — Ideas by Pillar
                      _buildSectionHeader('Ideas by Pillar'),
                      Gap.s,
                      _buildPillarSummary(),
                      Gap.l,

                      // Section D — Ready to Produce
                      _buildSectionHeader('Ready to Produce'),
                      Gap.s,
                      _buildReadyToProduce(),
                      Gap.l,

                      // Published by Format
                      _buildSectionHeader('Published by Format'),
                      Gap.s,
                      _buildFormatSummary(),
                      Gap.l,

                      // Formats Tested < 5 Times
                      _buildSectionHeader('Formats Tested < 5 Times'),
                      Gap.s,
                      _buildUndertestedFormats(),
                      Gap.l,

                      // Ready-to-Post Checklist
                      _buildSectionHeader('Ready-to-Post Checklist'),
                      Gap.s,
                      _buildReadyToPost(),
                    ],
                  ),
                ),
              ),
            );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to Fun Learning With Palak',
          style: AppText.screenTitle,
        ),
        const SizedBox(height: 4),
        Text('Your content workspace', style: AppText.hint),
      ],
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        _mainActionCard(
          icon: Icons.library_books,
          color: AppColors.primary,
          title: 'Content Library',
          subtitle: 'Browse, search, edit, and review every idea',
          onTap: widget.onReviewAllIdeas,
        ),
        Gap.s,
        _mainActionCard(
          icon: Icons.add,
          color: AppColors.accent,
          title: 'Add New Idea',
          subtitle: 'Create a new content idea from scratch',
          onTap: widget.onAddNewIdea,
        ),
        Gap.s,
        _mainActionCard(
          icon: Icons.auto_awesome,
          color: AppColors.warning,
          title: 'Create Content',
          subtitle: 'Select an idea and generate stories, scripts, prompts',
          onTap: widget.onCreateContent,
        ),
        Gap.s,
        _mainActionCard(
          icon: Icons.video_library_outlined,
          color: AppColors.accent,
          title: 'My Videos',
          subtitle: 'Upload, preview, and manage finished reels',
          onTap: widget.onManageVideos,
        ),
      ],
    );
  }

  Widget _mainActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.screenTitle.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.hint),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentProgress() {
    return Column(
      children: [
        _progressMetric('Total Ideas', _totalIdeas, Icons.lightbulb_outline),
        Gap.xs,
        _progressMetric('Need Review', _needReview, Icons.visibility_outlined),
        Gap.xs,
        _progressMetric('In Production', _inProduction, Icons.build_outlined),
        Gap.xs,
        _progressMetric('Ready to Post', _readyToPost, Icons.check_circle_outline),
        Gap.xs,
        _progressMetric('Posted', _posted, Icons.campaign_outlined),
      ],
    );
  }

  Widget _progressMetric(String label, int count, IconData icon) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: AppText.body),
            const Spacer(),
            Text(count.toString(), style: AppText.screenTitle.copyWith(fontSize: 20, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppText.screenTitle);
  }

  Widget _buildPillarSummary() {
    final byIdea = _pillarsByIdea();
    final byAudit = _pillarsByAudit();

    if (byIdea.isEmpty && byAudit.isEmpty) {
      return _buildEmptyState('No ideas in the library yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPillarRow('By Idea Library', byIdea),
        Gap.s,
        _buildPillarRow('By Audit Records', byAudit),
      ],
    );
  }

  Widget _buildPillarRow(String label, Map<ContentPillar, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.subtitle),
        Gap.xs,
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final pillar in ContentPillar.values)
              _buildPillarChip(pillar, counts[pillar] ?? 0),
          ],
        ),
      ],
    );
  }

  Widget _buildPillarChip(ContentPillar pillar, int count) {
    return Chip(
      backgroundColor: pillar == ContentPillar.play
          ? AppColors.primarySoft
          : AppColors.surfaceAlt,
      label: Text(
        '${pillar.label} · $count',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildReadyToProduce() {
    final items = _itemsReadyToProduce();
    if (items.isEmpty) {
      return _buildEmptyState('Nothing ready to produce yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${items.length} item${items.length == 1 ? '' : 's'} ready',
            style: AppText.subtitle),
        Gap.s,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length.clamp(0, 10),
          separatorBuilder: (_, _) => Gap.xs,
          itemBuilder: (context, i) {
            final item = items[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Text(item.bucket.emoji, style: const TextStyle(fontSize: 18)),
              ),
              title: Text(item.title, style: AppText.body),
              subtitle: Text('${item.bucket.name} · ${item.status.label}'),
              trailing: item.format.emoji.isNotEmpty
                  ? CircleAvatar(
                      backgroundColor: AppColors.surfaceAlt,
                      child: Text(item.format.emoji, style: const TextStyle(fontSize: 16)),
                    )
                  : null,
            );
          },
        ),
        if (items.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('+ ${items.length - 10} more items',
                style: AppText.small.copyWith(color: AppColors.textSoft)),
          ),
      ],
    );
  }

  Widget _buildFormatSummary() {
    final byFormat = _publishedByFormat();
    final byAudit = _postedFormatsFromAudit();

    if (byFormat.isEmpty && byAudit.isEmpty) {
      return _buildEmptyState('No published content yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormatRow('By Library', byFormat),
        Gap.s,
        _buildFormatRow('By Audit', byAudit),
      ],
    );
  }

  Widget _buildFormatRow(String label, Map<dynamic, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.subtitle),
        Gap.xs,
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final entry in counts.entries)
              Chip(
                backgroundColor: AppColors.surfaceAlt,
                label: Text('${entry.key} · ${entry.value}',
                    style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUndertestedFormats() {
    final undertested = _undertestedFormats();
    if (undertested.isEmpty) {
      return _buildEmptyState(
        'All formats tested 5+ times. 🎉\n(Or no experiment data yet.)');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '${undertested.length} format${undertested.length == 1 ? '' : 's'} undertested',
            style: AppText.subtitle),
        Gap.s,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: undertested.length,
          separatorBuilder: (_, _) => Gap.xs,
          itemBuilder: (context, i) {
            final entry = undertested.entries.elementAt(i);
            return ListTile(
              leading: const Icon(Icons.warning_amber_outlined,
                  color: AppColors.warning),
              title: Text(entry.key, style: AppText.body),
              subtitle: Text('${entry.value} test${entry.value == 1 ? '' : 's'} — need ${5 - entry.value} more'),
              trailing: Text('${entry.value}/5', style: AppText.small),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(message,
            style: AppText.body.copyWith(color: AppColors.textSoft),
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildReadyToPost() {
    final ready = _completeness.where((a) => a.isReadyToPost).toList();
    final missing = _completeness.where((a) => !a.isReadyToPost).toList();

    if (_completeness.isEmpty) {
      return _buildEmptyState(
        'No content ideas checked. Generate prompts to get started.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ready.isNotEmpty) ...[
          Text('${ready.length} ready to post', style: AppText.subtitle),
          Gap.s,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ready.length.clamp(0, 10),
            separatorBuilder: (_, _) => Gap.xs,
            itemBuilder: (context, i) {
              final item = ready[i];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: AppColors.primary),
                title: Text(item.title, style: AppText.body),
                subtitle: Text('${item.contentId} · ${item.hasVideoAsset ? "video uploaded" : ""}',
                    style: AppText.hint),
              );
            },
          ),
          if (ready.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('+ ${ready.length - 10} more ready',
                  style: AppText.small.copyWith(color: AppColors.textSoft)),
            ),
          Gap.l,
        ],
        Text('${missing.length} need attention', style: AppText.subtitle),
        Gap.s,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: missing.length.clamp(0, 10),
          separatorBuilder: (_, _) => Gap.xs,
          itemBuilder: (context, i) {
            final item = missing[i];
            final missingItems = <String>[];
            if (!item.hasScript) missingItems.add('script');
            if (!item.hasVideoPrompt) missingItems.add('video prompt');
            if (!item.hasVideoAsset) missingItems.add('video');
            if (!item.hasQualityReport) missingItems.add('quality check');
            return ListTile(
              leading: const Icon(Icons.warning_amber_outlined,
                  color: AppColors.warning),
              title: Text(item.title, style: AppText.body),
              subtitle: Text('Missing: ${missingItems.join(', ')}',
                  style: AppText.hint),
            );
          },
        ),
        if (missing.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('+ ${missing.length - 10} more need attention',
                style: AppText.small.copyWith(color: AppColors.textSoft)),
          ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ideaCountsLoaded) {
      _ideaCountsLoaded = true;
      _loadIdeaCounts();
    }
  }
}
