import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_key_store.dart';
import 'content_studio_service.dart';
import 'idea_input_screen.dart';
import 'prompt_preview.dart';

class ImagePromptScreen extends StatelessWidget {
  final ApiKeyStore keyStore;

  const ImagePromptScreen({super.key, required this.keyStore});

  @override
  Widget build(BuildContext context) {
    return IdeaInputScreen(
      feature: ContentFeature.imagePrompt,
      onGenerate:
          ({
            required idea,
            required characters,
            required additionalInstructions,
            readyPrompt,
            caption,
            pinnedComment,
          }) async {
            try {
              final result = await generateImagePrompt(
                idea: idea,
                characters: characters,
                additionalInstructions: additionalInstructions,
                apiKey: keyStore.getGeminiApiKey(),
              );
              if (context.mounted) {
                await _showPromptResults(context, 'Image Prompt', [
                  result.prompt,
                ]);
              }
            } catch (error) {
              if (context.mounted) _showError(context, error);
            }
          },
      onGeneratePromptOnly:
          ({
            required idea,
            required characters,
            required additionalInstructions,
            readyPrompt,
          }) {
            final prompt = buildImageGenerationPrompt(
              idea: idea,
              characters: characters,
              additionalInstructions: additionalInstructions,
            );
            prompt.showPromptOnly(
              context: context,
              title: 'Image Prompt',
              modelName: 'gemini-3.8-flash',
              generationConfig: const {
                'temperature': 0.7,
                'maxOutputTokens': 4096,
              },
            );
          },
    );
  }
}

class CarouselPromptsScreen extends StatelessWidget {
  final ApiKeyStore keyStore;

  const CarouselPromptsScreen({super.key, required this.keyStore});

  @override
  Widget build(BuildContext context) {
    const slideCount = 5;
    return IdeaInputScreen(
      feature: ContentFeature.carouselPrompts,
      onGenerate:
          ({
            required idea,
            required characters,
            required additionalInstructions,
            readyPrompt,
            caption,
            pinnedComment,
          }) async {
            try {
              final result = await generateCarouselPromptsWithPreview(
                context: context,
                idea: idea,
                slideCount: slideCount,
                characters: characters,
                additionalInstructions: additionalInstructions,
                apiKey: keyStore.getGeminiApiKey(),
                useSheet: true,
              );
              if (context.mounted) {
                await _showPromptResults(
                  context,
                  result.title,
                  result.slides.map((slide) => slide.prompt).toList(),
                );
              }
            } catch (error) {
              if (context.mounted) _showError(context, error);
            }
          },
      onGeneratePromptOnly:
          ({
            required idea,
            required characters,
            required additionalInstructions,
            readyPrompt,
          }) {
            final prompt = buildCarouselPromptsPrompt(
              idea: idea,
              slideCount: slideCount,
              characters: characters,
              additionalInstructions: additionalInstructions,
            );
            prompt.showPromptOnly(
              context: context,
              title: 'Carousel Prompts',
              modelName: 'gemini-3.8-flash',
              generationConfig: kCarouselGenConfig,
            );
          },
    );
  }
}

class GeminiVideoScreen extends StatelessWidget {
  final ApiKeyStore keyStore;

  const GeminiVideoScreen({super.key, required this.keyStore});

  @override
  Widget build(BuildContext context) {
    return IdeaInputScreen(
      feature: ContentFeature.geminiVideo,
      onGenerate:
          ({
            required idea,
            required characters,
            required additionalInstructions,
            readyPrompt,
            caption,
            pinnedComment,
          }) async {
            try {
              final result = await generateMasterReelPromptsWithPreview(
                context: context,
                idea: idea,
                characters: characters,
                additionalInstructions: additionalInstructions,
                storySpecificPrompt: readyPrompt ?? '',
                hasReferenceImages: false,
                apiKey: keyStore.getGeminiApiKey(),
                useSheet: true,
              );
              if (context.mounted) {
                await _showPromptResults(
                  context,
                  result.storyTitle,
                  result.parts.map((part) => part.promptText).toList(),
                );
              }
            } catch (error) {
              if (context.mounted) _showError(context, error);
            }
          },
      onGeneratePromptOnly:
          ({
            required idea,
            required characters,
            required additionalInstructions,
            readyPrompt,
          }) {
            final prompt = buildMasterReelPrompt(
              idea: idea,
              characters: characters,
              additionalInstructions: additionalInstructions,
              storySpecificPrompt: readyPrompt ?? '',
            );
            prompt.showPromptOnly(
              context: context,
              title: 'Master 30-Second Reel (3 Clips)',
              modelName: 'gemini-3.8-flash',
              generationConfig: kVideoGenConfig,
            );
          },
    );
  }
}

Future<void> _showPromptResults(
  BuildContext context,
  String title,
  List<String> prompts,
) async {
  final text = prompts
      .asMap()
      .entries
      .map((entry) {
        return 'PART ${entry.key + 1}\n${entry.value}';
      })
      .join('\n\n');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            ListTile(
              title: Text(title),
              trailing: IconButton(
                tooltip: 'Copy prompts',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prompts copied')),
                    );
                  }
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(text),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showError(BuildContext context, Object error) {
  if (error.toString().contains('User cancelled')) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Could not generate content: $error')));
}
