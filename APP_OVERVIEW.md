# Fun Learning With Palak App Overview

## Product Summary

This is a Flutter content-planning and production app for the Fun Learning With Palak
Instagram brand. It supports the creator workflow: capture an idea, develop content for
one or more Instagram formats, prepare copy and visual prompts, build a narrated reel,
and keep drafts on the device.

The brand focuses on playful learning, screen-free activities, everyday parenting
situations, and the characters Ria, Rio, and Cuty. **Brand defaults target parents of
children aged 1–4.** Individual briefs can narrow the age range or audience.

The app is local-first. It does not publish to Instagram, sync a creator account, or
guarantee reach or view counts. Nothing in the app or its prompts predicts a view count.

## The Content Model

This is the part of the system that changed most recently, and it is what everything
downstream depends on. A single field called `Format` was found to be doing three
unrelated jobs, which made classification unreliable.

### Seven independent axes

| Axis | Meaning | Values |
| --- | --- | --- |
| **Pillar** | What value the content gives | `PLAY` `THINK` `DISCOVER` `TALK` `DO` |
| **Series** | Recurring brand world | the seven series, see below |
| **Content Type** | What is published | `Reel` `Carousel` `Trial Reel` `Image Slideshow Reel` `Static Image` `Story` |
| **Narrative Format** | How the idea is structured | the registered handbook formats |
| **Production Method** | How the asset is created | `Character images` `Real-life video` `Image slideshow` `Text-based` `Carousel` `Mixed` |
| **Goal** | The outcome being optimised | `Reach` `Non-follower Reach` `Saves` `Shares` `Comments` `Relatability` `Authority` `Follows` |
| **Status** | Where the idea is in production | `idea → approved → scripted → imagesReady → generated → posted → tested → archived` |

**Series:** Jugaadu Mummy · Life With Ria & Rio · Can Your Child Figure It Out? ·
Talk With Your Child · Try This At Home · Parent-Relatable · Age-Based Skills

The axes are independent and must not be collapsed into one another. A `Jugaadu Mummy`
episode can be `PLAY` or `DO`; Trial Reel is a publishing and testing type, not a
production method.

`Status` is production-aware on purpose. `imagesReady` is a real stage, because image
generation is where a Ria/Rio/Cuty story Reel spends most of its time, and an idea that
is written and one whose images exist have different next actions.

**Migration state is not `Status`.** `MigrationState` in `lib/content_axes.dart` is a
separate enum (`approved` / `suggested` / `needsReview` / `invalid` /
`archiveCandidate`) describing a *classification decision in progress*. Only
`approved` is ever written to the source file. The two share a word and mean different
things by it, and the distinction is enforced in code.

### Content Format Library

Narrative formats live in `content_formats.md` and are compiled into
`lib/format_handbook.dart` by `tool/sync_formats.dart`. **16 of 50 formats are
specified.** Each entry has nine canonical fields: ID, Name, Definition, Structure,
Best for, Best content types, Best goals, Example, Generation rules, plus an optional
`Default for`.

`FormatSpec.recommend()` scores a format on whether it supports the content type and
serves the goal, and `reason()` returns one line of human-readable justification. A tie
is broken by the declared `Default for`, which breaks ties only and never outranks a real
score difference. When nothing matches, `recommend()` returns **null** rather than
defaulting, so an unsupported format is never silently substituted.

## Dashboard

| Entry | Purpose |
| --- | --- |
| Create Content | Prepare a post and create outputs for selected formats. Gemini can generate structured content when configured; local templates are available as a fallback. |
| Reel | Create a story-based reel through the script, scene, voice, and video workflow. |
| Trial Reel | Prepare a short, fast-cut compilation aimed at testing content with new viewers. Reach is not guaranteed. |
| Carousel | Create carousel copy and image prompts. |
| Image | Prepare a single-image post and its visual prompt and caption. |
| Idea Vault | Capture, edit, organize, develop, and delete raw ideas. |
| Settings | Configure the Gemini provider and selected content defaults. |
| Promotion Comments | Open the reusable comment vault. |
| Caption Generator | **Legacy entry. Not wired into the dashboard's primary callbacks in the same way as the others, and scheduled for removal** once the unified Content Package exists. |

Saved stories are available from the folder action in the dashboard app bar.

Carousel, Trial Reel and Single Image each currently have **three separate entry
points**. They are slated to consolidate into one Create screen.

## Main Workflows

### Create Content and Quick Content Studio

Quick Content Studio is for preparing post packages without going through the full
video-rendering workflow. The form supports a title, post type, audience, goal, mood,
hook, main idea, problem, lesson, visual style, CTA, and generated or editable copy.

A multi-format package adapts one core idea into format-specific content rather than
starting with unrelated ideas. Outputs can include hooks, scripts or slide text, image
prompts, captions, hashtags, pinned comments, and reply comments.

Quick Content Studio also includes:

- Saved post ideas: save a completed idea, reopen it in the form, copy its contents, or
  delete it with confirmation.
- Recent post history: generated packages are kept locally, with history limited to the
  most recent 50 entries.
- Built-in post packages and bulk paste for importing structured post text.
- Carousel slide-count selection and prompts that follow the current slide content.
- A posting pack view for reviewing and copying or sharing format-specific outputs.

**Known gap:** the posting pack's save action is a placeholder. It reports "Content
Library integration coming soon", so a generated package cannot yet be written into the
library. This is the widest gap in the app: generation completes and then stops before
persistence.

### Idea Vault

The dashboard Idea Vault is implemented in `lib/quick_content.dart`. It is separate
from the saved post-idea list in Quick Content Studio.

Each raw idea can have a title, a short description, notes, a content bucket, and a
status. The vault supports adding, editing, filtering, and confirmed deletion. An idea
can be sent into the multi-format workflow for development.

The Idea Vault's local records use `idea_inbox.json`. The saved post-idea list uses
`quick_ideas.json`; these are separate collections with different purposes.

### Reel Maker

The Reel workflow starts with a story brief. It supports story suggestions for common
preschool situations and a story check that evaluates qualities such as real-life
relevance, hook, curiosity, emotion, originality, character fit, and potential
save/share value. **The check is editorial guidance, not a prediction of Instagram
performance.** The ten reach dimensions in `lib/quality_check.dart` are the same kind of
heuristic and are surfaced as internal heuristics, never as predictions.

The production flow is:

1. Write or select a story and set duration, language, and style.
2. Generate a timed script and scene/image prompts with Gemini. Short scripts can be
   generated with prompts in one request; longer scripts can use the fallback
   multi-request path.
3. Review and edit script lines, cover text, scene descriptions, and image prompts.
4. Import or select images and choose narration settings.
5. Render the portrait video locally, review it, and save it to the device gallery.

A story project autosaves locally. Existing script and prompt results are reused when
their source story has not changed, avoiding unnecessary repeat requests.

### Voice and Video

Voice options include the device's text-to-speech engine, Gemini text-to-speech, and
ElevenLabs. Phone speech works offline when the required language is installed; the
network-based engines require their respective credentials and connectivity.

The local reel renderer uses FFmpeg to assemble a portrait video, images, voice audio,
captions, motion, optional music, and closing elements. The renderer is designed around
a 1080 x 1920, 30 fps output and includes Instagram-safe placement for captions and
cover text.

The Shot Planner asks Gemini to write shot-by-shot prompts in a Veo-friendly structure.
It is a prompt-planning feature; it does not itself call Veo to generate remote video
clips. Image-to-video assembly remains a separate local workflow.

### Planning and Content Library

The planning tools contain built-in hooks, posting-time suggestions, and a manual
post-results log. Suggested posting times are starting assumptions; use the app's
results log and real account data to adjust them.

Character reference images are stored under `assets/characters/`. Additional content
ideas are in `assets/ideas/` — note these four files are **not bundled and not read by
the app**. Music assets are documented under `assets/music/` and must be added to the
Flutter asset configuration before use.

### Promotion Comment Vault

The Promotion Comments dashboard entry opens a dedicated, scrollable vault. It shows
one wrapping comment per row, supports copying a comment, adding a new comment, and
filtering comments by bucket. Starter comments are built in, and custom comments are
stored on the device.

The store reads both the current object format (comment text plus optional bucket) and
older plain-string entries, so existing saved comments remain compatible. The local file
is `promo_comments.json`.

## Content Idea Library

`content_ideas.md` is the source of truth for content ideas, holding **57 ideas**. Each
carries an id plus the axis metadata: Topic, Problem, Lesson, Format, Best content type,
Goal, Age, Characters, Hook Angle, Status, Priority, and Notes.

**The library is mid-migration and is not yet authoritative.** The axes are being
resolved one at a time, and only approved values will be written. Current state, per
`tool/check_axes.dart`:

| Axis | In source | Decided | Open |
| --- | --- | --- | --- |
| Pillar | 0 | 11 suggested, 1 archive candidate | 45 |
| Series | 34 | 0 | 23 |
| Narrative Format | 24 | 19 approved | 2 blocked |
| Content Type | 50 | 0 | 7 |
| Production Method | 50 | 0 | 7 |
| Goal | 51 | 0 | 6 |
| Status | 57 | 0 | 0 |

A value counts as resolved only if it came from the source file or from a human
decision. **Classifier inference is never counted as resolved.** Until every axis reads
zero open, generated idea data must not be treated as authoritative.

### Distribution mechanics

`tool/reach_mechanics.dart` checks each idea against the mechanics that decide
non-follower distribution — visual-first comprehension, one-second recognition, open
loop, share trigger, production simplicity, follower independence, and save trigger.

Each mechanic returns `pass`, `fail`, or **`unknown`**, where unknown means the idea's
text does not state it. It deliberately does not produce a 1–10 score: a self-assigned
score has no evidential basis and would read as calibrated data.

The current finding: **`share_trigger` is unknown on 56 of 57 ideas.** The library
describes what a post is, not why a stranger would watch it to the end or send it to
someone. Sixteen ideas cannot be reach candidates as written — seven need filming or are
reference content, nine need real-life video.

## Brand and Character Model

`lib/brand_system.dart` holds the brand defaults, the `CharacterLibrary`, and the
`ContentFormat` enum. `lib/characters.dart` holds the `CharacterStore` that persists
character edits on device.

`BrandDefaults.visualStyle` is the **single** definition of visual style, read by
`lib/prompts.dart` and injected by `buildBrandContext`. It is deliberately one constant,
so the visual vocabulary can be changed without touching character generation, scene
generation, reel generation, prompt templates, or individual ideas.

Characters carry a lock block appended to every image-generation request, and it is
derived from `CharacterLibrary.all` rather than a hardcoded subset, so adding a
character updates every prompt automatically.

Approved characters: Ria (two ponytails, pink bows, "toofani"), Rio (stubborn, quick to
say no, sweet underneath), Cuty (white bunny, pink bow), Mumma, Papa, Daadi, Teacher.

Content buckets (`challenge`, `conversation`, `activity`, `humor`, `agePractice`,
`community`) still exist and are hardcoded in ten modules. They are the legacy model and
are being replaced by the Pillar and Series axes; see the redesign plan.

## AI and Credentials

Gemini is the app's only text/content AI provider. There is no OpenAI client or OpenAI
API-key field in the Flutter app. **A `backend/` directory exists in the repository
containing a `.env` with a live OpenAI key, `node_modules`, and a `.gitignore`, but no
source code.** It is not referenced by the app and its purpose is unclear.

If Gemini is unavailable or not configured, supported Quick Content flows can fall back
to local templates. Direct Gemini-backed story, prompt, and voice workflows still
require a working Gemini credential.

The Gemini key used by Quick Content can be configured in Settings. Other direct Gemini
services use `lib/secrets.dart`. Keep real credentials out of Git, screenshots, exported
files, and distributed builds. **A key embedded in a mobile app should be treated as
extractable**; a server-side proxy with authentication and rate limits is preferable
before distributing the app broadly.

ElevenLabs is an optional voice service, not a second text/provider. Its credential is
separate from the Gemini content workflow.

**Known gap:** six call sites read `lib/secrets.dart` directly, so a key configured in
Settings is honoured in only a minority of paths. The Settings key is also stored
unencrypted in SharedPreferences.

## Local Data and Backups

Most working data is stored as JSON in the app's documents directory.

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

Story changes also schedule a backup through the project backup helper; the destination
and behavior depend on the platform. Other local JSON data is not cloud-synced.
Uninstalling the app can remove its local documents, so keep required exports
separately.

The Settings screen labels data export/import actions, but those handlers are
placeholders and do not yet perform an export or import.

## Content Authoring Toolchain

Markdown is the source of truth for authored content, and Dart is generated from it.
This keeps prompt construction synchronous and `const`, so a malformed line becomes a
compile error instead of a startup crash.

| Command | Purpose |
| --- | --- |
| `dart run tool/sync_formats.dart` | `content_formats.md` → `lib/format_handbook.dart` |
| `dart run tool/check_formats.dart` | Validates the handbook: ids, axis references, contested defaults |
| `dart run tool/propose_formats.dart` | Narrative-format proposals from beat descriptions |
| `dart run tool/check_axes.dart` | **Authoritative** axis coverage across all 57 ideas |
| `dart run tool/propose_axes.dart` | Proposals for every open axis value, in one file |
| `tool/classify_ideas.dart` | Infers axis values; `--apply` refuses unless everything resolves |
| `tool/check_ideas.dart` | Validates ideas against the frozen axes |
| `tool/check_pillars.dart` | Pins the five documented classifier false positives |
| `tool/reach_mechanics.dart` | Distribution-mechanics analysis |
| `tool/show_ideas.dart <id>...` | Prints the full text of named ideas |

Human decisions live in `tool/format_decisions.csv` and `tool/pillar_decisions.csv`, and
are stored as **migration metadata, not `IdeaStatus`.** An approved decision always
outranks classifier inference; the tools refuse to re-litigate a settled idea.

An unknown migration state is a hard error rather than a silent skip, because a skipped
row turns an approved decision into a missing one.

## Important Source Files

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | App startup, dashboard routing, story/reel workflow, Gemini-backed story operations. |
| `lib/creator_home.dart` | Creator dashboard and entry points. |
| `lib/content_axes.dart` | **The seven axes, `GenerationRecipe`, `MigrationState`.** |
| `lib/format_handbook.dart` | **Generated.** Format registry and recommendation engine. |
| `lib/content_ideas.dart` | Idea models, hooks, and the seeded day-post list. |
| `lib/quick_content.dart` | Quick Content Studio, Idea Vault, saved ideas/history, Trial Reel, Promotion Comments vault. |
| `lib/brand_system.dart` | Brand defaults, `CharacterLibrary`, `ContentFormat`, bucket library. |
| `lib/characters.dart` | `CharacterRef` and the on-device `CharacterStore`. |
| `lib/prompts.dart` | Master prompt shapes, style interpolation, character lock. |
| `lib/content_generator.dart` | `ContentPackage` and its JSON parsing. |
| `lib/quality_check.dart` | Quality checks and the ten reach heuristics. |
| `lib/ai_provider.dart`, `lib/gemini_client.dart`, `lib/gemini_call.dart` | Provider contract, Gemini implementation, HTTP call helper. |
| `lib/caption_generator.dart`, `lib/reply_assistant.dart` | **Standalone generators, scheduled for removal.** |
| `lib/story_ideas.dart` | Story idea generation and story quality checks. |
| `lib/prompt_builder.dart`, `lib/prompt_screen.dart` | Timed script and visual-prompt generation and review. |
| `lib/projects.dart` | Story project persistence, autosave, and backup coordination. |
| `lib/voice.dart` | Phone, Gemini, and ElevenLabs speech generation. |
| `lib/video_builder.dart`, `lib/music.dart`, `lib/caption_renderer.dart` | Local video assembly, music selection, on-video captions. |
| `lib/format_adapter.dart`, `lib/posting_pack.dart`, `lib/posting_kit.dart` | Format conversion and posting packs. |
| `lib/content_library.dart`, `lib/regenerator.dart` | Library storage and section regeneration. |
| `lib/plan_data.dart`, `lib/plan_screen.dart` | Hooks, posting schedule, manual results tracking. |
| `lib/settings_screen.dart` | Gemini configuration, defaults, app behavior, data controls. |
| `test/widget_test.dart` | **Currently does not compile**, so no test runs. |

`lib/idea_inbox.dart` and `lib/slide_prompt_list.dart` were deleted; the Idea Vault is
implemented in `quick_content.dart` and still stores to `idea_inbox.json`.

## Fast Android Wireless Development

Use `run_phone.ps1` from the project root to add Android platform-tools to the current
PowerShell session, connect the phone, list Flutter devices, and launch the app.

**Run it as `.\run_phone.ps1`.** A bare `run_phone.ps1` fails: PowerShell does not run
the current directory from the command name.

Pair only if the phone has not already been paired with this computer:

```powershell
.\run_phone.ps1 -Pair
```

Enter the pairing IP and port from Android's "Pair device with pairing code" screen,
then the code when ADB prompts. The script then asks for the current IP and port on the
main Wireless debugging screen and starts the app.

For later sessions, pairing is normally unnecessary:

```powershell
.\run_phone.ps1
```

To skip the prompt, pass the cached address:

```powershell
.\run_phone.ps1 -DeviceAddress "192.168.29.92:37423"
```

Keep the `flutter run` terminal open while editing. Press `r` for hot reload, `R` for
hot restart, and `q` to stop. If launching from the VS Code Flutter debugger, use its
Hot Reload action instead.

Do not run `flutter clean`, `flutter pub get`, analysis, and tests after every edit:

- Run `flutter pub get` after changing dependencies in `pubspec.yaml`.
- Use `flutter clean` only to recover from stale build output or when native build
  configuration requires a clean rebuild.
- Run `flutter analyze` and the `tool/` checks at meaningful checkpoints and before
  sharing changes.
- Changes to Android permissions, Gradle files, or native plugins need a full
  stop/rebuild; Dart hot reload cannot apply native changes.

Image selection, text-to-speech, FFmpeg rendering, and saving to the gallery depend on
platform permissions and native plugin support, so validate those on the target phone.

## Current Limitations

- **The posting pack cannot save.** A generated package stops before reaching the
  content library.
- **The idea library is mid-migration.** Most axis values are not yet approved, so idea
  data is not authoritative and must not drive generation.
- **The unified Content Package does not exist yet.** Four different models of "a
  complete post" are in use, and separate caption, hashtag and hook generators still
  exist alongside them.
- **The `script` field is generated and discarded.** Narration and per-scene dialogue are
  requested by the prompt and never read back.
- `test/widget_test.dart` does not compile, so `flutter test` fails and no test runs.
- Release builds are signed with the debug keystore and still use
  `com.example.reel_audio` as the application id, so they are not distributable.
- Calendar, Analytics and Experiments tabs do not exist yet.
- The app prepares content; Instagram publishing and scheduling are manual.
- Reach and view counts cannot be predicted or guaranteed by a prompt, score, or
  posting-time suggestion.
- Veo video generation is not connected; the Shot Planner generates prompts only.
- Data is primarily local, with no account-based cloud sync.
- Settings export/import controls are not implemented.
- Voice engines other than the device TTS require separate credentials and network
  access.
- Gemini model access, rate limits, supported regions, and quotas depend on the user's
  Google AI account.

## Development Status

See `REDESIGN_PLAN.md` for the full task list, current state, and remaining order. That
file tracks open work only; completed items are removed as they land.