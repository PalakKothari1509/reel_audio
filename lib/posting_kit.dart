import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'projects.dart';
import 'prompt_builder.dart';
import 'theme.dart';

// ── Everything needed to post, in one sheet ───────────────────────────────────
//
// The caption, the pinned comment and the reply used to live only on the prompts
// screen, several steps back from the finished reel. So posting meant leaving the reel,
// walking back through the app, copying, and — because nothing about the reel was kept —
// building the whole thing again afterwards to get back to it.
//
// This opens over the reel instead. Read straight off the phone, so it costs nothing,
// and editable in place, with edits shared with the prompts screen so the two never
// disagree about what the caption says.

Future<void> showPostingKit(BuildContext context, String projectId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => _PostingKit(projectId: projectId, scroll: scroll),
      ),
    );

class _PostingKit extends StatefulWidget {
  final String projectId;
  final ScrollController scroll;
  const _PostingKit({required this.projectId, required this.scroll});

  @override
  State<_PostingKit> createState() => _PostingKitState();
}

class _Item {
  final String field;
  final String title;
  final String hint;
  final String generated;
  const _Item(this.field, this.title, this.hint, this.generated);
}

class _PostingKitState extends State<_PostingKit> {
  bool _loading = true;
  List<_Item> _items = [];
  Map<String, String> _edits = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final project = await loadProject(widget.projectId);
    final items = <_Item>[];

    if (project != null && project.promptsJson.isNotEmpty) {
      try {
        final post = promptsFromSaved(project.promptsJson, project.promptsScript).post;
        // In the order you actually use them: write the post, pin, then reply.
        items.addAll([
          _Item('caption', 'Caption', 'Paste as the post caption, hashtags included',
            post.forInstagram),
          _Item('pin_comment', 'Pin this comment', 'Post it yourself, then pin it',
            post.pinComment),
          _Item('reply_question', 'Reply to comments with', 'Ends in a question so the '
            'conversation carries on', post.replyQuestion),
          _Item('cover_hook', 'Cover hook', 'Already drawn on the reel — here for the '
            'cover title', post.coverHook.isEmpty ? post.coverTitle : post.coverHook),
          _Item('best_time', 'When to post', 'A starting point — your Insights know better',
            post.bestTime),
        ]);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _edits = Map.of(project?.edits ?? const {});
      _loading = false;
    });
  }

  String _text(_Item item) =>
      (_edits[item.field]?.trim().isNotEmpty == true) ? _edits[item.field]! : item.generated;

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$what copied'), duration: const Duration(seconds: 2)));
  }

  Future<void> _edit(_Item item) async {
    final ctrl = TextEditingController(text: _text(item));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${item.title.toLowerCase()}', style: const TextStyle(fontSize: 16)),
        content: TextField(controller: ctrl, maxLines: 10, minLines: 3, autofocus: true),
        actions: [
          if (_edits.containsKey(item.field))
            TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Reset')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (result.trim().isEmpty) {
        _edits.remove(item.field);
      } else {
        _edits[item.field] = result.trim();
      }
    });

    final project = await loadProject(widget.projectId);
    if (project != null) await ProjectStore.save(project.copyWith(edits: Map.of(_edits)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return ListView(controller: widget.scroll, padding: const EdgeInsets.all(24), children: const [
        Text('No caption yet', style: AppText.screenTitle),
        Gap.s,
        Text('This story has no caption or comments written down. Open AI prompts from '
            'the Pictures step once and they are saved from then on.', style: AppText.hint),
      ]);
    }

    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text('Caption & comments', style: AppText.screenTitle),
        Gap.xs,
        const Text('Tap the copy icon, paste into Instagram. Nothing here uses a request.',
          style: AppText.hint),
        Gap.m,
        ..._items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(item.title, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                    if (_edits.containsKey(item.field)) ...[
                      const SizedBox(width: 6),
                      const Text('edited', style: TextStyle(fontSize: 11,
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                  Text(item.hint, style: AppText.small),
                ])),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _edit(item)),
                // The copy button is the big one: it is the reason this sheet exists.
                IconButton.filledTonal(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copy(_text(item), item.title)),
              ]),
              Gap.s,
              SelectableText(_text(item).isEmpty ? '—' : _text(item),
                style: AppText.body),
            ]),
          ),
        )),
      ],
    );
  }
}
