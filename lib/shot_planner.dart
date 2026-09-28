import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_provider.dart';
import 'brand_system.dart';
import 'content_generator.dart';
import 'format_adapter.dart';
import 'theme.dart';

class ShotPlannerScreen extends StatefulWidget {
  final ContentPackage package;
  final Map<ContentFormat, FormatOutput> formats;

  const ShotPlannerScreen({
    super.key,
    required this.package,
    required this.formats,
  });

  @override
  State<ShotPlannerScreen> createState() => _ShotPlannerScreenState();
}

class _ShotPlannerScreenState extends State<ShotPlannerScreen> {
  late List<ShotPlanItem> _shots;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeShots();
  }

  void _initializeShots() {
    final trialOutput = widget.formats[ContentFormat.trialReel];
    if (trialOutput != null) {
      _shots = trialOutput.slides.asMap().entries.map((entry) {
        final i = entry.key;
        final slide = entry.value;
        return ShotPlanItem(
          index: i,
          title: slide.title,
          description: slide.body,
          visualPrompt: slide.visualPrompt,
          veoPrompt: trialOutput.imagePrompts[i],
          durationSeconds: _estimateDuration(slide.body),
          cameraMove: FormatAdapter.cameraMoves[i % FormatAdapter.cameraMoves.length],
          lighting: FormatAdapter.lightingOptions[i % FormatAdapter.lightingOptions.length],
          audioCue: FormatAdapter.audioCues[i % FormatAdapter.audioCues.length],
          transition: i < 7 ? FormatAdapter.transitions[i % FormatAdapter.transitions.length] : 'fade to logo',
        );
      }).toList();
    } else {
      // Fallback: create from package slides
      _shots = widget.package.slides.asMap().entries.map((entry) {
        final i = entry.key;
        final slide = entry.value;
        return ShotPlanItem(
          index: i,
          title: slide.title,
          description: slide.body,
          visualPrompt: slide.visualPrompt,
          veoPrompt: FormatAdapter.veoPrompt(slide, i, widget.package.bucket),
          durationSeconds: _estimateDuration(slide.body),
          cameraMove: FormatAdapter.cameraMoves[i % FormatAdapter.cameraMoves.length],
          lighting: FormatAdapter.lightingOptions[i % FormatAdapter.lightingOptions.length],
          audioCue: FormatAdapter.audioCues[i % FormatAdapter.audioCues.length],
          transition: i < 7 ? FormatAdapter.transitions[i % FormatAdapter.transitions.length] : 'fade to logo',
        );
      }).toList();
    }
    
    // Ensure exactly 8 shots
    while (_shots.length < 8) {
      final lastIdx = _shots.length - 1;
      final last = _shots[lastIdx];
      _shots.add(ShotPlanItem(
        index: _shots.length,
        title: 'Shot ${_shots.length + 1}',
        description: 'Continuation of ${last.title.toLowerCase()}',
        visualPrompt: last.visualPrompt,
        veoPrompt: last.veoPrompt,
        durationSeconds: 3,
        cameraMove: FormatAdapter.cameraMoves[_shots.length % FormatAdapter.cameraMoves.length],
        lighting: FormatAdapter.lightingOptions[_shots.length % FormatAdapter.lightingOptions.length],
        audioCue: FormatAdapter.audioCues[_shots.length % FormatAdapter.audioCues.length],
        transition: _shots.length < 7 ? 'smooth cut' : 'fade to logo',
      ));
    }
    
    if (_shots.length > 8) {
      _shots = _shots.take(8).toList();
    }
  }

  int _estimateDuration(String text) {
    final words = text.split(' ').length;
    return (words / 3).clamp(2, 5).round(); // ~3 words per second
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = _shots.fold(0, (sum, s) => sum + s.durationSeconds);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Shot Planner: ${widget.package.idea}'),
        actions: [
          IconButton(
            tooltip: 'Export Shot Plan',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportShotPlan,
          ),
          IconButton(
            tooltip: 'Copy All Veo Prompts',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyAllVeoPrompts,
          ),
          IconButton(
            tooltip: 'Regenerate with AI',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: _regenerateWithAI,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(totalDuration),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _shots.length,
              itemBuilder: (context, index) => _ShotCard(
                shot: _shots[index],
                onChanged: (updated) => setState(() => _shots[index] = updated),
                onDuplicate: () => _duplicateShot(index),
                onDelete: _shots.length > 8 ? () => _deleteShot(index) : null,
              ),
            ),
          ),
          _buildBottomBar(totalDuration),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalDuration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        border: Border(bottom: BorderSide(color: Colors.purple.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.purple.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trial Reel Shot Planner', style: AppText.screenTitle.copyWith(color: Colors.purple.shade700)),
                    Text('8 shots • ${totalDuration}s estimated • Veo-ready prompts', style: AppText.hint),
                  ],
                ),
              ),
            ],
          ),
          Gap.m,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Bucket', value: '${widget.package.bucket.emoji} ${widget.package.bucket.name}', color: widget.package.bucket.color),
              _InfoChip(label: 'Format', value: 'Trial Reel (60s fast-cut)', color: Colors.purple),
              _InfoChip(label: 'Aspect', value: '9:16 vertical', color: Colors.blue),
              _InfoChip(label: 'Quality', value: '4K 30fps', color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int totalDuration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Duration', style: AppText.hint),
                Text('${totalDuration}s', style: AppText.screenTitle.copyWith(fontSize: 24)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _copyAllVeoPrompts,
              icon: const Icon(Icons.copy_all),
              label: const Text('Copy All Veo Prompts'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportShotPlan,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Export Plan'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _exportShotPlan() {
    final buffer = StringBuffer();
    buffer.writeln('TRIAL REEL SHOT PLAN');
    buffer.writeln('═══════════════════════');
    buffer.writeln('');
    buffer.writeln('Topic: ${widget.package.idea}');
    buffer.writeln('Bucket: ${widget.package.bucket.name} ${widget.package.bucket.emoji}');
    buffer.writeln('Total Shots: ${_shots.length}');
    buffer.writeln('Estimated Duration: ${_shots.fold(0, (sum, s) => sum + s.durationSeconds)}s');
    buffer.writeln('');
    buffer.writeln('BRAND CONTEXT:');
    buffer.writeln(BrandContext.defaultContext().toPromptString());
    buffer.writeln('');
    buffer.writeln('SHOTS:');
    buffer.writeln('═══════════════════════');
    
    for (final shot in _shots) {
      buffer.writeln('');
      buffer.writeln('SHOT ${shot.index + 1}/8: ${shot.title}');
      buffer.writeln('────────────────────────────────────────');
      buffer.writeln('Description: ${shot.description}');
      buffer.writeln('Duration: ${shot.durationSeconds}s');
      buffer.writeln('Camera: ${shot.cameraMove}');
      buffer.writeln('Lighting: ${shot.lighting}');
      buffer.writeln('Audio Cue: ${shot.audioCue}');
      buffer.writeln('Transition: ${shot.transition}');
      buffer.writeln('');
      buffer.writeln('VEO PROMPT:');
      buffer.writeln(shot.veoPrompt);
      buffer.writeln('');
      buffer.writeln('VISUAL PROMPT (backup):');
      buffer.writeln(shot.visualPrompt);
      buffer.writeln('');
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complete shot plan copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  void _copyAllVeoPrompts() {
    final prompts = _shots.map((s) => 'SHOT ${s.index + 1}:\n${s.veoPrompt}').join('\n\n══════════════════════\n\n');
    Clipboard.setData(ClipboardData(text: prompts));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All 8 Veo prompts copied'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _regenerateWithAI() async {
    // Would call AI provider to regenerate shot plan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI regeneration coming soon!')),
    );
  }

  void _duplicateShot(int index) {
    if (_shots.length >= 10) return;
    setState(() {
      final original = _shots[index];
      _shots.insert(index + 1, original.copyWith(index: index + 1));
      _renumberShots();
    });
  }

  void _deleteShot(int index) {
    if (_shots.length <= 8) return;
    setState(() {
      _shots.removeAt(index);
      _renumberShots();
    });
  }

  void _renumberShots() {
    for (int i = 0; i < _shots.length; i++) {
      _shots[i] = _shots[i].copyWith(index: i);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ShotPlanItem {
  final int index;
  final String title;
  final String description;
  final String visualPrompt;
  final String veoPrompt;
  final int durationSeconds;
  final String cameraMove;
  final String lighting;
  final String audioCue;
  final String transition;

  ShotPlanItem({
    required this.index,
    required this.title,
    required this.description,
    required this.visualPrompt,
    required this.veoPrompt,
    required this.durationSeconds,
    required this.cameraMove,
    required this.lighting,
    required this.audioCue,
    required this.transition,
  });

  ShotPlanItem copyWith({
    int? index,
    String? title,
    String? description,
    String? visualPrompt,
    String? veoPrompt,
    int? durationSeconds,
    String? cameraMove,
    String? lighting,
    String? audioCue,
    String? transition,
  }) {
    return ShotPlanItem(
      index: index ?? this.index,
      title: title ?? this.title,
      description: description ?? this.description,
      visualPrompt: visualPrompt ?? this.visualPrompt,
      veoPrompt: veoPrompt ?? this.veoPrompt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      cameraMove: cameraMove ?? this.cameraMove,
      lighting: lighting ?? this.lighting,
      audioCue: audioCue ?? this.audioCue,
      transition: transition ?? this.transition,
    );
  }
}

class _ShotCard extends StatefulWidget {
  final ShotPlanItem shot;
  final ValueChanged<ShotPlanItem> onChanged;
  final VoidCallback onDuplicate;
  final VoidCallback? onDelete;

  const _ShotCard({
    required this.shot,
    required this.onChanged,
    required this.onDuplicate,
    this.onDelete,
  });

  @override
  State<_ShotCard> createState() => _ShotCardState();
}

class _ShotCardState extends State<_ShotCard> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _cameraCtrl;
  late TextEditingController _lightingCtrl;
  late TextEditingController _audioCtrl;
  late TextEditingController _transitionCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.shot.title);
    _descCtrl = TextEditingController(text: widget.shot.description);
    _durationCtrl = TextEditingController(text: widget.shot.durationSeconds.toString());
    _cameraCtrl = TextEditingController(text: widget.shot.cameraMove);
    _lightingCtrl = TextEditingController(text: widget.shot.lighting);
    _audioCtrl = TextEditingController(text: widget.shot.audioCue);
    _transitionCtrl = TextEditingController(text: widget.shot.transition);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _cameraCtrl.dispose();
    _lightingCtrl.dispose();
    _audioCtrl.dispose();
    _transitionCtrl.dispose();
    super.dispose();
  }

  void _updateShot([String? _]) {
    widget.onChanged(widget.shot.copyWith(
      title: _titleCtrl.text,
      description: _descCtrl.text,
      durationSeconds: int.tryParse(_durationCtrl.text) ?? widget.shot.durationSeconds,
      cameraMove: _cameraCtrl.text,
      lighting: _lightingCtrl.text,
      audioCue: _audioCtrl.text,
      transition: _transitionCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Shot header - always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.shot.index + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.shot.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Text(
                          '${widget.shot.durationSeconds}s • ${widget.shot.cameraMove} • ${widget.shot.transition}',
                          style: AppText.hint.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSoft),
                  if (widget.onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.copy_outlined, size: 20, color: AppColors.primary),
                      onPressed: widget.onDuplicate,
                      tooltip: 'Duplicate shot',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete shot',
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Expanded details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Gap.s,
          
          // Title & Description
          _EditableField(
            label: 'Shot Title',
            controller: _titleCtrl,
            onChanged: _updateShot,
          ),
          Gap.s,
          _EditableField(
            label: 'Description / Action',
            controller: _descCtrl,
            maxLines: 2,
            onChanged: _updateShot,
          ),
          Gap.m,
          
          // Technical specs row
          Row(
            children: [
              Expanded(
                child: _EditableField(
                  label: 'Duration (seconds)',
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: _updateShot,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EditableField(
                  label: 'Transition',
                  controller: _transitionCtrl,
                  onChanged: _updateShot,
                ),
              ),
            ],
          ),
          Gap.m,
          
          // Camera & Lighting
          Row(
            children: [
              Expanded(
                child: _EditableField(
                  label: 'Camera Movement',
                  controller: _cameraCtrl,
                  onChanged: _updateShot,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EditableField(
                  label: 'Lighting',
                  controller: _lightingCtrl,
                  onChanged: _updateShot,
                ),
              ),
            ],
          ),
          Gap.s,
          _EditableField(
            label: 'Audio Cue',
            controller: _audioCtrl,
            onChanged: _updateShot,
          ),
          Gap.m,
          
          // Veo Prompt (read-only, copyable)
          _VeoPromptSection(shot: widget.shot),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _EditableField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.section.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _VeoPromptSection extends StatelessWidget {
  final ShotPlanItem shot;

  const _VeoPromptSection({required this.shot});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Veo Prompt (copy for video generation)', style: AppText.section.copyWith(fontSize: 12)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shot.veoPrompt));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veo prompt copied'), duration: Duration(seconds: 1)),
                );
              },
              tooltip: 'Copy Veo prompt',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: SelectableText(
            shot.veoPrompt,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.4),
          ),
        ),
        Gap.s,
        Text('Visual Prompt (backup for image gen)', style: AppText.hint.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            shot.visualPrompt,
            style: TextStyle(fontSize: 11, color: AppColors.textSoft, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          Text(value, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}