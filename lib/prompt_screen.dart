import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'characters.dart';
import 'prompt_builder.dart';
import 'projects.dart';
import 'prompts.dart';
import 'theme.dart';

// ── Prompts screen ────────────────────────────────────────────────────────────
// Everything here is meant to be copied out and pasted into an image or video
// generator, so every block has its own copy button and nothing needs retyping.

class PromptScreen extends StatefulWidget {
  final String storyDescription;
  final List<String> scriptLines;
  final int seconds;
  /// The saved story these belong to, so the prompts are written down once and read
  /// back on every later visit instead of being bought again. Empty in video mode.
  final String projectId;

  const PromptScreen({
    super.key,
    required this.storyDescription,
    required this.scriptLines,
    required this.seconds,
    this.projectId = '',
  });

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  PromptSet? _prompts;
  List<CharacterRef> _cast = [];
  /// Who is in THIS story. Names, because the list can be reordered or edited.
  Set<String> _inStory = {};
  bool _loading = true;
  bool _withOverlay = false;
  /// On by default, because a chat is what these get pasted into. Off gives the long
  /// self-contained prompt, which is what a generator with a single prompt box needs.
  bool _chatMode = true;
  String _error = '';
  /// Replaces "Working out the scenes..." while a retry is being waited out.
  String _waiting = '';
  /// True when these came off the phone rather than from a fresh request. Worth
  /// saying, so nobody wonders why the wording is identical to yesterday's.
  bool _fromSaved = false;
  /// Your own wording, by field. Read at the top of every card, so what you typed is
  /// what you see and what you copy.
  Map<String, String> _edits = {};

  /// Only the ticked characters go into the prompts. Sending the whole cast every
  /// time describes people who never appear, and generators dutifully draw them.
  List<CharacterRef> get _selectedCast =>
      _cast.where((c) => _inStory.contains(c.name)).toList();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // The cast is on the phone already, so show it while Gemini is still thinking.
    _cast = await CharacterStore.load();
    _inStory = _guessWhoIsInIt();
    if (mounted) setState(() {});

    // Read before asking. This screen used to fire a request every single time it
    // opened, so looking at your own prompts a second time cost the same as making
    // them — which on a free tier is the difference between working and blocked.
    final saved = await _savedPrompts();
    if (saved != null) {
      if (!mounted) return;
      setState(() { _prompts = saved; _loading = false; _fromSaved = true; });
      return;
    }

    await _askGemini();
  }

  /// The prompts written down last time, if they still match this script.
  ///
  /// Null when there are none, when the script has been edited since, or when the
  /// saved text will not parse — all of which mean the same thing to the caller.
  Future<PromptSet?> _savedPrompts() async {
    if (widget.projectId.isEmpty) return null;
    try {
      final all = await ProjectStore.load();
      final matches = all.where((p) => p.id == widget.projectId);
      if (matches.isEmpty) return null;

      final project = matches.first;
      // Loaded whether or not there are prompts: your own wording outlives them.
      _edits = Map.of(project.edits);
      if (project.promptsJson.isEmpty) return null;

      // One picture per line, so a changed script means prompts that describe
      // pictures for words that are no longer there.
      final sameScript = project.promptsScript.length == widget.scriptLines.length &&
          List.generate(widget.scriptLines.length,
              (i) => project.promptsScript[i] == widget.scriptLines[i]).every((m) => m);
      if (!sameScript) return null;

      return promptsFromSaved(project.promptsJson, widget.scriptLines);
    } catch (_) {
      return null;
    }
  }

  Future<void> _askGemini() async {
    setState(() { _loading = true; _error = ''; _waiting = ''; _fromSaved = false; });
    try {
      final prompts = await generatePrompts(
        storyDescription: widget.storyDescription,
        scriptLines: widget.scriptLines,
        seconds: widget.seconds,
        // Shown under the spinner: a silent thirty second wait reads as a hang.
        onWait: (message) { if (mounted) setState(() => _waiting = message); },
      );
      if (!mounted) return;
      setState(() { _prompts = prompts; _loading = false; });
      await _savePrompts(prompts);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _savePrompts(PromptSet prompts) async {
    if (widget.projectId.isEmpty || prompts.rawJson.isEmpty) return;
    final all = await ProjectStore.load();
    final matches = all.where((p) => p.id == widget.projectId);
    if (matches.isEmpty) return;

    await ProjectStore.save(matches.first.copyWith(
      promptsJson: prompts.rawJson,
      promptsScript: List.of(widget.scriptLines),
    ));
  }

  Future<void> _pickFace(int index) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final saved = await CharacterStore.saveFace(_cast[index].name, picked.path);
    setState(() => _cast[index] = _cast[index].copyWith(imagePath: saved));
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
              onPressed: () => _copy(_allImagePrompts(),
                'All ${_prompts!.scenes.length} image prompts'),
            ),
          // Only offered once there is something to replace, and it says plainly that
          // it spends a request — otherwise the cheap path and the expensive one look
          // identical and people tap the expensive one out of habit.
          if (_prompts != null)
            IconButton(
              tooltip: 'Write new prompts (uses a Gemini request)',
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _askGemini,
            ),
        ],
      ),
      body: _loading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(_waiting.isEmpty ? 'Working out the scenes...' : _waiting,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
            ]))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildCast(),
                if (_error.isNotEmpty) _buildError(),
                if (_fromSaved)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AppCard(
                      colour: AppColors.primarySoft,
                      borderColour: AppColors.primary,
                      child: const Row(children: [
                        Icon(Icons.bookmark_outline, size: 17, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                          'Saved from last time — no request used. Tap refresh above '
                          'for different ones.',
                          style: TextStyle(fontSize: 13, color: AppColors.text))),
                      ]),
                    ),
                  ),
                if (_prompts != null) ..._buildPrompts(),
              ],
            ),
    );
  }

  // ── The saved faces ─────────────────────────────────────────────────────────

  Widget _buildCast() {
    return Card(
      color: AppColors.surface,
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
          const Text('Tick who is in this story. Tap a face to change the picture, tap the '
              'name to edit the description. Saved on this phone and reused every time.',
            style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
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
                      Stack(children: [
                        GestureDetector(
                          onTap: () => _pickFace(i),
                          child: Opacity(
                            // Dimmed when not in this story, so the ticked ones read
                            // at a glance without having to check every box.
                            opacity: _inStory.contains(c.name) ? 1 : 0.35,
                            child: Container(
                              height: 92, width: 84,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _inStory.contains(c.name)
                                      ? AppColors.primary : AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              // A picked face wins; otherwise the one shipped with the
                              // app; otherwise the prompt to add one.
                              child: c.hasImage
                                  ? Image.file(File(c.imagePath!), fit: BoxFit.cover)
                                  : c.assetPath != null
                                      ? Image.asset(c.assetPath!, fit: BoxFit.cover)
                                      : const Center(child: Icon(Icons.add_a_photo,
                                          color: AppColors.textFaint, size: 22)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2, left: 2,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              if (!_inStory.remove(c.name)) _inStory.add(c.name);
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _inStory.contains(c.name)
                                    ? AppColors.primary : AppColors.textSoft,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                _inStory.contains(c.name)
                                    ? Icons.check : Icons.circle_outlined,
                                size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ]),
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
                                ? AppColors.warning : AppColors.textFaint),
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

  /// Ticks the characters whose name appears in the story or the script.
  ///
  /// Saves unticking four people on most stories. Falls back to everyone when no name
  /// is mentioned — better to describe one character too many than to send a prompt
  /// with nobody in it.
  Set<String> _guessWhoIsInIt() {
    final haystack =
        '${widget.storyDescription} ${widget.scriptLines.join(' ')}'.toLowerCase();

    final found = _cast
        .where((c) => haystack.contains(c.name.toLowerCase()))
        .map((c) => c.name)
        .toSet();

    return found.isEmpty ? _cast.map((c) => c.name).toSet() : found;
  }

  /// Add a character, or edit one. Null index means a new one.
  Future<void> _editCharacter(int? index) async {
    final existing = index == null ? null : _cast[index];
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
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
              child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
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
        color: AppColors.danger.withOpacity(0.3),
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
    final video = buildVideoPrompt(p.beats, widget.seconds, _selectedCast);

    return [
      const SizedBox(height: 14),
      const Text('Posting it',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 8),
      _promptCard(
        title: '1. Cover hook',
        subtitle: 'Drawn on picture 1 by the app — this is the thumbnail',
        body: _shown('cover_hook', p.post.coverHook.isEmpty ? p.post.coverTitle : p.post.coverHook),
        copyLabel: 'Cover hook',
        editField: 'cover_hook',
      ),
      const SizedBox(height: 10),
      _promptCard(
        title: '2. The lesson',
        subtitle: 'What the reel leaves a parent with',
        body: _shown('moral_line', p.post.moralLine.isEmpty ? p.beats.endingLine : p.post.moralLine),
        copyLabel: 'Lesson',
        editField: 'moral_line',
      ),
      const SizedBox(height: 10),
      _promptCard(
        title: '3. Last screen',
        // Both on one card because they are one screen, and reading them apart is
        // how you end up with a question that does not sit with the line above it.
        subtitle: 'Drawn on the closing card by the app',
        // Question first, then the reason to keep it — the same order it is drawn in,
        // so what you read here is what ends up on the screen.
        body: _shown('last_screen',
            '${p.post.endQuestion.isEmpty ? '' : '${p.post.endQuestion}\n\n'}'
            '${p.post.ctaLine.isEmpty ? kDefaultCtaLine : p.post.ctaLine}'),
        copyLabel: 'Last screen',
        editField: 'last_screen',
      ),
      const SizedBox(height: 10),
      _promptCard(
        title: '4. Caption',
        subtitle: '${p.post.hashtags.length} hashtags included',
        body: _shown('caption', p.post.forInstagram),
        copyLabel: 'Caption',
        editField: 'caption',
      ),
      const SizedBox(height: 10),
      _promptCard(
        title: '5. Pin this comment',
        subtitle: 'Post it yourself, then pin it',
        body: _shown('pin_comment', p.post.pinComment),
        copyLabel: 'Pin comment',
        editField: 'pin_comment',
      ),
      const SizedBox(height: 10),
      _promptCard(
        title: '6. Reply to every comment with this',
        subtitle: 'A question keeps the conversation going; "thank you!" ends it',
        body: _shown('reply_question', p.post.replyQuestion),
        copyLabel: 'Reply question',
        editField: 'reply_question',
      ),
      const SizedBox(height: 10),
      _promptCard(
        title: '7. When to post',
        // The caveat is part of the card, not a footnote, because a time presented as
        // fact would stop anyone checking the real answer in their own Insights.
        subtitle: kBestTimeCaveat,
        body: _shown('best_time', p.post.bestTime),
        copyLabel: 'Posting time',
        editField: 'best_time',
      ),
      const SizedBox(height: 18),
      const Text('The prompts',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 8),
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
        const Text('Add caption', style: TextStyle(fontSize: 11, color: AppColors.textSoft)),
        Switch(
          value: _withOverlay,
          onChanged: (v) => setState(() => _withOverlay = v),
        ),
      ]),
      Row(children: [
        Expanded(
          child: Text(
            _chatMode
                ? 'Short messages for a chat. Send the setup first, then one message '
                  'per picture, in order, in the same chat.'
                : 'Long self-contained prompts. Each one stands alone, for a tool with '
                  'a single prompt box.',
            style: const TextStyle(fontSize: 11, color: AppColors.textSoft)),
        ),
        const SizedBox(width: 8),
        // Named for the shape of the thing, not for WhatsApp: the same messages work
        // in any chat that makes pictures, and naming it after one app would age badly.
        ChoiceChip(
          label: Text(_chatMode ? 'Chat' : 'Full',
            style: const TextStyle(fontSize: 11)),
          selected: _chatMode,
          onSelected: (_) => setState(() => _chatMode = !_chatMode),
        ),
      ]),
      const SizedBox(height: 8),
      // Only in chat mode, and first, because every picture message below depends on
      // it having been sent. Out of order, the pictures come back as strangers.
      if (_chatMode) ...[
        _promptCard(
          title: 'Send this first',
          subtitle: 'Once per story. Wait for it to reply before the pictures.',
          body: buildCastSetupMessage(_selectedCast),
          copyLabel: 'Setup message',
        ),
        const SizedBox(height: 10),
      ],
      ...p.scenes.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _promptCard(
              title: e.value.beat.isEmpty
                  ? 'Picture ${e.key + 1}'
                  : 'Picture ${e.key + 1} · ${e.value.beat}',
              subtitle: e.value.dialogue.isEmpty
                  ? e.value.overlayText
                  : '${e.value.overlayText}   💬 ${e.value.dialogue}',
              body: _sceneBody(e.value, e.key, p.scenes.length),
              copyLabel: 'Picture ${e.key + 1} prompt',
            ),
          )),
    ];
  }

  /// One picture, written for whichever place it is going to be pasted.
  String _sceneBody(ScenePrompt scene, int index, int total) => _chatMode
      ? buildSceneMessage(scene, index + 1, total, withOverlay: _withOverlay)
      : buildImagePrompt(scene, _selectedCast, withOverlay: _withOverlay);

  /// Everything in one go. In chat mode the setup comes first, since without it the
  /// picture messages refer to characters that were never described.
  String _allImagePrompts() {
    final scenes = _prompts!.scenes
        .asMap()
        .entries
        .map((e) => _sceneBody(e.value, e.key, _prompts!.scenes.length));

    final blocks = _chatMode
        ? [buildCastSetupMessage(_selectedCast), ...scenes]
        : scenes.toList();

    return blocks.join('\n\n────────────────\n\n');
  }

  /// Whatever you rewrote for [field], or what was generated.
  String _shown(String field, String generated) =>
      (_edits[field]?.trim().isNotEmpty == true) ? _edits[field]! : generated;

  /// Rewrite one of these in your own words.
  ///
  /// Saved beside the reply rather than over it, so the edit survives asking for new
  /// prompts and the original is still there if the rewrite turns out worse. Reset
  /// puts the generated one back.
  Future<void> _editField(String field, String title, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title', style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          minLines: 2,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          if (_edits.containsKey(field))
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Reset')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save')),
        ],
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (result.trim().isEmpty) {
        _edits.remove(field);
      } else {
        _edits[field] = result.trim();
      }
    });
    await _saveEdits();
  }

  Future<void> _saveEdits() async {
    if (widget.projectId.isEmpty) return;
    final all = await ProjectStore.load();
    final matches = all.where((p) => p.id == widget.projectId);
    if (matches.isEmpty) return;
    await ProjectStore.save(matches.first.copyWith(edits: Map.of(_edits)));
  }

  Widget _promptCard({
    required String title,
    required String subtitle,
    required String body,
    required String copyLabel,
    /// Set on anything you might want to word differently yourself. Null on the
    /// picture prompts — those are instructions to a generator, not your writing.
    String? editField,
  }) {
    final edited = editField != null && _edits.containsKey(editField);
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  if (edited) ...[
                    const SizedBox(width: 6),
                    const Text('edited',
                      style: TextStyle(fontSize: 10, color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                  ],
                ]),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSoft)),
              ]),
            ),
            if (editField != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _editField(editField, title, body),
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
              color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
            child: SelectableText(body,
              style: const TextStyle(fontSize: 11, height: 1.35, fontFamily: 'monospace')),
          ),
        ]),
      ),
    );
  }
}
