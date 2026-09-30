# Fun Learning With Palak App Overview

## Product Summary

This is a Flutter content-planning and production app for the Fun Learning With Palak Instagram brand. It supports the full creator workflow: capture an idea, develop content for one or more Instagram formats, prepare copy and visual prompts, build a narrated reel, and keep drafts on the device.

The brand focuses on playful learning, screen-free activities, everyday parenting situations, and the characters Ria, Rio, and Cuty. Brand defaults target parents of preschoolers; individual briefs can narrow the age range or audience.

The app is local-first. It does not publish to Instagram, sync a creator account, or guarantee reach or view counts.

## Dashboard

The dashboard is the entry point. It provides:

| Entry | Purpose |
| --- | --- |
| Create Content | Prepare a post and create outputs for selected formats, including carousel, Reel, Trial Reel, and single image. Gemini can generate structured content when configured; local templates are available as a fallback. |
| Reel | Create a story-based reel through the script, scene, voice, and video workflow. |
| Trial Reel | Prepare a short, fast-cut compilation aimed at testing content with new viewers. Reach is not guaranteed. |
| Carousel | Create carousel copy and image prompts. |
| Image | Prepare a single-image post and its visual prompt and caption. |
| Idea Vault | Capture, edit, organize, develop, and delete raw ideas. |
| Settings | Configure the Gemini provider and selected content defaults. |
| Promotion Comments | Open the reusable comment vault. |

Saved stories are available from the folder action in the dashboard app bar.

## Main Workflows

### Create Content and Quick Content Studio

Quick Content Studio is for preparing post packages without going through the full video-rendering workflow. The form supports a title, post type, audience, goal, mood, hook, main idea, problem, lesson, visual style, CTA, and generated or editable copy.

Depending on the chosen action and provider configuration, the app can use Gemini or local templates. A multi-format package adapts one core idea into format-specific content rather than starting with unrelated ideas. Outputs can include hooks, scripts or slide text, image prompts, captions, hashtags, pinned comments, and reply comments.

Quick Content Studio also includes:

- Saved post ideas: save a completed idea, reopen it in the form, copy its contents, or delete it with confirmation.
- Recent post history: generated packages are kept locally, with history limited to the most recent 50 entries.
- Built-in post packages and bulk paste for importing structured post text.
- Carousel slide-count selection and prompts that follow the current slide content.
- A posting pack view for reviewing and copying or sharing format-specific outputs.

### Idea Vault

The dashboard Idea Vault is implemented in `lib/quick_content.dart`. It is separate from the saved post-idea list in Quick Content Studio.

Each raw idea can have a title, a short description, notes, a content bucket, and a status. The vault supports adding, editing, filtering, and confirmed deletion. An idea can be sent into the multi-format workflow for development.

The Idea Vault's local records use `idea_inbox.json`. The saved post-idea list uses `quick_ideas.json`; these are separate collections with different purposes.

### Reel Maker

The Reel workflow starts with a story brief. It supports story suggestions for common preschool situations and a story check that evaluates qualities such as real-life relevance, hook, curiosity, emotion, originality, character fit, and potential save/share value. The check is editorial guidance, not a prediction of Instagram performance.

The production flow is:

1. Write or select a story and set duration, language, and style.
2. Generate a timed script and scene/image prompts with Gemini. Short scripts can be generated with prompts in one request; longer scripts can use the fallback multi-request path.
3. Review and edit script lines, cover text, scene descriptions, and image prompts.
4. Import or select images and choose narration settings.
5. Render the portrait video locally, review it, and save it to the device gallery.

A story project autosaves locally. Existing script and prompt results are reused when their source story has not changed, avoiding unnecessary repeat requests.

### Voice and Video

Voice options include the device's text-to-speech engine, Gemini text-to-speech, and ElevenLabs. Phone speech works offline when the required language is installed; the network-based engines require their respective credentials and connectivity.

The local reel renderer uses FFmpeg to assemble a portrait video, images, voice audio, captions, motion, optional music, and closing elements. The renderer is designed around a 1080 x 1920, 30 fps output and includes Instagram-safe placement for captions and cover text.

The Shot Planner asks Gemini to write shot-by-shot prompts in a Veo-friendly structure. It is a prompt-planning feature; it does not itself call Veo to generate remote video clips. Image-to-video assembly remains a separate local workflow.

### Planning and Content Library

The planning tools contain built-in hooks, posting-time suggestions, and a manual post-results log. Results can be grouped by content bucket. Suggested posting times are starting assumptions; use the app's results log and real account data to adjust them.

The content library and built-in post files provide reusable examples and packages. Character reference images are stored under `assets/characters/`; additional content ideas are in `assets/ideas/`. Music assets are documented under `assets/music/` and must be included in the Flutter asset configuration before use.

### Promotion Comment Vault

The Promotion Comments dashboard entry opens a dedicated, scrollable vault. It shows one wrapping comment per row, supports copying a comment, adding a new comment, and filtering comments by bucket. Starter comments are built in, and custom comments are stored on the device.

The store reads both the current object format (comment text plus optional bucket) and older plain-string entries, so existing saved comments remain compatible. The local file is `promo_comments.json`.

## Brand and Content Model

`lib/brand_system.dart` contains the core brand defaults, character descriptions, content buckets, and supported formats. Generated visual prompts can use the character-lock descriptions for:

- Ria: curious, playful, energetic, and a little mischievous.
- Rio: sweet, determined, and often quick to say no.
- Cuty: a small white bunny with a pink bow; calm and observant.

Content buckets describe the kind of post (for example, challenge, conversation, activity, humor, or age practice). Formats describe how the content is presented (for example, carousel, Reel, Trial Reel, or single image). A bucket and a format are separate choices.

The content package model can hold a hook, slides or shots, visual prompts, caption, CTA, hashtags, pinned comment, and varied reply comments. Some parts use local templates; Gemini-backed paths can generate structured content and regenerate selected sections.

## AI and Credentials

Gemini is the app's only text/content AI provider. There is no OpenAI client, OpenAI API-key field, or OpenAI Idea Lab backend in the app. If Gemini is unavailable or not configured, supported Quick Content flows can fall back to local templates; direct Gemini-backed story, prompt, and voice workflows still require a working Gemini credential.

The Gemini key used by Quick Content can be configured in Settings. Other direct Gemini services use the app's local secret configuration. Keep real credentials out of Git, screenshots, exported files, and distributed builds. A key embedded in a mobile app should be treated as extractable; a server-side proxy with authentication and rate limits is preferable before distributing the app broadly.

ElevenLabs is an optional voice service, not a second text/content provider. Its voice credential is separate from the Gemini content workflow.

## Local Data and Backups

Most working data is stored as JSON in the app's documents directory. Important stores include:

| Data | Local store |
| --- | --- |
| Story projects, scripts, edits, prompts, voice and render state | One JSON file per story under `stories/` |
| Raw Idea Vault records | `idea_inbox.json` |
| Saved Quick Content ideas | `quick_ideas.json` |
| Recent generated post history | `quick_post_history.json` |
| Promotion comments | `promo_comments.json` |
| Content library | `content_library.json` |
| Character configuration | `characters.json` |
| Planning hooks and schedule | `hooks.json` and `schedule.json` |
| Gemini Quick Content key and selected defaults | SharedPreferences |

Story changes also schedule a backup through the project backup helper; the destination and behavior depend on the platform. Other local JSON data is not cloud-synced. Uninstalling the app can remove its local documents, so keep any required exports or backups separately.

The Settings screen currently labels data export/import actions, but those handlers are placeholders and do not yet perform an export or import.

## Important Source Files

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | App startup, dashboard routing, story/reel workflow, and Gemini-backed story operations. |
| `lib/creator_home.dart` | Creator dashboard and entry points. |
| `lib/quick_content.dart` | Quick Content Studio, multi-format tools, Idea Vault, saved ideas/history, Trial Reel, and Promotion Comments vault. |
| `lib/brand_system.dart` | Brand defaults, characters, buckets, and content formats. |
| `lib/ai_provider.dart`, `lib/gemini_client.dart` | Content-provider contract, Gemini implementation, and local fallback behavior. |
| `lib/story_ideas.dart` | Story idea generation and story quality checks. |
| `lib/prompt_builder.dart`, `lib/prompt_screen.dart` | Timed script and visual-prompt generation and review. |
| `lib/projects.dart` | Story project persistence, autosave, and backup coordination. |
| `lib/voice.dart` | Phone, Gemini, and ElevenLabs speech generation. |
| `lib/video_builder.dart`, `lib/music.dart`, `lib/caption_renderer.dart` | Local video assembly, music selection, and on-video captions. |
| `lib/format_adapter.dart`, `lib/posting_pack.dart` | Format conversion and copy/share-ready posting packs. |
| `lib/plan_data.dart`, `lib/plan_screen.dart` | Hooks, posting schedule, and manual results tracking. |
| `lib/settings_screen.dart` | Gemini configuration, defaults, app behavior, and data controls. |
| `test/widget_test.dart` | Focused widget and script-parsing tests. |

The dashboard currently routes to the Idea Vault implemented in `quick_content.dart`. `lib/idea_inbox.dart` is a separate model/store implementation and is not the dashboard route.

## Fast Android Wireless Development

Use `run_phone.ps1` from the project root to add Android platform-tools to the current PowerShell session, connect the phone, list Flutter devices, and launch the app.

Pair only if the phone has not already been paired with this computer:

```powershell
.\run_phone.ps1 -Pair
```

Enter the pairing IP and port from Android's "Pair device with pairing code" screen, then enter the code when ADB prompts. The script next asks for the current IP and port on the main Wireless debugging screen and starts the app.

For later sessions, pairing is normally unnecessary. Run:

```powershell
.\run_phone.ps1
```

Enter the current IP and port from the main Wireless debugging screen. To skip that prompt:

```powershell
.\run_phone.ps1 -DeviceAddress "192.168.1.10:37639"
```

Keep the `flutter run` terminal open while editing. Press `r` there to hot reload a small Dart/UI change, `R` to hot restart the Dart app, and `q` to stop it. If launching from the VS Code Flutter debugger, use its Hot Reload action or save-triggered reload instead.

Do not run `flutter clean`, `flutter pub get`, analysis, and tests after every small edit:

- Run `flutter pub get` after changing dependencies in `pubspec.yaml`.
- Use `flutter clean` only to recover from stale/corrupt build output or when native build configuration requires a clean rebuild.
- Run `flutter analyze` and `flutter test` at meaningful checkpoints, before sharing changes, or when investigating a relevant issue.
- Changes to Android permissions, Gradle files, or native plugins need a full stop/rebuild; Dart hot reload cannot apply native changes.

Image selection, text-to-speech, FFmpeg rendering, and saving to the gallery depend on platform permissions and native plugin support, so validate those workflows on the target phone.

## Current Limitations

- The app prepares content; Instagram publishing and scheduling are manual.
- Reach and view counts cannot be predicted or guaranteed by a prompt, score, or posting-time suggestion.
- Veo video generation is not connected; the Shot Planner currently generates prompts only.
- Data is primarily local, with no account-based cloud sync.
- Settings export/import controls are not implemented yet.
- Voice engines other than the device TTS require separate credentials and network access.
- Gemini model access, rate limits, supported regions, and quotas depend on the user's Google AI account.
