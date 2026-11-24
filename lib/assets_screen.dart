import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brand_system.dart';
import 'projects.dart';
import 'theme.dart';

/// Lists assets available to the app: character reference images bundled in
/// the asset directory, and saved project pictures stored on the device.
///
/// Independent from Image Prompts and Carousel Prompts — this screen only
/// browses assets, it does not generate images or claims any media exists.
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assets')),
      body: Column(
        children: [
          Expanded(child: _CharacterAssets()),
          const Divider(height: 1),
          Expanded(child: _ProjectAssets()),
        ],
      ),
    );
  }
}

/// Character reference images bundled with the app.
class _CharacterAssets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHARACTER IMAGES', style: AppText.section),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: CharacterLibrary.registered.length,
              itemBuilder: (context, index) {
                final c = CharacterLibrary.registered[index];
                return _AssetTile(
                  name: c.name,
                  emoji: c.emoji,
                  role: c.role,
                  imagePath: c.assetPath,
                  imagePrompt: c.imagePromptDescription,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Saved project pictures stored in the app's documents directory.
class _ProjectAssets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: ProjectStore.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final projects = snapshot.data!;
        final hasImages = projects.where((p) => p.images.isNotEmpty).toList();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAVED PROJECT IMAGES', style: AppText.section),
              const SizedBox(height: 8),
              if (hasImages.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No saved project images yet.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: hasImages.length,
                    itemBuilder: (context, index) {
                      final p = hasImages[index];
                      return _AssetTile(
                        name: p.displayName,
                        emoji: '📁',
                        role: '${p.images.length} image(s)',
                        imagePath: p.images.isNotEmpty ? p.images.first : null,
                        imagePrompt: 'Saved with project "${p.displayName}"',
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AssetTile extends StatelessWidget {
  final String name;
  final String emoji;
  final String role;
  final String? imagePath;
  final String? imagePrompt;

  const _AssetTile({
    required this.name,
    required this.emoji,
    required this.role,
    this.imagePath,
    this.imagePrompt,
  });

  @override
  Widget build(BuildContext context) {
    final assetExists = imagePath != null &&
        (imagePath!.startsWith('assets/') ||
            (File(imagePath!).existsSync()));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceAlt,
              child: ClipOval(
                child: assetExists
                    ? (imagePath!.startsWith('assets/')
                        ? Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                            errorBuilder: (_, _, _) => _emojiFallback(),
                          )
                        : Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                            errorBuilder: (_, _, _) => _emojiFallback(),
                          ))
                    : _emojiFallback(),
              ),
            ),
          ],
        ),
        title: Text(name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(role, style: AppText.small),
            if (imagePrompt != null && imagePrompt!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                imagePrompt!,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textFaint,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copy path',
          onPressed: assetExists
              ? () {
                  Clipboard.setData(ClipboardData(text: imagePath!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Path copied')),
                  );
                }
              : null,
        ),
      ),
    );
  }

  Widget _emojiFallback() {
    return Center(
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}
