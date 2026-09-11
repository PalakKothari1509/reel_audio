import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'characters.dart';
import 'prompt_builder.dart';
import 'prompts.dart';

// ── Prompts screen ────────────────────────────────────────────────────────────
// Everything here is meant to be copied out and pasted into an image or video
// generator, so every block has its own copy button and nothing needs retyping.

class PromptScreen extends StatefulWidget {
  final String storyDescription;
  final List<String> scriptLines;
  final int seconds;

  const PromptScreen({
    super.key,
    required this.storyDescription,
    required this.scriptLines,
    required this.seconds,
  });

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  PromptSet? _prompts;
  List<CharacterRef> _cast = [];
  bool _loading = true;
  bool _withOverlay = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // The cast is on the phone already, so show it while Gemini is still thinking.
    _cast = await CharacterStore.load();
    if (mounted) setState(() {});

    try {
      final prompts = await generatePrompts(
        storyDescription: widget.storyDescription,
        scriptLines: widget.scriptLines,
        seconds: widget.seconds,
      );
      if (!mounted) return;
      setState(() { _prompts = prompts; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _pickFace(int index) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final saved = await CharacterStore.saveFace(_cast[index].name, picked.path);
    setState(() => _cast[index] = _cast[index].withImage(saved));
    await CharacterStore.save(_cast);

    // The old file is gone but Flutter still holds its pixels, so the tile would
    // keep showing the previous face until the screen is rebuilt from scratch.
    imageCache.clear();
    imageCache.clearLiveImages();
    if (mounted) setState(() {});
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what copied'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Prompts'),
        actions: [
          if (_prompts != null)
            IconButton(
              tooltip: 'Copy every image prompt',
              icon: const Icon(Icons.copy_all),
              onPressed: () => _copy(
                _prompts!.scenes
                    .map((s) => buildImagePrompt(s, _cast, withOverlay: _withOverlay))
                    .join('\n\n────────────────\n\n'),
                'All ${_prompts!.scenes.length} image prompts',
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Working out the scenes...', style: TextStyle(fontSize: 13)),
            ]))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildCast(),
                if (_error.isNotEmpty) _buildError(),
                if (_prompts != null) ..._buildPrompts(),
              ],
            ),
    );
  }

  // ── The saved faces ─────────────────────────────────────────────────────────

  Widget _buildCast() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('Your characters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            TextButton.icon(
              onPressed: () => _editCharacter(null),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
            ),
          ]),
          const Text('Saved on this phone and reused in every prompt. Tap a face to '
              'change the picture, tap the name to edit the description.',
            style: TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 10),
          SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cast.length,
              itemBuilder: (ctx, i) {
                final c = _cast[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 84,
                    child: Column(children: [
                      GestureDetector(
                        onTap: () => _pickFace(i),
                        child: Container(
                          height: 92, width: 84,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: c.hasImage ? Colors.teal : Colors.grey.shade700),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: c.hasImage
                              ? Image.file(File(c.imagePath!), fit: BoxFit.cover)
                              : const Center(child: Icon(Icons.add_a_photo,
                                  color: Colors.white38, size: 22)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => _editCharacter(i),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Flexible(child: Text(c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12))),
                          const SizedBox(width: 2),
                          Icon(Icons.edit, size: 11,
                            // Amber when there is no description: that character would
                            // be left out of every prompt, and nothing else would say so.
                            color: c.description.trim().isEmpty
                                ? Colors.amber : Colors.white38),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  /// Add a character, or edit one. Null index means a new one.
  Future<void> _editCharacter(int? index) async {
    final existing = index == null ? null : _cast[index];
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(existing == null ? 'New character' : existing.name),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 6,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'Description',
                helperText: 'Hair, eyes, skin, clothes, build. This exact wording goes '
                    'into every prompt.',
                helperMaxLines: 3,
              ),
            ),
          ]),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (saved == null) return;

    if (saved == false && existing != null) {
      await CharacterStore.removeFace(existing);
      setState(() => _cast.removeAt(index!));
    } else if (saved == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;
      final updated = (existing ?? const CharacterRef(name: ''))
          .copyWith(name: name, description: descCtrl.text.trim());
      setState(() {
        if (index == null) {
          _cast.add(updated);
        } else {
          _cast[index] = updated;
        }
      });
    }

    await CharacterStore.save(_cast);
  }

  Widget _buildError() => Card(
        color: Colors.red.shade900.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(_error, style: const TextStyle(fontSize: 12))),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () => _copy(_error, 'Error'),
            ),
          ]),
        ),
      );

  // ── The prompts ─────────────────────────────────────────────────────────────

  List<Widget> _buildPrompts() {
    final p = _prompts!;
    final video = buildVideoPrompt(p.beats, widget.seconds, _cast);

    return [
      const SizedBox(height: 12),
      _promptCard(
        title: 'Video prompt',
        subtitle: 'One prompt for the whole reel. Paste into a video generator.',
        body: video,
        copyLabel: 'Video prompt',
      ),
      const SizedBox(height: 16),
      Row(children: [
        const Expanded(child: Text('Image prompts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        // Off by default: most generators render text badly, and a misspelt overlay
        // is worse than none. Better to add captions afterwards.
        const Text('Add caption', style: TextStyle(fontSize: 11, color: Colors.white54)),
        Switch(
          value: _withOverlay,
          onChanged: (v) => setState(() => _withOverlay = v),
        ),
      ]),
      const Text('One per line of the script, in order.',
        style: TextStyle(fontSize: 11, color: Colors.white54)),
      const SizedBox(height: 8),
      ...p.scenes.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _promptCard(
              title: 'Picture ${e.key + 1}',
              subtitle: e.value.overlayText,
              body: buildImagePrompt(e.value, _cast, withOverlay: _withOverlay),
              copyLabel: 'Picture ${e.key + 1} prompt',
            ),
          )),
    ];
  }

  Widget _promptCard({
    required String title,
    required String subtitle,
    required String body,
    required String copyLabel,
  }) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copy(body, copyLabel),
            ),
          ]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38, borderRadius: BorderRadius.circular(6)),
            child: SelectableText(body,
              style: const TextStyle(fontSize: 11, height: 1.35, fontFamily: 'monospace')),
          ),
        ]),
      ),
    );
  }
}
