import 'package:flutter/material.dart';

import 'brand_system.dart';
import 'characters.dart';
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
  /// character names, and additional instructions.
  final void Function({
    required String idea,
    required List<String> characters,
    required String additionalInstructions,
  }) onGenerate;

  /// Extra controls specific to the feature (e.g. slide count, duration).
  final Widget? extraControls;

  const IdeaInputScreen({
    super.key,
    required this.feature,
    required this.onGenerate,
    this.extraControls,
  });

  @override
  State<IdeaInputScreen> createState() => _IdeaInputScreenState();
}

class _IdeaInputScreenState extends State<IdeaInputScreen> {
  final _ideaCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();
  final List<String> _selectedChars = ['ria', 'rio', 'cuty'];

  static const _allChars = [
    ('ria', 'Ria', '🌸'),
    ('rio', 'Rio', '💙'),
    ('cuty', 'Cuty', '🐰'),
    ('mumma', 'Mumma', '👩'),
    ('papa', 'Papa', '👨'),
  ];

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
      _ideaCtrl.text = '${hook.cover}\n\n${hook.opening}\n\n'
          'Problem: ${hook.problem}\nLesson: ${hook.lesson}';
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
    widget.onGenerate(
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
                  children: _allChars.map((c) {
                    final selected = _selectedChars.contains(c.$1);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedChars.remove(c.$1);
                        } else {
                          _selectedChars.add(c.$1);
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
                            Text(c.$3),
                            const SizedBox(width: 6),
                            Text(
                              c.$2,
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
            child: PrimaryButton(
              label: 'Generate',
              icon: Icons.auto_awesome,
              onPressed: _generate,
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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kDefaultHooks
        .where((h) =>
            _filter.isEmpty ||
            h.cover.toLowerCase().contains(_filter) ||
            h.opening.toLowerCase().contains(_filter) ||
            h.problem.toLowerCase().contains(_filter) ||
            h.category.toLowerCase().contains(_filter))
        .toList();

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final h = filtered[i];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  title: Text(
                    h.cover,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    h.opening,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small,
                  ),
                  trailing: Text(
                    h.category,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textFaint),
                  ),
                  onTap: () => Navigator.pop(ctx, h),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
