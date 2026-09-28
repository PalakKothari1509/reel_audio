import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'brand_system.dart';
import 'content_generator.dart';
import 'format_adapter.dart';
import 'theme.dart';

class PostingPackScreen extends StatefulWidget {
  final Map<ContentFormat, FormatOutput> formats;
  final ContentPackage originalPackage;

  const PostingPackScreen({
    super.key,
    required this.formats,
    required this.originalPackage,
  });

  @override
  State<PostingPackScreen> createState() => _PostingPackScreenState();
}

class _PostingPackScreenState extends State<PostingPackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ContentFormat> _tabFormats = [
    ContentFormat.carousel,
    ContentFormat.reel,
    ContentFormat.trialReel,
    ContentFormat.singleImage,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabFormats.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _formatIcon(ContentFormat format) {
    switch (format) {
      case ContentFormat.carousel:
        return Icons.view_carousel_outlined;
      case ContentFormat.reel:
        return Icons.movie_outlined;
      case ContentFormat.trialReel:
        return Icons.science_outlined;
      case ContentFormat.singleImage:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posting Pack: ${widget.originalPackage.idea}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabFormats.map((f) => Tab(
            icon: Icon(_formatIcon(f)),
            text: f.label,
          )).toList(),
        ),
        actions: [
          IconButton(
            tooltip: 'Export all as JSON',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportAllJson,
          ),
          IconButton(
            tooltip: 'Share all',
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareAll,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabFormats.map((format) {
          final output = widget.formats[format]!;
          return _FormatTabView(format: format, output: output, originalPackage: widget.originalPackage);
        }).toList(),
      ),
    );
  }

  Future<void> _exportAllJson() async {
    final map = <String, dynamic>{
      'originalPackage': widget.originalPackage.toJson(),
      'formats': widget.formats.map((k, v) => MapEntry(k.name, v.toJson())),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    
    await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(map)));
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All formats exported as JSON to clipboard')),
    );
  }

  Future<void> _shareAll() async {
    final buffer = StringBuffer();
    buffer.writeln('POSTING PACK: ${widget.originalPackage.idea}');
    buffer.writeln('Bucket: ${widget.originalPackage.bucket.name} ${widget.originalPackage.bucket.emoji}');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('');
    
    for (final format in _tabFormats) {
      final output = widget.formats[format]!;
      buffer.writeln('${format.emoji} ${format.label.toUpperCase()}');
      buffer.writeln('────────────────────');
      buffer.writeln('HOOK: ${output.copyMap['hook']}');
      buffer.writeln('');
      buffer.writeln('CAPTION: ${output.copyMap['caption']}');
      buffer.writeln('');
      buffer.writeln('HASHTAGS: ${output.copyMap['hashtags']}');
      buffer.writeln('');
      buffer.writeln('PINNED: ${output.copyMap['pinnedComment']}');
      buffer.writeln('');
      buffer.writeln('REPLIES: ${output.copyMap['replyComments']}');
      buffer.writeln('');
      if (output.script.isNotEmpty) {
        buffer.writeln('SCRIPT: ${output.script}');
        buffer.writeln('');
      }
      buffer.writeln('IMAGE PROMPTS (${output.imagePrompts.length}):');
      for (int i = 0; i < output.imagePrompts.length; i++) {
        buffer.writeln('  ${i + 1}. ${output.imagePrompts[i]}');
      }
      buffer.writeln('');
      buffer.writeln('═══════════════════════════════════');
      buffer.writeln('');
    }
    
    await Share.share(buffer.toString(), subject: 'Posting Pack: ${widget.originalPackage.idea}');
  }
}

class _FormatTabView extends StatelessWidget {
  final ContentFormat format;
  final FormatOutput output;
  final ContentPackage originalPackage;

  const _FormatTabView({
    required this.format,
    required this.output,
    required this.originalPackage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormatHeader(format: format, output: output),
          Gap.l,
          _CopySection(
            title: '📋 Copy Blocks',
            children: _buildCopyBlocks(),
          ),
          Gap.l,
          if (output.script.isNotEmpty) ...[
            _CopySection(
              title: '🎬 Script / Voiceover',
              children: [_CopyBlock(label: 'Full Script', content: output.script, isMultiLine: true)],
            ),
            Gap.l,
          ],
          _CopySection(
            title: '🎨 Image/Video Prompts (${output.imagePrompts.length})',
            children: output.imagePrompts.asMap().entries.map((entry) {
              final i = entry.key;
              final prompt = entry.value;
              return _CopyBlock(
                label: format == ContentFormat.trialReel ? 'Shot ${i + 1}' : 'Slide ${i + 1}',
                content: prompt,
                isMultiLine: true,
                showIndex: true,
                index: i + 1,
                total: output.imagePrompts.length,
              );
            }).toList(),
          ),
          Gap.l,
          _CopySection(
            title: '📦 Slides/Shots Detail',
            children: output.slides.asMap().entries.map((entry) {
              final i = entry.key;
              final slide = entry.value;
              return _SlideDetailCard(slide: slide, index: i, format: format);
            }).toList(),
          ),
          Gap.l,
          _ActionButtons(format: format, output: output, originalPackage: originalPackage),
        ],
      ),
    );
  }

  List<Widget> _buildCopyBlocks() {
    final blocks = <Widget>[];
    final copyMap = output.copyMap;
    
    final orderedKeys = ['hook', 'caption', 'hashtags', 'pinnedComment', 'replyComments'];
    
    for (final key in orderedKeys) {
      final content = copyMap[key];
      if (content != null && content.isNotEmpty) {
        blocks.add(_CopyBlock(
          label: _formatLabel(key),
          content: content,
          isMultiLine: key != 'hashtags' && key != 'hook',
        ));
      }
    }
    
    return blocks;
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'hook': return '🎯 Hook';
      case 'caption': return '📝 Caption';
      case 'hashtags': return '🏷️ Hashtags';
      case 'pinnedComment': return '📌 Pinned Comment';
      case 'replyComments': return '💬 Reply Comments (5)';
      default: return key;
    }
  }
}

class _FormatHeader extends StatelessWidget {
  final ContentFormat format;
  final FormatOutput output;

  const _FormatHeader({required this.format, required this.output});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: format == ContentFormat.carousel ? Colors.blue.shade50 :
               format == ContentFormat.reel ? Colors.red.shade50 :
               format == ContentFormat.trialReel ? Colors.purple.shade50 :
               Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: format == ContentFormat.carousel ? Colors.blue :
                 format == ContentFormat.reel ? Colors.red :
                 format == ContentFormat.trialReel ? Colors.purple :
                 Colors.green,
        ),
      ),
      child: Row(
        children: [
          Icon(format.emoji == '📚' ? Icons.menu_book :
               format.emoji == '🎬' ? Icons.videocam :
               format.emoji == '🧪' ? Icons.science :
               Icons.image,
            size: 32,
            color: format == ContentFormat.carousel ? Colors.blue :
                   format == ContentFormat.reel ? Colors.red :
                   format == ContentFormat.trialReel ? Colors.purple :
                   Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${format.emoji} ${format.label}', style: AppText.screenTitle.copyWith(
                  color: format == ContentFormat.carousel ? Colors.blue :
                         format == ContentFormat.reel ? Colors.red :
                         format == ContentFormat.trialReel ? Colors.purple :
                         Colors.green,
                )),
                Text('${output.slides.length} ${format == ContentFormat.singleImage ? 'image' : format == ContentFormat.carousel ? 'slides' : 'shots'} • ${output.imagePrompts.length} prompts', style: AppText.hint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CopySection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.section),
        Gap.s,
        ...children,
      ],
    );
  }
}

class _CopyBlock extends StatelessWidget {
  final String label;
  final String content;
  final bool isMultiLine;
  final bool showIndex;
  final int? index;
  final int? total;

  const _CopyBlock({
    required this.label,
    required this.content,
    this.isMultiLine = false,
    this.showIndex = false,
    this.index,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                if (showIndex && index != null && total != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$index/$total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                if (showIndex && index != null && total != null) const SizedBox(width: 8),
                Expanded(child: Text(label, style: AppText.section.copyWith(color: AppColors.primary))),
                IconButton(
                  tooltip: 'Copy $label',
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  onPressed: () => _copy(context),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              content,
              style: AppText.body.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 1)),
    );
  }
}

class _SlideDetailCard extends StatelessWidget {
  final SlideContent slide;
  final int index;
  final ContentFormat format;

  const _SlideDetailCard({required this.slide, required this.index, required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  format == ContentFormat.trialReel ? 'Shot ${index + 1}' : 
                  format == ContentFormat.carousel ? 'Slide ${index + 1}' : 'Shot ${index + 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(slide.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              IconButton(
                tooltip: 'Copy slide detail',
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                onPressed: () => _copySlideDetail(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (slide.body.isNotEmpty) Text('Body: ${slide.body}', style: AppText.body),
          if (slide.overlayText != null && slide.overlayText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Overlay: ${slide.overlayText}', style: AppText.hint.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (slide.visualPrompt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Visual Prompt:', style: AppText.hint.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(slide.visualPrompt, style: AppText.body.copyWith(fontSize: 11, color: AppColors.textSoft)),
          ],
        ],
      ),
    );
  }

  void _copySlideDetail(BuildContext context) {
    final text = '${slide.title}\n\n${slide.body}\n\n${slide.overlayText != null ? 'Overlay: ${slide.overlayText}\n\n' : ''}Visual Prompt:\n${slide.visualPrompt}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${format.label} ${index + 1} copied'), duration: const Duration(seconds: 1)),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ContentFormat format;
  final FormatOutput output;
  final ContentPackage originalPackage;

  const _ActionButtons({required this.format, required this.output, required this.originalPackage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _copyAll(context),
            icon: const Icon(Icons.copy_all),
            label: Text('Copy Everything (${format.label})'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        Gap.s,
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _shareFormat(context),
            icon: const Icon(Icons.share_outlined),
            label: Text('Share ${format.label} Pack'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        Gap.s,
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _saveToLibrary(context),
            icon: const Icon(Icons.save_outlined),
            label: Text('Save to Content Library'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ],
    );
  }

  void _copyAll(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('${format.emoji} ${format.label.toUpperCase()} - COPY ALL');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('');
    
    final copyMap = output.copyMap;
    final orderedKeys = ['hook', 'caption', 'hashtags', 'pinnedComment', 'replyComments'];
    
    for (final key in orderedKeys) {
      final content = copyMap[key];
      if (content != null && content.isNotEmpty) {
        buffer.writeln(_formatLabel(key).toUpperCase());
        buffer.writeln(content);
        buffer.writeln('');
      }
    }
    
    if (output.script.isNotEmpty) {
      buffer.writeln('SCRIPT / VOICEOVER');
      buffer.writeln(output.script);
      buffer.writeln('');
    }
    
    buffer.writeln('IMAGE/VIDEO PROMPTS (${output.imagePrompts.length})');
    for (int i = 0; i < output.imagePrompts.length; i++) {
      buffer.writeln('${i + 1}. ${output.imagePrompts[i]}');
      buffer.writeln('');
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${format.label} pack copied entirely'), duration: const Duration(seconds: 2)),
    );
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'hook': return 'Hook';
      case 'caption': return 'Caption';
      case 'hashtags': return 'Hashtags';
      case 'pinnedComment': return 'Pinned Comment';
      case 'replyComments': return 'Reply Comments';
      default: return key;
    }
  }

  Future<void> _shareFormat(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('${format.emoji} ${format.label}: ${originalPackage.idea}');
    buffer.writeln('Bucket: ${originalPackage.bucket.name} ${originalPackage.bucket.emoji}');
    buffer.writeln('');
    
    final copyMap = output.copyMap;
    for (final key in ['hook', 'caption', 'hashtags', 'pinnedComment', 'replyComments']) {
      final content = copyMap[key];
      if (content != null && content.isNotEmpty) {
        buffer.writeln(_formatLabel(key).toUpperCase());
        buffer.writeln(content);
        buffer.writeln('');
      }
    }
    
    if (output.script.isNotEmpty) {
      buffer.writeln('SCRIPT:');
      buffer.writeln(output.script);
      buffer.writeln('');
    }
    
    await Share.share(buffer.toString(), subject: '${format.label}: ${originalPackage.idea}');
  }

  void _saveToLibrary(BuildContext context) {
    // Navigate to content library with pre-filled data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content Library integration coming soon!'), duration: Duration(seconds: 2)),
    );
  }
}