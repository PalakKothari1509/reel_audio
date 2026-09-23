import 'package:flutter/material.dart';

import 'slide_prompts.dart';
import 'theme.dart';

// ── The slide prompts, as a list you can actually use ─────────────────────────
//
// Seven full prompts shown at once is a wall of text, and folded away behind a
// single "copied" button it is a wall of text nobody can check. Each slide gets its
// own row: closed it says which slide and what the picture is, open it shows the
// whole prompt, and every row copies on its own.

/// Every prompt as one block, for pasting all seven into an image tool at once.
String slidePromptsAsText(List<String> prompts) => prompts.join('\n\n---\n\n');

class SlidePromptList extends StatelessWidget {
  final List<String> prompts;
  final void Function(String text, String label) onCopy;

  const SlidePromptList({
    super.key,
    required this.prompts,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('SLIDE IMAGE PROMPTS  •  ${prompts.length}',
                  style: AppText.section),
            ),
            TextButton.icon(
              onPressed: () => onCopy(
                slidePromptsAsText(prompts),
                'All ${prompts.length} slide prompts',
              ),
              icon: const Icon(Icons.copy_all_outlined, size: 17),
              label: const Text('Copy all', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        Text(
          'One prompt per slide. Paste each one into your image tool to get the '
          'same characters and style across the whole post.',
          style: AppText.hint,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < prompts.length; i++)
          _SlidePromptTile(
            number: i + 1,
            total: prompts.length,
            prompt: prompts[i],
            onCopy: () => onCopy(prompts[i], 'Slide ${i + 1} prompt'),
          ),
      ],
    );
  }
}

class _SlidePromptTile extends StatelessWidget {
  final int number;
  final int total;
  final String prompt;
  final VoidCallback onCopy;

  const _SlidePromptTile({
    required this.number,
    required this.total,
    required this.prompt,
    required this.onCopy,
  });

  /// "Slide 3 of 7 — Step. Instagram image prompt for the post "..."."
  String get _heading {
    final firstLine = prompt.split('\n').first;
    final dot = firstLine.indexOf('. ');
    return dot > 0 ? firstLine.substring(0, dot) : firstLine;
  }

  /// The picture line, which is what actually differs between the prompts.
  String get _picture {
    for (final line in prompt.split('\n')) {
      if (line.startsWith('The picture: ')) {
        return line.substring('The picture: '.length);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        // The default divider above an expanded tile is a full-width line that
        // reads as a section break in a list where every row is one item.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 12, right: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: CircleAvatar(
            radius: 15,
            backgroundColor: number == 1 ? AppColors.accent : AppColors.primarySoft,
            child: Text('$number',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: number == 1 ? Colors.white : AppColors.primary)),
          ),
          title: Text(_heading,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text)),
          subtitle: _picture.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(_picture,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small),
                ),
          trailing: IconButton(
            tooltip: 'Copy slide $number prompt',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_all_outlined, size: 18),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(prompt,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.45, color: AppColors.text)),
            ),
            if (number < total) ...[
              const SizedBox(height: 6),
              Text('Slide $number of $total', style: AppText.small),
            ],
          ],
        ),
      ),
    );
  }
}
