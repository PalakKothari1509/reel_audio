# Fun Learning With Palak — Quick Start

## Prerequisites
- Flutter 3.10+
- Android SDK (for APK builds)
- Google Gemini API key (for online mode; optional)

## Running the app
```bash
flutter pub get
flutter run
```

## Offline mode (no API key needed)
- Tap "Offline Story Generator" on the dashboard
- Select characters (all 7: Ria, Rio, Cuty, Mumma, Papa, Daadi, Teacher)
- Select from Content Library or generate randomly
- Choose duration (20s/30s/40s/60s)
- Tap "Generate Story (No Internet Required)"

## Online mode (requires API key)
- Add API key in Settings > API Keys
- Use any content studio feature (Reel from Images, Image Prompt, Carousel, Gemini Video)
- App auto-falls back to offline mode if Gemini returns 429/400/503 errors

## Tests
```bash
flutter test
# Currently 426 tests passing
```

## Project structure
```
lib/
├── master_prompt.dart       # Shared prompt constants (single source of truth)
├── characters.dart          # Character definitions (all 7 characters)
├── hook_system.dart         # Hook/text generation functions
├── content_ideas.dart       # HookIdea model + kDefaultHooks library
├── story_generator_offline.dart   # StoryGenerator (11 templates)
├── video_prompt_generator_offline.dart  # Video prompt generation
├── offline_engagement.dart         # Caption, hashtags, engagement
├── content_studio_service.dart     # Online Gemini generation
├── content_studio_screens.dart     # UI screens with offline fallback
├── idea_input_screen.dart          # Shared idea input UI
├── idea_review_screen.dart         # Idea review/approval UI
├── offline_story_maker_screen.dart # Offline generation screen
└── gemini_call.dart                # HTTP wrapper for Gemini API
```
