// HomeScreen — the redesigned dashboard for Fun Learning With Palak Content Studio.
//
// Replaces CreatorHomeScreen with a simpler, task-oriented navigation hub.
// Shows what needs attention and lets the user start their next task in one tap.
//
// Proposed navigation (see documentation/REDESIGN_VISION.md §3):
//   Home | Idea Vault | Create | My Content | Insights | Settings

import 'package:flutter/material.dart';

import 'content_axes.dart';
import 'content_service.dart';
import 'theme.dart';

/// Callback type for navigation actions that don't need arguments.
typedef NavCallback = void Function();

/// Callback type for "Create" action that may carry an idea ID.
typedef CreateCallback = void Function(String? ideaId);

/// The redesigned Home screen.
///
/// Presents the six top-level navigation sections as a scrollable list of
/// action cards, plus a pipeline overview that shows how many items are in
/// each status bucket. Tapping a pipeline count navigates to the filtered
/// Idea Vault.
class ContentStudioHome extends StatefulWidget {
  final CreateCallback onCreateReel;
  final CreateCallback onAddIdea;
  final NavCallback onMyContent;
  final NavCallback onInsights;
  final NavCallback onSettings;
  final NavCallback onIdeaVault;

  const ContentStudioHome({
    super.key,
    required this.onCreateReel,
    required this.onAddIdea,
    required this.onMyContent,
    required this.onInsights,
    required this.onSettings,
    required this.onIdeaVault,
  });

  @override
  State<ContentStudioHome> createState() => _ContentStudioHomeState();
}

class _ContentStudioHomeState extends State<ContentStudioHome> {
  Map<IdeaStatus, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final counts = await ContentService.getStatusCounts();
    if (!mounted) return;
    setState(() {
      _statusCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fun Learning With Palak'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: widget.onSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildWelcomeSection(),
            Gap.l,
            _buildPipelineOverview(),
            Gap.l,
            _buildQuickActions(),
            Gap.l,
            _buildNavigationCards(),
            Gap.m,
            _buildReminders(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good morning, Palak!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        Gap.xs,
        Text(
          'What would you like to create today?',
          style: AppText.hint,
        ),
      ],
    );
  }

  Widget _buildPipelineOverview() {
    final sections = [
      _PipelineCard('Ideas', _statusCounts[IdeaStatus.idea] ?? 0,
          color: AppColors.primary),
      _PipelineCard('In Progress',
          (_statusCounts[IdeaStatus.scripted] ?? 0) +
          (_statusCounts[IdeaStatus.imagesReady] ?? 0) +
          (_statusCounts[IdeaStatus.generated] ?? 0),
          color: AppColors.accent),
      _PipelineCard('Approved', _statusCounts[IdeaStatus.approved] ?? 0,
          color: AppColors.warning),
      _PipelineCard('Published', _statusCounts[IdeaStatus.posted] ?? 0,
          color: AppColors.textFaint),
      _PipelineCard('Awaiting Metrics',
          _statusCounts[IdeaStatus.tested] ?? 0,
          color: AppColors.danger),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your content pipeline', style: AppText.section),
        Gap.s,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sections,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: AppText.section),
        Gap.s,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickActionButton(
              label: '+ Add Idea',
              icon: Icons.add,
              onTap: () => widget.onAddIdea(null),
              color: AppColors.primary,
            ),
            _QuickActionButton(
              label: 'Create a Reel',
              icon: Icons.movie_creation_outlined,
              onTap: () => widget.onCreateReel(null),
              color: AppColors.accent,
            ),
            _QuickActionButton(
              label: 'View Content',
              icon: Icons.folder_open,
              onTap: widget.onIdeaVault,
              color: AppColors.textSoft,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationCards() {
    final cards = [
      _NavCard(
        icon: Icons.lightbulb_outline,
        iconColor: AppColors.primary,
        title: 'Idea Vault',
        subtitle: 'Capture, browse, organise, and develop ideas',
        onTap: widget.onIdeaVault,
      ),
      _NavCard(
        icon: Icons.auto_awesome,
        iconColor: AppColors.accent,
        title: 'Create',
        subtitle: 'Generate and edit content packages',
        onTap: () => widget.onCreateReel(null),
      ),
      _NavCard(
        icon: Icons.library_books,
        iconColor: AppColors.warning,
        title: 'My Content',
        subtitle: 'Track production, published content, and performance',
        onTap: widget.onMyContent,
      ),
      _NavCard(
        icon: Icons.insights,
        iconColor: AppColors.primary,
        title: 'Insights',
        subtitle: 'Understand results and plan next tests',
        onTap: widget.onInsights,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Go to', style: AppText.section),
        Gap.s,
        ...cards,
      ],
    );
  }

  Widget _buildReminders() {
    final reminders = <Widget>[];

    final newIdeas = _statusCounts[IdeaStatus.idea] ?? 0;
    if (newIdeas > 0) {
      reminders.add(_ReminderItem(
        icon: Icons.lightbulb_outline,
        text: '$newIdeas idea${newIdeas != 1 ? 's' : ''} waiting to be developed',
        onTap: widget.onIdeaVault,
      ));
    }

    final tested = _statusCounts[IdeaStatus.tested] ?? 0;
    if (tested > 0) {
      reminders.add(_ReminderItem(
        icon: Icons.bar_chart,
        text: '$tested published item${tested != 1 ? 's' : ''} awaiting metrics',
        onTap: widget.onInsights,
      ));
    }

    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reminders', style: AppText.section),
        Gap.s,
        ...reminders,
      ],
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _PipelineCard(this.label, this.count, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: onTap,
      fillColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.screenTitle.copyWith(fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.hint),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ReminderItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: AppText.body)),
              Icon(Icons.chevron_right, size: 16, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
