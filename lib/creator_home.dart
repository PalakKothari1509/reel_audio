import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'day14_posts.dart';
import 'quick_content.dart';
import 'theme.dart';

class CreatorHomeScreen extends StatefulWidget {
  final VoidCallback onReel;
  final VoidCallback onTrialReel;
  final VoidCallback onCarousel;
  final VoidCallback onSingleImage;
  final VoidCallback onMultiFormat;
  final VoidCallback onIdeaVault;
  final VoidCallback onSavedStories;
  final VoidCallback onSettings;

  const CreatorHomeScreen({
    super.key,
    required this.onReel,
    required this.onTrialReel,
    required this.onCarousel,
    required this.onSingleImage,
    required this.onMultiFormat,
    required this.onIdeaVault,
    required this.onSavedStories,
    required this.onSettings,
  });

  @override
  State<CreatorHomeScreen> createState() => _CreatorHomeScreenState();
}

class _CreatorHomeScreenState extends State<CreatorHomeScreen> {
  List<PromoComment> _comments = [];
  String _filterBucket = '';

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await PromoCommentStore.loadWithBuckets();
    if (mounted) setState(() => _comments = comments);
  }

  Future<void> _copyComment(String comment) async {
    await Clipboard.setData(ClipboardData(text: comment));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment copied'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _showPromotionComments() async {
    final input = TextEditingController();
    String selectedBucket = '';
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const Text('Promotion Comments', style: AppText.screenTitle),
              Gap.s,
              const Text('Choose a comment that fits the other creator\'s post, then copy it directly.', style: AppText.hint),
              Gap.m,
              TextField(
                controller: input,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add your own reusable comment...',
                  suffix: DropdownButton<String>(
                    value: selectedBucket.isEmpty ? null : selectedBucket,
                    hint: const Text('Bucket'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('None')),
                      ...kContentBuckets.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Row(children: [
                          Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: b.color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(b.shortLabel),
                        ]),
                      )),
                    ],
                    onChanged: (v) => setSheetState(() => selectedBucket = v ?? ''),
                  ),
                ),
              ),
              Gap.s,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save comment'),
                  onPressed: () async {
                    final text = input.text.trim();
                    if (text.isEmpty || _comments.any((c) => c.normalizedText == text)) return;
                    final comment = PromoComment(text: text, bucket: selectedBucket);
                    await PromoCommentStore.add(comment);
                    input.clear();
                    setSheetState(() {});
                    if (mounted) setState(() => _loadComments());
                  },
                ),
              ),
              Gap.m,
              if (_filterBucket.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Showing: ${bucketLabel(_filterBucket)} bucket only',
                      style: AppText.hint),
                ),
              ..._filteredComments.map((comment) => _CommentRow(
                    text: comment.text,
                    bucket: comment.bucket,
                    onCopy: () => _copyComment(comment.text),
                    onBucketFilter: (bucketId) {
                      setState(() => _filterBucket = bucketId);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
    input.dispose();
  }

  List<PromoComment> get _filteredComments {
    if (_filterBucket.isEmpty) return _comments;
    return _comments.where((c) => c.bucket == _filterBucket).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fun Learning With Palak'),
        actions: [
          IconButton(
            tooltip: 'Saved stories',
            icon: const Icon(Icons.folder_open),
            onPressed: widget.onSavedStories,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          const Text('What are you creating today?', style: AppText.screenTitle),
          Gap.s,
          const Text('Choose a starting point. Your work stays saved in the app.', style: AppText.hint),
          Gap.l,
          _ActionCard(
            icon: Icons.auto_awesome,
            colour: AppColors.primary,
            title: 'Create Content',
            subtitle: 'One idea → Carousel, Reel, Trial Reel, Image (all at once)',
            onTap: widget.onMultiFormat,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.movie_creation_outlined,
            colour: AppColors.accent,
            title: 'Reel',
            subtitle: 'Full reel workflow: story → script → images → voice → video',
            onTap: widget.onReel,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.play_circle_outline,
            colour: AppColors.accent,
            title: 'Trial Reel',
            subtitle: '60-sec compilation for non-follower reach (hook, fast cuts, CTA)',
            onTap: widget.onTrialReel,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.view_carousel_outlined,
            colour: AppColors.accent,
            title: 'Carousel',
            subtitle: 'Enter idea → get slide prompts for all carousel pages',
            onTap: widget.onCarousel,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.image_outlined,
            colour: AppColors.warning,
            title: 'Image',
            subtitle: 'Enter idea → get 7 different image prompts for Meta AI',
            onTap: widget.onSingleImage,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.lightbulb_outline,
            colour: AppColors.primary,
            title: 'Idea Vault',
            subtitle: 'Capture, organize & develop ideas (💡📝✅📤♻️)',
            onTap: widget.onIdeaVault,
          ),
          Gap.l,
          _ActionCard(
            icon: Icons.settings_outlined,
            colour: Colors.grey.shade600,
            title: 'Settings',
            subtitle: 'AI provider, API keys, defaults, export/import data',
            onTap: widget.onSettings,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _ActionCard(
          icon: Icons.forum_outlined,
          colour: AppColors.accent,
          title: 'Promotion Comments',
          subtitle: 'Section-wise comments for engaging with other creators',
          onTap: _showPromotionComments,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.colour,
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
            border: Border.all(color: colour.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colour.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: colour),
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
              Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String text;
  final String bucket;
  final VoidCallback onCopy;
  final ValueChanged<String> onBucketFilter;

  const _CommentRow({
    required this.text,
    required this.bucket,
    required this.onCopy,
    required this.onBucketFilter,
  });

  @override
  Widget build(BuildContext context) {
    final b = bucket.isNotEmpty ? bucketById(bucket) : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(text, style: AppText.body)),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onCopy,
                  tooltip: 'Copy',
                ),
              ],
            ),
            if (b != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: b.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(b.shortLabel, style: AppText.small.copyWith(color: b.color, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => onBucketFilter(b.id),
                    child: Text('Filter', style: TextStyle(color: b.color, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}