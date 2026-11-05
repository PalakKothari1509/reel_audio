# How the “Show Prompt Only” Button Works

## What it does

The button builds the text prompt for the selected feature and shows it on screen. It does not send the prompt to Gemini or generate content. You can read the prompt, copy it, and close the preview.

## What happens when you tap it

1. The app checks that you have entered or selected an idea. If the idea is empty, it shows a message asking you to enter one.
2. The app collects the idea, selected characters, and any extra instructions. If no characters are selected, it uses the default characters.
3. The screen creates the prompt for that feature. For example, the 30-second reel screen builds a reel prompt; other content screens build their own prompt.
4. The app opens a preview sheet showing the prompt, model name, and settings.
5. Tap the copy icon to copy the prompt, or close the sheet to return to the previous screen.

For **Gemini Story Video**, selecting an idea that has a saved Ready Prompt combines that story with the shared style, character, safety, and output rules. **Show Prompt Only** and **Generate** use the same combined prompt. The story prompt guides the scenes and dialogue; the master rules control continuity, safety, and the final JSON format.

## Why it does not generate content

The preview is for viewing and copying only. It has no Send or Generate action, and opening it does not call Gemini. You do not need an API key just to view or copy the prompt.

## Where to find the code

- [`lib/idea_input_screen.dart`](../lib/idea_input_screen.dart) shows the button when the screen has a prompt-only callback, checks the idea, and passes the input to the feature screen.
- [`lib/content_studio_screens.dart`](../lib/content_studio_screens.dart) builds prompts for the content-studio screens.
- [`lib/prompt_preview.dart`](../lib/prompt_preview.dart) opens the preview sheet and handles copying and closing it.
- [`lib/main.dart`](../lib/main.dart) has a separate **Show Prompt** button for the story quality check. It uses the same preview style for a story-check prompt.
