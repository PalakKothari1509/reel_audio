import 'package:flutter/material.dart';

import 'theme.dart';

class CreatorHomeScreen extends StatelessWidget {
  final VoidCallback onReel;
  final VoidCallback onTrialReel;
  final VoidCallback onCarousel;
  final VoidCallback onSingleImage;
  final VoidCallback onMultiFormat;
  final VoidCallback onIdeaVault;
  final VoidCallback onSavedStories;
  final VoidCallback onSettings;

  const CreatorHomeScreen({
    super.key,
    required this.onReel,
    required this.onTrialReel,
    required this.onCarousel,
    required this.onSingleImage,
    required this.onMultiFormat,
    required this.onIdeaVault,
    required this.onSavedStories,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fun Learning With Palak'),
        actions: [
          IconButton(
            tooltip: 'Saved stories',
            icon: const Icon(Icons.folder_open),
            onPressed: onSavedStories,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('What are you creating today?', style: AppText.screenTitle),
          Gap.s,
          const Text('Choose a starting point. Your work stays saved in the app.', style: AppText.hint),
          Gap.l,
          _ActionCard(
            icon: Icons.auto_awesome,
            colour: AppColors.primary,
            title: 'Create Content',
            subtitle: 'One idea → Carousel, Reel, Trial Reel, Image (all at once)',
            onTap: onMultiFormat,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.movie_creation_outlined,
            colour: AppColors.accent,
            title: 'Reel',
            subtitle: 'Full reel workflow: story → script → images → voice → video',
            onTap: onReel,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.play_circle_outline,
            colour: AppColors.accent,
            title: 'Trial Reel',
            subtitle: '60-sec compilation for non-follower reach (hook, fast cuts, CTA)',
            onTap: onTrialReel,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.view_carousel_outlined,
            colour: AppColors.accent,
            title: 'Carousel',
            subtitle: 'Enter idea → get slide prompts for all carousel pages',
            onTap: onCarousel,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.image_outlined,
            colour: AppColors.warning,
            title: 'Image',
            subtitle: 'Enter idea → get 7 different image prompts for Meta AI',
            onTap: onSingleImage,
          ),
          Gap.m,
          _ActionCard(
            icon: Icons.lightbulb_outline,
            colour: AppColors.primary,
            title: 'Idea Vault',
            subtitle: 'Capture, organize & develop ideas (💡📝✅📤♻️)',
            onTap: onIdeaVault,
          ),
          Gap.l,
          _ActionCard(
            icon: Icons.settings_outlined,
            colour: Colors.grey.shade600,
            title: 'Settings',
            subtitle: 'AI provider, API keys, defaults, export/import data',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.colour,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colour.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colour.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: colour),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.screenTitle.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.hint),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
