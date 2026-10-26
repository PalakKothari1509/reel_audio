// ── Prompt Preview Dialog ──────────────────────────────────────────────────────
//
// Shows the exact prompt that will be sent to Gemini before sending.
// Allows user to copy, review, and confirm before making the API call.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'theme.dart';

/// Configuration for a prompt preview dialog
class PromptPreviewConfig {
  final String title;
  final String prompt;
  final String modelName;
  final Map<String, dynamic> generationConfig;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const PromptPreviewConfig({
    required this.title,
    required this.prompt,
    required this.modelName,
    required this.generationConfig,
    required this.onConfirm,
    this.onCancel,
  });
}

/// Shows a dialog with the full prompt before sending to Gemini
Future<void> showPromptPreview(BuildContext context, PromptPreviewConfig config) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PromptPreviewDialog(config: config),
  );
}

/// Also available as a bottom sheet for larger prompts
Future<void> showPromptPreviewSheet(BuildContext context, PromptPreviewConfig config) async {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PromptPreviewSheet(config: config),
  );
}

class _PromptPreviewDialog extends StatelessWidget {
  final PromptPreviewConfig config;

  const _PromptPreviewDialog({required this.config});

  @override
  Widget build(BuildContext context) {
    final promptLines = config.prompt.trim().split('\n').length;
    final charCount = config.prompt.length;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.preview, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(config.title, style: AppText.section)),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model & config info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model: ${config.modelName}', style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Lines: $promptLines  •  Characters: $charCount', style: AppText.hint),
                  const SizedBox(height: 4),
                  Text('Config: ${_formatConfig(config.generationConfig)}', style: AppText.hint),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Prompt content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    config.prompt,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: AppColors.text),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    config.onCancel?.call();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    config.onConfirm();
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send to Gemini'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatConfig(Map<String, dynamic> config) {
    final parts = <String>[];
    if (config['temperature'] != null) parts.add('temp: ${config['temperature']}');
    if (config['maxOutputTokens'] != null) parts.add('maxTokens: ${config['maxOutputTokens']}');
    if (config['thinkingConfig'] != null) parts.add('thinking: ${config['thinkingConfig']}');
    if (config['responseMimeType'] != null) parts.add('mime: ${config['responseMimeType']}');
    return parts.join('  •  ');
  }
}

class _PromptPreviewSheet extends StatelessWidget {
  final PromptPreviewConfig config;

  const _PromptPreviewSheet({required this.config});

  @override
  Widget build(BuildContext context) {
    final promptLines = config.prompt.trim().split('\n').length;
    final charCount = config.prompt.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.preview, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(config.title, style: AppText.section)),
                  IconButton(
                    icon: const Icon(Icons.copy_all),
                    tooltip: 'Copy full prompt',
                    onPressed: () => _copyPrompt(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                      config.onCancel?.call();
                    },
                  ),
                ],
              ),
            ),
            // Model info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      Text('Model: ', style: AppText.small),
                      Text(config.modelName, style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      Text('$promptLines lines  •  $charCount chars', style: AppText.hint),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Config: ${_formatConfig(config.generationConfig)}', style: AppText.hint),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Prompt content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(
                      config.prompt,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: AppColors.text),
                    ),
                  ),
                ),
              ),
            ),
            // Send button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    config.onConfirm();
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send to Gemini'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyPrompt(BuildContext context) {
    Clipboard.setData(ClipboardData(text: config.prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt copied to clipboard')),
    );
  }

  String _formatConfig(Map<String, dynamic> config) {
    final parts = <String>[];
    if (config['temperature'] != null) parts.add('temp: ${config['temperature']}');
    if (config['maxOutputTokens'] != null) parts.add('maxTokens: ${config['maxOutputTokens']}');
    if (config['thinkingConfig'] != null) parts.add('thinking: ${config['thinkingConfig']}');
    if (config['responseMimeType'] != null) parts.add('mime: ${config['responseMimeType']}');
    return parts.join('  •  ');
  }
}

/// Extension to easily add preview to any async function
extension PromptPreviewExtension on String {
  /// Shows preview dialog then executes [onSend] if confirmed
  Future<T> withPromptPreview<T>({
    required BuildContext context,
    required String title,
    required String modelName,
    required Map<String, dynamic> generationConfig,
    required Future<T> Function() onSend,
    bool useSheet = false,
  }) async {
    final completer = Completer<T>();

    final config = PromptPreviewConfig(
      title: title,
      prompt: this,
      modelName: modelName,
      generationConfig: generationConfig,
      onConfirm: () async {
        try {
          final result = await onSend();
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      },
      onCancel: () => completer.completeError(Exception('User cancelled')),
    );

    if (useSheet) {
      await showPromptPreviewSheet(context, config);
    } else {
      await showPromptPreview(context, config);
    }

    return completer.future;
  }

  /// Shows prompt in a copyable dialog WITHOUT sending to Gemini.
  /// Use this when you just want to generate and copy the prompt.
  Future<void> showPromptOnly({
    required BuildContext context,
    required String title,
    required String modelName,
    required Map<String, dynamic> generationConfig,
    bool useSheet = true,
  }) async {
    final promptLines = this.trim().split('\n').length;
    final charCount = this.length;

    final config = PromptPreviewConfig(
      title: title,
      prompt: this,
      modelName: modelName,
      generationConfig: generationConfig,
      onConfirm: () {}, // no-op
      onCancel: () {},
    );

    // Use a simplified dialog without the "Send" button
    if (useSheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _PromptOnlySheet(
          config: config,
          promptLines: promptLines,
          charCount: charCount,
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => _PromptOnlyDialog(
          config: config,
          promptLines: promptLines,
          charCount: charCount,
        ),
      );
    }
  }
}

class _PromptOnlyDialog extends StatelessWidget {
  final PromptPreviewConfig config;
  final int promptLines;
  final int charCount;

  const _PromptOnlyDialog({
    required this.config,
    required this.promptLines,
    required this.charCount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.description, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(config.title, style: AppText.section)),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model & config info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model: ${config.modelName}', style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Lines: $promptLines  •  Characters: $charCount', style: AppText.hint),
                  const SizedBox(height: 4),
                  Text('Config: ${_formatConfig(config.generationConfig)}', style: AppText.hint),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Prompt content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    config.prompt,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: AppColors.text),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Actions - only Copy and Close
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: config.prompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prompt copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_all, size: 18),
                  label: const Text('Copy Prompt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatConfig(Map<String, dynamic> config) {
    final parts = <String>[];
    if (config['temperature'] != null) parts.add('temp: ${config['temperature']}');
    if (config['maxOutputTokens'] != null) parts.add('maxTokens: ${config['maxOutputTokens']}');
    if (config['thinkingConfig'] != null) parts.add('thinking: ${config['thinkingConfig']}');
    if (config['responseMimeType'] != null) parts.add('mime: ${config['responseMimeType']}');
    return parts.join('  •  ');
  }
}

class _PromptOnlySheet extends StatelessWidget {
  final PromptPreviewConfig config;
  final int promptLines;
  final int charCount;

  const _PromptOnlySheet({
    required this.config,
    required this.promptLines,
    required this.charCount,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.description, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(config.title, style: AppText.section)),
                  IconButton(
                    icon: const Icon(Icons.copy_all),
                    tooltip: 'Copy full prompt',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: config.prompt));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prompt copied to clipboard')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Model info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      Text('Model: ', style: AppText.small),
                      Text(config.modelName, style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      Text('$promptLines lines  •  $charCount chars', style: AppText.hint),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Config: ${_formatConfig(config.generationConfig)}', style: AppText.hint),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Prompt content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(
                      config.prompt,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: AppColors.text),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatConfig(Map<String, dynamic> config) {
    final parts = <String>[];
    if (config['temperature'] != null) parts.add('temp: ${config['temperature']}');
    if (config['maxOutputTokens'] != null) parts.add('maxTokens: ${config['maxOutputTokens']}');
    if (config['thinkingConfig'] != null) parts.add('thinking: ${config['thinkingConfig']}');
    if (config['responseMimeType'] != null) parts.add('mime: ${config['responseMimeType']}');
    return parts.join('  •  ');
  }
}