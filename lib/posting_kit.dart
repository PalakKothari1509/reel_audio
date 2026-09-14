import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'plan_data.dart';
import 'projects.dart';
import 'prompt_builder.dart';
import 'prompts.dart';
import 'reply_assistant.dart';
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

    // From your own schedule rather than the time Gemini makes up for each reel: one
    // table you control and can check against results, instead of a new guess per post.
    final nextSlot = nextPostingTime(await ScheduleStore.load());

    final options = <String, List<String>>{};
    var storyContext = '';

    if (project != null && project.promptsJson.isNotEmpty) {
      try {
        final post = promptsFromSaved(project.promptsJson, project.promptsScript).post;
        storyContext = [
          project.title,
          if (post.moralLine.isNotEmpty) 'Lesson: ${post.moralLine}',
        ].join('. ');

        // The things drawn onto the reel first, because they have to be settled before
        // it is built; then what gets pasted into Instagram, in the order it is pasted.
        items.addAll([
          _Item('cover_hook', 'Hook', 'Drawn big on picture 1 — pick below',
            post.coverHook.isEmpty ? post.coverTitle : post.coverHook),
          _Item('last_screen', 'Ending', 'The line on the closing card, under Little '
            'Stories, Big Lessons ❤️ — pick below', defaultEnding(post)),
          _Item('cover_title', 'Cover title', 'For the reel cover in Instagram',
            post.coverTitle),
          _Item('caption', 'Caption', 'Paste as the post caption, hashtags included',
            post.forInstagram),
          _Item('hashtags', 'Hashtags', 'Also inside the caption above',
            post.hashtags.join(' ')),
          _Item('pin_comment', 'Pinned comment', 'Post it yourself, then pin it — pick below',
            // The first of the five when there are five, so one is always marked as
            // chosen; the single older suggestion for stories written before them.
            post.pinCommentOptions.isNotEmpty ? post.pinCommentOptions.first : post.pinComment),
          _Item('reply_question', 'A reply to start with', 'For your first few comments',
            post.replyQuestion),
          _Item('best_time', 'When to post', 'Next slot from your schedule in Plan',
            nextSlot.isEmpty ? post.bestTime : nextSlot),
        ]);

        options['cover_hook'] = [
          for (final h in post.coverHookOptions) h.text,
        ];
        _hookTypes = {for (final h in post.coverHookOptions) h.text: h.type};
        options['pin_comment'] = post.pinCommentOptions;
        options['last_screen'] = post.endingOptions;
      } catch (_) {}
    }
    _options = options;
    _storyContext = storyContext;

    final posts = await PostLogStore.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _edits = Map.of(project?.edits ?? const {});
      _title = project?.title ?? 'Reel';
      _posted = posts.any((p) => p.projectId == widget.projectId);
      _loading = false;
    });
  }

  String _title = 'Reel';
  bool _posted = false;
  Map<String, List<String>> _options = {};
  Map<String, String> _hookTypes = {};
  String _storyContext = '';

  /// Makes one of the offered options the chosen one. Saved as an edit, which is what
  /// the reel's cover, its closing card and this sheet all read — so choosing here is
  /// choosing everywhere.
  Future<void> _use(_Item item, String value) async {
    setState(() => _edits[item.field] = value);
    await _saveField(item.field, value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(item.field == 'pin_comment'
          ? 'Pinned comment chosen.'
          : '${item.title} chosen. Rebuild the reel to see it on the video.')));
  }

  /// Saves one field, merged into the edits as they are on disk now. Writing this
  /// sheet's whole copy back would undo a cover picked on the Script step meanwhile.
  Future<void> _saveField(String field, String value) =>
      ProjectStore.update(widget.projectId, (p) {
        final edits = {...p.edits};
        if (value.isEmpty) {
          edits.remove(field);
        } else {
          edits[field] = value;
        }
        return p.copyWith(edits: edits);
      });

  /// Logs that this reel went out now, so its numbers can be added in Plan later and
  /// the times that work start to show. The time is taken from the tap, which is why
  /// the button is meant to be pressed right after posting.
  Future<void> _markPosted() async {
    await PostLogStore.add(PostRecord(
      id: 'post${DateTime.now().millisecondsSinceEpoch}',
      title: _title,
      projectId: widget.projectId,
      postedAt: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() => _posted = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Logged. Add its views and saves in Plan → Results in two days.')));
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

    await _saveField(item.field, result.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final replyButton = SizedBox(
      width: double.infinity,
      child: SecondaryButton(
        label: 'Reply to a comment',
        icon: Icons.chat_bubble_outline,
        onPressed: () => showReplyAssistant(context, storyContext: _storyContext),
      ),
    );

    if (_items.isEmpty) {
      return ListView(controller: widget.scroll, padding: const EdgeInsets.all(24), children: [
        const Text('No caption yet', style: AppText.screenTitle),
        Gap.s,
        const Text('This story has no caption or comments written down. Open AI prompts '
            'from the Pictures step once and they are saved from then on.',
            style: AppText.hint),
        Gap.l,
        replyButton,
      ]);
    }

    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text('Posting kit', style: AppText.screenTitle),
        Gap.xs,
        const Text('Pick the hook, ending and pinned comment, then copy and paste into '
            'Instagram. Nothing here uses a request, except Reply to a comment.',
          style: AppText.hint),
        Gap.m,
        replyButton,
        Gap.s,
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _posted ? null : _markPosted,
            icon: Icon(_posted ? Icons.check : Icons.send, size: 18),
            label: Text(_posted ? 'Logged as posted' : 'I posted it'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
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
              // The alternatives, each one tap to choose. The chosen one is marked, so
              // it is clear what the reel and the post will actually use.
              if ((_options[item.field] ?? const []).isNotEmpty) ...[
                Gap.s,
                const Divider(height: 1, color: AppColors.border),
                Gap.s,
                Text(item.field == 'cover_hook' ? 'Hook options'
                    : item.field == 'last_screen' ? 'Ending options' : 'Other options',
                  style: AppText.section),
                Gap.xs,
                ..._options[item.field]!.map((option) {
                  final chosen = option == _text(item);
                  final type = item.field == 'cover_hook' ? _hookTypes[option] : null;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Icon(chosen ? Icons.check_circle : Icons.circle_outlined,
                        size: 18, color: chosen ? AppColors.primary : AppColors.textFaint),
                      Gap.wS,
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(option, style: TextStyle(fontSize: 14, height: 1.35,
                          fontWeight: chosen ? FontWeight.w700 : FontWeight.w400,
                          color: AppColors.text)),
                        if (type != null && type.isNotEmpty)
                          Text(type, style: AppText.small),
                      ])),
                      if (!chosen)
                        TextButton(
                          onPressed: () => _use(item, option),
                          child: const Text('Use this')),
                    ]),
                  );
                }),
              ],
            ]),
          ),
        )),
      ],
    );
  }
}

/// What the closing card says when no ending has been chosen.
///
/// The first offered ending when there are options. Stories written before endings
/// were offered keep the question-and-save lines they always had, so their saved reels
/// still match and are not rebuilt for no reason.
String defaultEnding(PostDetails post) {
  if (post.endingOptions.isNotEmpty) return post.endingOptions.first;
  return [
    if (post.endQuestion.isNotEmpty) post.endQuestion,
    post.ctaLine.isNotEmpty ? post.ctaLine : kDefaultCtaLine,
  ].join('\n\n');
}
