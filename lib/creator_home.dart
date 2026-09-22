import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  List<String> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await PromoCommentStore.load();
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
    final comments = await PromoCommentStore.load();
    final input = TextEditingController();
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
              decoration: const InputDecoration(hintText: 'Add your own reusable comment...'),
            ),
            Gap.s,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save comment'),
                onPressed: () async {
                  final text = input.text.trim();
                  if (text.isEmpty || comments.contains(text)) return;
                  comments.insert(0, text);
                  await PromoCommentStore.save(comments);
                  input.clear();
                  setSheetState(() {});
                  if (mounted) setState(() => _comments = List.of(comments));
                },
              ),
            ),
            Gap.m,
            ...comments.map((comment) => _CommentRow(
                  text: comment,
                  onCopy: () => _copyComment(comment),
                )),
          ],
        ),
      ),
      ),
    );
    input.dispose();
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
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String text;
  final VoidCallback onCopy;

  const _CommentRow({required this.text, required this.onCopy});

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
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
