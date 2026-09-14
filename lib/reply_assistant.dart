import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'story_ideas.dart';
import 'theme.dart';

// ── Reply assistant ───────────────────────────────────────────────────────────
//
// Paste a comment someone left, see what kind of comment it is, and pick from five
// replies written for that kind. One request per comment, and only when you press
// the button — nothing is sent while you are typing.

/// Opens the assistant as a sheet. [storyContext] is the reel's title and lesson when
/// opened from a story, so replies can mention what happened in it.
Future<void> showReplyAssistant(BuildContext context, {String storyContext = ''}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ReplyAssistant(
          storyContext: storyContext, scroll: scroll),
      ),
    );

class ReplyAssistant extends StatefulWidget {
  final String storyContext;
  final ScrollController? scroll;
  const ReplyAssistant({super.key, this.storyContext = '', this.scroll});

  @override
  State<ReplyAssistant> createState() => _ReplyAssistantState();
}

class _ReplyAssistantState extends State<ReplyAssistant> {
  final _comment = TextEditingController();
  ReplySuggestions? _result;
  bool _busy = false;
  String _status = '';

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _status = ''; _result = null; });
    try {
      final result = await suggestReplies(_comment.text,
        storyContext: widget.storyContext,
        onWait: (m) { if (mounted) setState(() => _status = m); });
      if (!mounted) return;
      setState(() { _result = result; _busy = false; _status = ''; });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _status = '❌ $e'; });
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Reply copied — paste it under the comment'),
      duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const Text('Reply to a comment', style: AppText.screenTitle),
        Gap.xs,
        const Text('Paste the comment. The app works out what kind of comment it is and '
            'writes five replies that suit it. Uses one request.', style: AppText.hint),
        Gap.m,
        TextField(
          controller: _comment,
          minLines: 2,
          maxLines: 6,
          style: AppText.body,
          decoration: const InputDecoration(
            hintText: 'e.g. My daughter does this every day 😂'),
        ),
        Gap.s,
        PrimaryButton(
          label: _busy ? 'Writing replies...' : 'Suggest replies',
          icon: Icons.chat_bubble_outline,
          loading: _busy,
          onPressed: _generate,
        ),
        Gap.s,
        StatusBar(message: _status),
        if (r != null) ...[
          Row(children: [
            const Text('Type: ', style: AppText.hint),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20)),
              child: Text(r.type, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
          if (r.note.isNotEmpty) ...[
            Gap.s,
            AppCard(
              colour: AppColors.accentSoft,
              borderColour: AppColors.accent,
              child: Text(r.note, style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ],
          Gap.m,
          ...r.replies.map((reply) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Row(children: [
                Expanded(child: SelectableText(reply, style: AppText.body)),
                Gap.wS,
                FilledButton.tonalIcon(
                  onPressed: () => _copy(reply),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Use this'),
                ),
              ]),
            ),
          )),
          Gap.s,
          Center(child: TextButton.icon(
            onPressed: _busy ? null : _generate,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Five different ones (uses a request)'),
          )),
        ],
      ],
    );
  }
}
