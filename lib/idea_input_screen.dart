import 'package:flutter/material.dart';

import 'characters.dart';
import 'content_collections.dart';
import 'content_ideas.dart';
import 'theme.dart';

// ── Shared idea input screen ──────────────────────────────────────────────────
//
// All four features start here: enter or select an idea, pick characters, add
// optional instructions, then tap the feature-specific generate button.

enum ContentFeature {
  reelFromImages('🎬 Reel from Images', 'Complete Reel script and scene prompts'),
  imagePrompt('🖼️ Image Generation Prompt', 'One detailed image-generation prompt'),
  carouselPrompts('🎠 Carousel Generation', 'Complete prompts for all slides'),
  geminiVideo('🎬 Gemini Story Video', 'Connected 10-second video prompts');

  final String label;
  final String description;
  const ContentFeature(this.label, this.description);
}

class IdeaInputScreen extends StatefulWidget {
  final ContentFeature feature;

  /// Called when the user taps Generate. Receives the idea text, selected
  /// character names, and additional instructions. If a hook with a
  /// pre-built viral prompt was selected, [readyPrompt] contains it.
  final void Function({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
    String? readyPrompt,
  }) onGenerate;

  /// Optional: called when user taps "Show Prompt Only" — builds and displays
  /// the prompt without sending to Gemini.
  final void Function({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  })? onGeneratePromptOnly;

  /// Extra controls specific to the feature (e.g. slide count, duration).
  final Widget? extraControls;

  /// Pre-fills the idea field. Used when returning from the review screen.
  final String? initialText;

  const IdeaInputScreen({
    super.key,
    required this.feature,
    required this.onGenerate,
    this.onGeneratePromptOnly,
    this.extraControls,
    this.initialText,
  });

  @override
  State<IdeaInputScreen> createState() => _IdeaInputScreenState();
}

class _IdeaInputScreenState extends State<IdeaInputScreen> {
  final _ideaCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();
  final List<String> _selectedChars = ['ria', 'rio', 'cuty'];

  HookIdea? _selectedHook;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) _ideaCtrl.text = widget.initialText!;
  }

  @override
  void dispose() {
    _ideaCtrl.dispose();
    _instrCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromLibrary() async {
    final hook = await showModalBottomSheet<HookIdea>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => _LibraryPicker(),
    );
    if (hook == null || !mounted) return;
    setState(() {
      _selectedHook = hook;
      _ideaCtrl.text = '${hook.cover}\n\n${hook.opening}\n\n'
          'Problem: ${hook.problem}\nLesson: ${hook.lesson}';
      if (hook.storyDetail.trim().isNotEmpty) {
        _ideaCtrl.text += '\n\n${hook.storyDetail.trim()}';
      }
      if (hook.defaultCast.isNotEmpty) {
        _selectedChars
          ..clear()
          ..addAll(hook.defaultCast.map((c) => c.toLowerCase()));
      }
    });
  }

  void _generate() {
    final idea = _ideaCtrl.text.trim();
    if (idea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter or select an idea first.')),
      );
      return;
    }
    final chars = _selectedChars.isEmpty
        ? ['ria', 'rio', 'cuty']
        : List<String>.from(_selectedChars);
    final readyPrompt = _selectedHook?.readyPrompt.trim() ?? '';
    widget.onGenerate(
      idea: idea,
      characters: chars,
      additionalInstructions: _instrCtrl.text.trim(),
      readyPrompt: readyPrompt.isNotEmpty ? readyPrompt : null,
    );
  }

  void _showPromptOnly() {
    if (widget.onGeneratePromptOnly == null) return;
    final idea = _ideaCtrl.text.trim();
    if (idea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter or select an idea first.')),
      );
      return;
    }
    final chars = _selectedChars.isEmpty
        ? ['ria', 'rio', 'cuty']
        : List<String>.from(_selectedChars);
    widget.onGeneratePromptOnly!(
      idea: idea,
      characters: chars,
      additionalInstructions: _instrCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.feature.label)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const SizedBox(height: 12),
                Text(widget.feature.description, style: AppText.hint),
                const SizedBox(height: 20),

                // ── Idea input ──────────────────────────────────────────────
                const Text('Idea', style: AppText.section),
                const SizedBox(height: 8),
                TextField(
                  controller: _ideaCtrl,
                  maxLines: 5,
                  minLines: 3,
                  style: AppText.body,
                  decoration: InputDecoration(
                    hintText: 'e.g. Rio refuses to put away his toys. '
                        'Cuty helps him understand that toys belong in their proper places.',
                    hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickFromLibrary,
                    icon: const Icon(Icons.library_books_outlined, size: 18),
                    label: const Text('Select from Content Library'),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Characters ──────────────────────────────────────────────
                const Text('Characters', style: AppText.section),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCharacterOptions.map((c) {
                    final selected = _selectedChars.contains(c.id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedChars.remove(c.id);
                        } else {
                          _selectedChars.add(c.id);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.emoji),
                            const SizedBox(width: 6),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected ? Colors.white : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Feature-specific controls ───────────────────────────────
                if (widget.extraControls != null) ...[
                  widget.extraControls!,
                  const SizedBox(height: 20),
                ],

                // ── Additional instructions ─────────────────────────────────
                const Text('Additional instructions (optional)', style: AppText.section),
                const SizedBox(height: 8),
                TextField(
                  controller: _instrCtrl,
                  maxLines: 3,
                  minLines: 2,
                  style: AppText.body,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Focus on Mumma\'s reaction. Use warm evening lighting.',
                    hintStyle: TextStyle(color: AppColors.textFaint, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // ── Generate button ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Generate',
                  icon: Icons.auto_awesome,
                  onPressed: _generate,
                ),
                if (widget.onGeneratePromptOnly != null) ...[
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Show Prompt Only',
                    icon: Icons.description,
                    onPressed: _showPromptOnly,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Content library picker ────────────────────────────────────────────────────

class _LibraryPicker extends StatefulWidget {
  @override
  State<_LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends State<_LibraryPicker> {
  String _filter = '';
  final _ctrl = TextEditingController();
  String? _selectedCollection;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<HookIdea> get _filtered {
    final q = _filter.toLowerCase();
    return kDefaultHooksWithRewrite
        .where((h) =>
            (_selectedCollection == null ||
                collectionOf(h.id, custom: h.custom) == _selectedCollection) &&
            (q.isEmpty ||
                h.cover.toLowerCase().contains(q) ||
                h.opening.toLowerCase().contains(q) ||
                h.problem.toLowerCase().contains(q) ||
                h.category.toLowerCase().contains(q)))
        .toList();
  }

  Map<String, List<HookIdea>> get _grouped {
    final map = <String, List<HookIdea>>{};
    for (final h in _filtered) {
      final c = collectionOf(h.id, custom: h.custom);
      (map[c] ??= []).add(h);
    }
    return map;
  }

  List<String> get _orderedKeys {
    final keys = <String>[];
    for (final c in kCollections) {
      if (_grouped.containsKey(c.id)) keys.add(c.id);
    }
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final orderedKeys = _orderedKeys;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _collectionChips(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search ideas...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _filter = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: grouped.isEmpty
                  ? _empty()
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orderedKeys.length,
                      itemBuilder: (ctx, i) {
                        final collectionId = orderedKeys[i];
                        final ideas = grouped[collectionId]!;
                        return ExpansionTile(
                          key: PageStorageKey('col-$collectionId'),
                          title: Text(
                            '${kCollectionById[collectionId]?.emoji ?? '✏️'} '
                            '${kCollectionById[collectionId]?.label ?? 'My Ideas'} '
                            '(${ideas.length})',
                            style: const TextStyle(fontSize: 14),
                          ),
                          children: [
                            for (final h in ideas) _ideaTile(ctx, h),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
    );
  }

  Widget _collectionChips() {
    final counts = <String, int>{};
    for (final h in _filtered) {
      final c = collectionOf(h.id, custom: h.custom);
      counts[c] = (counts[c] ?? 0) + 1;
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          _collectionChip(
              null, 'All', _filtered.length, _selectedCollection == null),
          for (final c in kCollections)
            if (counts[c.id] != null || c.id == 'mine' || c.id == 'safety')
              _collectionChip(
                c.id,
                '${c.emoji} ${c.label}',
                counts[c.id] ?? 0,
                _selectedCollection == c.id,
                dimmed: c.id == 'safety',
              ),
        ],
      ),
    );
  }

  Widget _collectionChip(
    String? value,
    String label,
    int count,
    bool selected, {
    bool dimmed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(count == 0 && value != null ? label : '$label ($count)'),
        selected: selected,
        onSelected: (_) =>
            setState(() => _selectedCollection = selected ? null : value),
        disabledColor: dimmed ? Colors.grey.shade300 : null,
        labelStyle: TextStyle(
          color: dimmed && !selected ? Colors.grey : null,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _ideaTile(BuildContext ctx, HookIdea h) {
    final hasReadyPrompt = h.readyPrompt.trim().isNotEmpty;
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Row(
        children: [
          Text(
            h.cover,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (hasReadyPrompt) ...[
            const SizedBox(width: 6),
            const Icon(Icons.rocket_launch, size: 14, color: AppColors.accent),
          ],
        ],
      ),
      subtitle: Text(
        h.opening,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppText.small,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasReadyPrompt)
            const Tooltip(
              message: 'Ready-to-post viral prompt',
              child: Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
            ),
          const SizedBox(width: 8),
          Text(
            h.category,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textFaint),
          ),
        ],
      ),
      onTap: () => Navigator.pop(ctx, h),
    );
  }

  Widget _empty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No matching ideas'),
        ),
      );
}
