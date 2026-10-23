import 'package:flutter/material.dart';

import 'brand_system.dart';
import 'characters.dart';
import 'content_axes.dart';
import 'content_library_service.dart';
import 'theme.dart';

/// A simple form screen for adding a new idea directly to the Content Library.
///
/// Accessed from the Home screen's "Add New Idea" button (when wired from
/// main.dart). The idea is saved as a custom [ContentIdea] via
/// [ContentLibraryService.addIdea].
class AddIdeaScreen extends StatefulWidget {
  final VoidCallback? onIdeaAdded;

  const AddIdeaScreen({super.key, this.onIdeaAdded});

  @override
  State<AddIdeaScreen> createState() => _AddIdeaScreenState();
}

class _AddIdeaScreenState extends State<AddIdeaScreen> {
  final _titleCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _lessonCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  final _storyDetailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ContentBucket _selectedBucket = BucketLibrary.challenge;
  String _selectedFormat = 'Reel';
  List<String> _selectedChars = ['ria', 'rio', 'cuty'];

  bool _isSaving = false;

  static const _formats = ['Reel', 'Carousel', 'Static Image', 'Trial Reel'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _problemCtrl.dispose();
    _lessonCtrl.dispose();
    _openingCtrl.dispose();
    _storyDetailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final idea = ContentIdea(
        id: '',
        title: _titleCtrl.text.trim(),
        category: _selectedBucket.name,
        collectionId: _selectedBucket.id,
        format: _selectedFormat,
        problem: _problemCtrl.text.trim(),
        lesson: _lessonCtrl.text.trim(),
        opening: _openingCtrl.text.trim(),
        storyDetail: _storyDetailCtrl.text.trim(),
        characterIds: List<String>.from(_selectedChars),
        caption: '',
        isCustom: true,
        status: IdeaStatus.idea,
        notes: _notesCtrl.text.trim(),
        sourceType: 'ContentIdea',
      );
      await ContentLibraryService.instance.addIdea(idea);
      if (!mounted) return;
      widget.onIdeaAdded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idea added to library')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to add idea: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Idea'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: AppText.hint),
            const SizedBox(height: 4),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Rio Copies Everything',
                isDense: true,
              ),
            ),
            Gap.m,
            Text('Bucket', style: AppText.hint),
            const SizedBox(height: 4),
            DropdownButtonFormField<ContentBucket>(
              value: _selectedBucket,
              items: BucketLibrary.all
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: b.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${b.emoji} ${b.name}'),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBucket = v!),
              decoration: const InputDecoration(isDense: true),
            ),
            Gap.m,
            Text('Format', style: AppText.hint),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              items: _formats
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFormat = v!),
              decoration: const InputDecoration(isDense: true),
            ),
            Gap.m,
            Text('Characters', style: AppText.hint),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: kCharacterOptions.map((c) {
                final selected = _selectedChars.contains(c.id);
                return FilterChip(
                  label: Text(c.name),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _selectedChars.remove(c.id);
                    } else {
                      _selectedChars.add(c.id);
                    }
                  }),
                );
              }).toList(),
            ),
            Gap.m,
            Text('Opening Hook', style: AppText.hint),
            const SizedBox(height: 4),
            TextField(
              controller: _openingCtrl,
              decoration: const InputDecoration(
                hintText: 'The first line / hook...',
                isDense: true,
              ),
              maxLines: 2,
            ),
            Gap.m,
            Text('Problem', style: AppText.hint),
            const SizedBox(height: 4),
            TextField(
              controller: _problemCtrl,
              decoration: const InputDecoration(
                hintText: 'The real-life problem this story is built on...',
                isDense: true,
              ),
              maxLines: 3,
            ),
            Gap.m,
            Text('Lesson', style: AppText.hint),
            const SizedBox(height: 4),
            TextField(
              controller: _lessonCtrl,
              decoration: const InputDecoration(
                hintText: 'What is the learning outcome?',
                isDense: true,
              ),
              maxLines: 2,
            ),
            Gap.m,
            Text('Story Details', style: AppText.hint),
            const SizedBox(height: 4),
            TextField(
              controller: _storyDetailCtrl,
              decoration: const InputDecoration(
                hintText: 'Story: ...\nTwist: ...\nResolution: ...\nMoral: ...',
                isDense: true,
              ),
              maxLines: 6,
            ),
            Gap.m,
            Text('Notes (optional)', style: AppText.hint),
            const SizedBox(height: 4),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                hintText: 'Any additional notes...',
                isDense: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
