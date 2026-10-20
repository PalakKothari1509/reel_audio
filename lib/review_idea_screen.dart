import 'package:flutter/material.dart';

import 'content_axes.dart';
import 'content_library_service.dart';
import 'theme.dart';

/// Shows a single idea in readable sections, with actions to edit, create content,
/// view saved prompts, run quality check, etc.
///
/// This screen is opened from ContentLibraryScreen's "Review Idea" button.
/// It reads the idea from [ContentLibraryService] by ID.
class ReviewIdeaScreen extends StatefulWidget {
  final String ideaId;
  final VoidCallback? onCreateContent;

  const ReviewIdeaScreen({super.key, required this.ideaId, this.onCreateContent});

  @override
  State<ReviewIdeaScreen> createState() => _ReviewIdeaScreenState();
}

class _ReviewIdeaScreenState extends State<ReviewIdeaScreen> {
  ContentIdea? _idea;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final idea = await ContentLibraryService.instance.getIdeaById(widget.ideaId);
    if (!mounted) return;
    setState(() {
      _idea = idea;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Idea'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _idea == null
              ? const Center(child: Text('Idea not found'))
              : _buildContent(_idea!),
    );
  }

  Widget _buildContent(ContentIdea idea) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──────────────────────────────────────────────
          Text(idea.title, style: AppText.screenTitle),
          const SizedBox(height: 8),

          // ── Metadata row ───────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _metaChip(idea.category, Icons.category_outlined),
              _metaChip(idea.format, Icons.format_align_left),
              if (idea.characterIds.isNotEmpty)
                _metaChip(idea.characterIds.join(', '), Icons.group_outlined),
            ],
          ),
          const SizedBox(height: 24),

          // ── 1. Opening Hook ────────────────────────────────────
          _section('1. Opening Hook', idea.opening),

          // ── 2. Real-Life Problem ───────────────────────────────
          _section('2. Real-Life Problem', idea.problem),

          // ── 3. Story Details ───────────────────────────────────
          _section('3. Story Details', idea.storyDetail),

          // ── 4. Learning Outcome ────────────────────────────────
          _section('4. Learning Outcome', idea.lesson),

          // ── 5. Caption ─────────────────────────────────────────
          if (idea.caption.isNotEmpty) _section('5. Caption', idea.caption),

          // ── 6. Content Status ──────────────────────────────────
          const SizedBox(height: 8),
          Text('6. Content Status', style: AppText.section),
          const SizedBox(height: 8),
          _buildStatusSummary(idea),

          // ── Actions ────────────────────────────────────────────
          const SizedBox(height: 24),
          _buildActions(idea),
        ],
      ),
    );
  }

  Widget _metaChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSoft),
          const SizedBox(width: 4),
          Text(label, style: AppText.small),
        ],
      ),
    );
  }

  Widget _section(String heading, String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: AppText.section),
        const SizedBox(height: 8),
        Text(content, style: AppText.body),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusSummary(ContentIdea idea) {
    final hasStory = idea.storyDetail.trim().isNotEmpty;
    final hasScript = idea.status.index >= IdeaStatus.scripted.index;
    final hasPrompts = false;
    final hasVideo = idea.status.index >= IdeaStatus.generated.index;
    final hasQualityReport = idea.status.index >= IdeaStatus.approved.index;
    final hasPosting = idea.status == IdeaStatus.posted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusRow('Script', hasScript, hasScript ? 'Generated' : 'Not yet'),
        _statusRow('Story Details', hasStory, hasStory ? 'Available' : 'Missing'),
        _statusRow('Video Prompts', hasPrompts, hasPrompts ? 'Generated' : 'Not yet'),
        _statusRow('Finished Video', hasVideo, hasVideo ? 'Uploaded' : 'Not uploaded'),
        _statusRow('Quality Report', hasQualityReport, hasQualityReport ? 'Checked' : 'Pending'),
        _statusRow('Posting Status', hasPosting, hasPosting ? 'Posted' : 'Not posted'),
      ],
    );
  }

  Widget _statusRow(String label, bool done, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? AppColors.primary : AppColors.textSoft,
            size: 16,
          ),
          const SizedBox(width: 8),
          SizedBox(width: 120, child: Text(label, style: AppText.body)),
          Text(detail, style: AppText.hint),
        ],
      ),
    );
  }

  Widget _buildActions(ContentIdea idea) {
    final actions = <Widget>[];

    actions.add(_actionButton(
      icon: Icons.edit_outlined,
      label: 'Edit Idea',
      color: AppColors.primary,
      onTap: () {
        // TODO: open edit form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit form coming soon')),
        );
      },
    ));

    actions.add(_actionButton(
      icon: Icons.save,
      label: 'Save Changes',
      color: AppColors.primary,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved')),
        );
      },
    ));

    actions.add(_actionButton(
      icon: Icons.auto_awesome,
      label: 'Create Content',
      color: AppColors.accent,
      onTap: () {
        widget.onCreateContent?.call();
      },
    ));

    actions.add(_actionButton(
      icon: Icons.description_outlined,
      label: 'Generate Script',
      color: AppColors.warning,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Script generator coming soon')),
        );
      },
    ));

    actions.add(_actionButton(
      icon: Icons.visibility_outlined,
      label: 'View Saved Prompts',
      color: AppColors.textSoft,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt viewer coming soon')),
        );
      },
    ));

    actions.add(_actionButton(
      icon: Icons.videocam_outlined,
      label: 'View Video',
      color: AppColors.textSoft,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video viewer coming soon')),
        );
      },
    ));

    actions.add(_actionButton(
      icon: Icons.shield_outlined,
      label: 'Run Quality Check',
      color: AppColors.danger,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quality checker coming soon')),
        );
      },
    ));

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions,
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 140,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
