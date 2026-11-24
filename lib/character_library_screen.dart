import 'package:flutter/material.dart';

import 'brand_system.dart';
import 'theme.dart';

/// Displays every registered character definition from `character_definitions.dart`.
///
/// Read-only — character data is not modified here. The protected
/// `lib/character_definitions.dart` is only read, never written.
class CharacterLibraryScreen extends StatelessWidget {
  const CharacterLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character Library')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: CharacterLibrary.registered.length,
        itemBuilder: (context, index) {
          final c = CharacterLibrary.registered[index];
          return _CharacterCard(c);
        },
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character c;

  const _CharacterCard(this.c);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text(c.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c.name,
                            style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: ${c.id}',
                              style: AppText.small.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Role: ${c.role}',
                        style: AppText.small.copyWith(color: AppColors.textSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _FieldRow('Appearance', c.appearance),
            _FieldRow('Personality', c.personality),
            _FieldRow('Description', c.description),
            if (c.speechPattern.isNotEmpty)
              _FieldRow('Speech Pattern', c.speechPattern),
            _FieldRow('Voice', c.voice),
            _FieldRow('Image Prompt', c.imagePromptDescription),
            if (c.assetPath != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.image_outlined, size: 16, color: AppColors.textFaint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Asset: ${c.assetPath}',
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textFaint,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: AppText.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            TextSpan(
              text: value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppColors.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
