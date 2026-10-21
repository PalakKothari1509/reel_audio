// HomeScreen - the dashboard for Fun Learning With Palak Content Studio.
//
// A simple task-oriented navigation hub: one primary action to start a reel,
// plus the places you go to manage ideas and see what you have made.

import 'package:flutter/material.dart';

import 'theme.dart';

typedef NavCallback = void Function();
typedef CreateCallback = void Function(String? ideaId);

class ContentStudioHome extends StatefulWidget {
  final CreateCallback onCreateReel;
  final NavCallback onMyContent;
  final NavCallback onSettings;

  /// New simplified callbacks.
  final NavCallback onContentLibrary;
  final NavCallback? onReviewAllIdeas;
  final NavCallback? onAddNewIdea;
  final CreateCallback? onCreateContent;

  /// Legacy support — if provided, these appear as additional Create options.
  final NavCallback? onImagePrompt;
  final NavCallback? onCarouselPrompts;
  final NavCallback? onGeminiVideo;

  /// Optional offline story generator.
  final NavCallback? onOfflineStory;

  const ContentStudioHome({
    super.key,
    required this.onCreateReel,
    required this.onMyContent,
    required this.onSettings,
    required this.onContentLibrary,
    this.onReviewAllIdeas,
    this.onAddNewIdea,
    this.onCreateContent,
    this.onImagePrompt,
    this.onCarouselPrompts,
    this.onGeminiVideo,
    this.onOfflineStory,
  });

  @override
  State<ContentStudioHome> createState() => _ContentStudioHomeState();
}

class _ContentStudioHomeState extends State<ContentStudioHome> {
  @override
  Widget build(BuildContext context) {
    final createActions = <Widget>[
      _PrimaryAction(
        icon: Icons.auto_awesome,
        title: 'Create Content',
        subtitle: 'Select an idea from the library to generate story, script, prompts',
        onTap: () {
          final cb = widget.onCreateContent ?? widget.onCreateReel;
          cb(null);
        },
      ),
    ];

    if (widget.onAddNewIdea != null) {
      createActions.addAll([
        const SizedBox(height: 10),
        _PrimaryAction(
          icon: Icons.add,
          title: 'Add New Idea',
          subtitle: 'Write a new idea directly into the Content Library',
          onTap: widget.onAddNewIdea!,
        ),
      ]);
    }
    if (widget.onImagePrompt != null) {
      createActions.addAll([
        const SizedBox(height: 10),
        _PrimaryAction(
          icon: Icons.image_outlined,
          title: 'Image Generation Prompt',
          subtitle: 'One detailed prompt ready to paste into an image generator',
          onTap: widget.onImagePrompt!,
        ),
      ]);
    }
    if (widget.onCarouselPrompts != null) {
      createActions.addAll([
        const SizedBox(height: 10),
        _PrimaryAction(
          icon: Icons.view_carousel_outlined,
          title: 'Carousel Generation',
          subtitle: 'Full set of slide prompts for a carousel post',
          onTap: widget.onCarouselPrompts!,
        ),
      ]);
    }
    if (widget.onGeminiVideo != null) {
      createActions.addAll([
        const SizedBox(height: 10),
        _PrimaryAction(
          icon: Icons.smart_display_outlined,
          title: 'Gemini Story Video',
          subtitle: 'Connected 10-second video prompts with continuity lock',
          onTap: widget.onGeminiVideo!,
        ),
      ]);
    }
    if (widget.onOfflineStory != null) {
      createActions.addAll([
        const SizedBox(height: 10),
        _PrimaryAction(
          icon: Icons.offline_bolt,
          title: 'Offline Story Generator',
          subtitle: 'Generate stories, video prompts, and captions without API',
          onTap: widget.onOfflineStory!,
        ),
      ]);
    }

    final goToActions = <Widget>[
      _NavCard(
        icon: Icons.library_books,
        iconColor: AppColors.primary,
        title: 'Content Library',
        subtitle: 'Browse, search, review, and edit every idea',
        onTap: widget.onContentLibrary,
      ),
    ];

    if (widget.onReviewAllIdeas != null) {
      goToActions.addAll([
        const SizedBox(height: 10),
        _NavCard(
          icon: Icons.visibility_outlined,
          iconColor: AppColors.warning,
          title: 'Review All Ideas',
          subtitle: 'Dashboard quick-filter for ideas needing attention',
          onTap: widget.onReviewAllIdeas!,
        ),
      ]);
    }

    goToActions.addAll([
      const SizedBox(height: 10),
      _NavCard(
        icon: Icons.video_library_outlined,
        iconColor: AppColors.accent,
        title: 'My Videos',
        subtitle: 'Upload, preview, and manage finished reels',
        onTap: widget.onMyContent,
      ),
    ]);

    final children = <Widget>[
      const Text(
        'Good morning, Palak!',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'What would you like to create today?',
        style: AppText.hint,
      ),
      const SizedBox(height: 24),
      const Text('Create', style: AppText.section),
      const SizedBox(height: 12),
      ...createActions,
      const SizedBox(height: 24),
      const Text('Go to', style: AppText.section),
      const SizedBox(height: 12),
      ...goToActions,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fun Learning With Palak'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: widget.onSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.icon,
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
            border: Border.all(color: AppColors.accent),
            gradient: LinearGradient(
              colors: [
                AppColors.accent,
                AppColors.surface,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: AppColors.surface),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.screenTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.hint),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.iconColor,
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
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: AppColors.text),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.screenTitle.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.hint),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
