import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'day14_posts.dart';
import 'quick_content.dart';
import 'theme.dart';

class CreatorHomeScreen extends StatefulWidget {
  final VoidCallback onMakeReel;
  final VoidCallback onQuickPost;
  final VoidCallback onIdeas;
  final VoidCallback onSavedStories;

  const CreatorHomeScreen({
    super.key,
    required this.onMakeReel,
    required this.onQuickPost,
    required this.onIdeas,
    required this.onSavedStories,
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
            const Text('Profile promotion comments', style: AppText.screenTitle),
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
                    setState(() {
                      _filterBucket = bucketId;
                    });
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
          if (_filterBucket.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _filterBucket = '';
              }),
              child: const Text('Clear', style: TextStyle(color: AppColors.textSoft)),
            ),
          IconButton(
            tooltip: 'Saved stories',
            icon: const Icon(Icons.folder_open),
            onPressed: widget.onSavedStories,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const Text('What are you creating today?', style: AppText.screenTitle),
          Gap.s,
          const Text('Choose a starting point. Your work stays saved in the app.', style: AppText.hint),
          Gap.l,
          _ActionCard(
            icon: Icons.movie_creation_outlined,
            colour: AppColors.primary,
            title: 'Make a reel',
            subtitle: 'Story, script, pictures, voice and final video',
            onTap: widget.onMakeReel,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.article_outlined,
            colour: AppColors.accent,
            title: 'Create a quick post',
            subtitle: 'Carousel, static image, caption and comments',
            onTap: widget.onQuickPost,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.lightbulb_outline,
            colour: AppColors.warning,
            title: 'Browse ideas',
            subtitle: 'Use a complete hook and story structure',
            onTap: widget.onIdeas,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.forum_outlined,
            colour: AppColors.accent,
            title: 'Profile promotion comments',
            subtitle: 'Open all saved comments and copy one for another post',
            onTap: _showPromotionComments,
          ),
          if (_comments.isNotEmpty) ...[
            Gap.l,
            const SectionTitle('Your promotion comments'),
            Gap.s,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterBucket.isEmpty,
                  onSelected: (v) => setState(() {
                    _filterBucket = '';
                  }),
                ),
                ...kContentBuckets.map((b) => FilterChip(
                  label: Text(b.shortLabel),
                  selected: _filterBucket == b.id,
                  onSelected: (v) => setState(() {
                    _filterBucket = v ? b.id : '';
                  }),
                  backgroundColor: b.softColor,
                  selectedColor: b.color.withOpacity(0.3),
                  checkmarkColor: b.color,
                )),
              ],
            ),
            Gap.m,
            ..._filteredComments.map((comment) => _CommentRow(
                  text: comment.text,
                  bucket: comment.bucket,
                  onCopy: () => _copyComment(comment.text),
                  onBucketFilter: (bucketId) {
                    setState(() => _filterBucket = bucketId);
                  },
                )),
          ],
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String text;
  final String bucket;
  final VoidCallback onCopy;
  final void Function(String bucketId)? onBucketFilter;
  final String? filterBucket;

  const _CommentRow({
    required this.text,
    this.bucket = '',
    required this.onCopy,
    this.onBucketFilter,
    this.filterBucket,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (bucket.isNotEmpty && onBucketFilter != null)
              GestureDetector(
                onTap: () => onBucketFilter!(bucket),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bucketById(bucket)?.softColor ?? AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bucketById(bucket)?.color ?? AppColors.border),
                  ),
                  child: Text(bucketLabel(bucket),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: bucketById(bucket)?.color ?? AppColors.textSoft)),
                ),
              ),
            Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.hint)),
            IconButton(tooltip: 'Copy comment', onPressed: onCopy, icon: const Icon(Icons.copy_outlined, size: 18)),
          ],
        ),
      );
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colour.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colour, size: 26),
              ),
              Gap.wM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
                    Gap.xs,
                    Text(subtitle, style: AppText.hint),
                  ],
                )),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
