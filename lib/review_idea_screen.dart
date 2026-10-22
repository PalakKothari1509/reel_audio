import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'content_axes.dart';
import 'content_library_service.dart';
import 'prompt_vault.dart';
import 'quality_check_center.dart';
import 'story_generator_offline.dart';
import 'theme.dart';
import 'video_library.dart';
import 'video_library_store.dart';

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
  String? _generatedScript;
  bool _isGeneratingScript = false;
  String _status = '';

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
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(child: CircularProgressIndicator()),
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(_status, style: AppText.hint),
                ],
              ],
            )
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
    final hasVideo = idea.status.index >= IdeaStatus.generated.index;
    final hasQualityReport = idea.status.index >= IdeaStatus.approved.index;
    final hasPosting = idea.status == IdeaStatus.posted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusRow('Script', hasScript, hasScript ? 'Generated' : 'Not yet'),
        _statusRow('Story Details', hasStory, hasStory ? 'Available' : 'Missing'),
         _statusRow('Video Prompts', true, 'See Prompt Vault'),
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
      onTap: () => _showEditDialog(idea),
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
      onTap: _isGeneratingScript ? null : () { _generateScript(idea); },
    ));

    if (_generatedScript != null && _generatedScript!.isNotEmpty) {
      actions.add(_actionButton(
        icon: Icons.visibility_outlined,
        label: 'View Script',
        color: AppColors.warning,
        onTap: () => _showScriptDialog(),
      ));
    }

    actions.add(_actionButton(
      icon: Icons.visibility_outlined,
      label: 'View Saved Prompts',
      color: AppColors.textSoft,
      onTap: () => _viewSavedPrompts(idea.id),
    ));

    actions.add(_actionButton(
      icon: Icons.videocam_outlined,
      label: 'View Video',
      color: AppColors.textSoft,
      onTap: () => _viewVideo(idea.id),
    ));

    actions.add(_actionButton(
      icon: Icons.shield_outlined,
      label: 'Run Quality Check',
      color: AppColors.danger,
      onTap: () => _runQualityCheck(idea),
    ));

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions,
    );
  }

  void _showEditDialog(ContentIdea idea) {
    final titleCtrl = TextEditingController(text: idea.title);
    final notesCtrl = TextEditingController(text: idea.notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Idea'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = idea.copyWith(
                title: titleCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              await ContentLibraryService.instance.updateIdea(updated);
              setState(() => _idea = updated);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Idea updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateScript(ContentIdea idea) async {
    setState(() {
      _isGeneratingScript = true;
      _status = 'Generating script...';
    });
    try {
      final generator = StoryGenerator();
      final story = await generator.generateFromIdea(idea);
      final script = _formatScript(story);
      setState(() {
        _generatedScript = script;
        _isGeneratingScript = false;
        _status = '';
      });
      if (!mounted) return;
      _showScriptDialog();
    } catch (e) {
      setState(() {
        _isGeneratingScript = false;
        _status = '❌ $e';
      });
    }
  }

  String _formatScript(GeneratedStory story) {
    final buffer = StringBuffer();
    buffer.writeln('Title: ${story.title}');
    buffer.writeln('Hook: ${story.hook}');
    buffer.writeln('Characters: ${story.cast.join(', ')}');
    buffer.writeln('Setting: ${story.setting}');
    buffer.writeln();
    buffer.writeln('Problem: ${story.problem}');
    buffer.writeln('Twist: ${story.twist}');
    buffer.writeln('Worse: ${story.worse}');
    buffer.writeln('Solution: ${story.solution}');
    buffer.writeln('Ending: ${story.endingLine}');
    buffer.writeln('Moral: ${story.moral}');
    return buffer.toString();
  }

  void _showScriptDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generated Script'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              _generatedScript ?? '',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _generatedScript ?? ''));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Script copied')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewSavedPrompts(String contentId) async {
    final prompts = await PromptVault.getByContentId(contentId);
    if (prompts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved prompts for this idea')),
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saved Prompts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.separated(
            itemCount: prompts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final p = prompts[i];
              return ListTile(
                title: Text(p.title, style: const TextStyle(fontSize: 13)),
                subtitle: Text('${p.type.name} • v${p.version}'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: p.promptText));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Prompt copied')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _viewVideo(String contentId) async {
    final videos = await VideoLibrary.getByContentId(contentId);
    if (videos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No videos saved for this idea')),
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Videos'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.separated(
            itemCount: videos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final v = videos[i];
              return ListTile(
                leading: const Icon(Icons.videocam_outlined, size: 28),
                title: Text(v.title, style: const TextStyle(fontSize: 13)),
                subtitle: Text('${v.status.label} • v${v.version} • ${v.aspectRatio}'),
                trailing: Text(
                  v.uploadedAt != null
                      ? 'Uploaded'
                      : v.postedAt != null
                          ? 'Posted'
                          : 'Draft',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _runQualityCheck(ContentIdea idea) async {
    setState(() {
      _loading = true;
      _status = 'Running quality check...';
    });
    try {
      final report = QualityCheckCenter.checkScript(
        contentId: idea.id,
        version: 1,
        title: idea.title,
        scriptText: idea.storyDetail,
      );
      await QualityCheckCenter.save(report);
      setState(() => _loading = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Text(report.overallStatus),
              const SizedBox(width: 8),
              Text(
                '${report.passCount}/${report.findings.length} passed',
                style: const TextStyle(fontSize: 14, color: AppColors.textSoft),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: report.findings.length,
              itemBuilder: (ctx, i) {
                final f = report.findings[i];
                return ListTile(
                  leading: Icon(
                    f.passed ? Icons.check_circle : Icons.warning,
                    color: f.passed ? AppColors.success : _severityColor(f.severity),
                    size: 20,
                  ),
                  title: Text(f.checkName, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(f.message, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Quality check failed: $e')),
      );
    }
  }

  Color _severityColor(FindingSeverity s) {
    return switch (s) {
      FindingSeverity.critical => AppColors.danger,
      FindingSeverity.major => AppColors.warning,
      FindingSeverity.minor => AppColors.textSoft,
      FindingSeverity.suggestion => AppColors.accent,
    };
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
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
