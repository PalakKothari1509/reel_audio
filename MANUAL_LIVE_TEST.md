# Manual Live Gemini Test Procedure

## Prerequisites

1. **API Keys Configured**
   - Copy `lib/secrets.example.dart` to `lib/secrets.dart`
   - Add your Gemini API key from https://aistudio.google.com/apikey
   - Add your ElevenLabs API key from https://elevenlabs.io/app/speech-synthesis
   - Run `flutter pub get`

2. **Android Device/Emulator**
   - Physical device with USB debugging, OR
   - Android emulator (API 29+ recommended)

## Test Scenario

### Target Idea
- **Idea ID**: `idea_16`
- **Title**: `Ek Aur Story?!`
- **Characters**: Cuty, Mumma
- **Score**: 84 (Ready to Post)

### Edited Narrative (must include this exact phrase)
```
LIVE ANDROID GEMINI TEST: Cuty discovers a magical bedtime book that reads itself. Each page turns automatically as she listens. She falls asleep mid-chapter. Mumma closes the book and kisses her forehead. The book glows softly on the nightstand.
```

## Step-by-Step Procedure

### 1. Build and Run
```bash
flutter run --debug
```
Or build APK:
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Open Content Library
- Launch app
- Navigate to Content Library (main screen)
- Find `idea_16` "Ek Aur Story?!" (Child Chaos category)

### 3. Open StoryScreen
- Tap "Create Content" on the idea
- Verify the story text loads (original: sand timer bedtime story)

### 4. Edit Story
- Tap the story text field
- Replace entire content with the edited narrative above (must include "LIVE ANDROID GEMINI TEST")
- Verify the edited text is visible

### 5. Generate Video
- Tap the **videocam** icon (Generate Video button) in the app bar
- App navigates to GeminiVideoScreen
- Tap "Generate" button

### 6. Observe Generation
- Loading indicator appears with "Waiting..." messages if rate limited
- If model switches: "Model rejected request — switching..." or "Rate limited — switching..."
- On success: Bottom sheet appears with **3 parts** labeled PART 1, PART 2, PART 3

### 7. Verify Three-Part Output
Check each part in the bottom sheet:

**PART 1** (Hook & Problem, 0-10s):
- [ ] Contains "LIVE ANDROID GEMINI TEST"
- [ ] Contains "magical bedtime book" or "reads itself"
- [ ] Characters: Cuty and Mumma mentioned
- [ ] Setting: Cuty's bedroom, bedtime
- [ ] Duration: 10 seconds (0-10)

**PART 2** (Twist & Escalation, 10-20s):
- [ ] Continuity: "Continuing seamlessly from the final frame of Clip 1"
- [ ] Cuty falling asleep mid-chapter
- [ ] Book still glowing

**PART 3** (Resolution, 20-30s):
- [ ] Continuity: "Continuing directly from the final frame of Clip 2"
- [ ] Mumma closes book, kisses forehead
- [ ] Book glow fades

**All Parts**:
- [ ] 9:16 vertical aspect ratio mentioned
- [ ] 30-second total duration
- [ ] Soft 3D Pixar/Disney visual style
- [ ] Safety rules present
- [ ] Caption, 5 hashtags, pinned comment parsed

### 8. Save and Reopen
- Tap "Save" or let auto-save complete
- Navigate away from the screen
- Return to Content Library → find the saved project
- Reopen and verify all 3 parts persist with edited narrative

## Expected API Behavior

| Scenario | Expected App Behavior |
|----------|----------------------|
| Success (200) | Bottom sheet with 3 parts |
| 429 Rate Limit | "Rate limited — switching to next model..." then try next model |
| 400 Bad Request | "Model rejected request — switching..." then try next model |
| 404 Not Found | "Switching to next model..." then try next model |
| 503 Overloaded | "Model overloaded — switching..." then try next model |
| Daily Limit Exhausted | Clear error: "Gemini is overloaded..." / "Gemini busy..." |
| Invalid/Placeholder Key | Clear error: "Gemini API key not configured..." |

## Verification Checklist

- [ ] App builds without errors (`flutter analyze` clean)
- [ ] App runs on Android device/emulator
- [ ] Content Library loads idea_16 correctly
- [ ] StoryScreen loads original story
- [ ] Story edit accepts and displays "LIVE ANDROID GEMINI TEST"
- [ ] Generate Video button navigates to GeminiVideoScreen
- [ ] Generation completes with 3 parts
- [ ] Edited narrative appears in all 3 parts
- [ ] Original narrative does NOT replace edited narrative
- [ ] Character consistency: Cuty and Mumma descriptions match
- [ ] Scene continuity: Part 2 continues from Part 1, Part 3 from Part 2
- [ ] 9:16, 30-second, 3D Pixar style requirements present
- [ ] Safety rules present
- [ ] Caption, 5 hashtags, pinned comment present
- [ ] Save completes without error
- [ ] Reopen shows all 3 parts with edited narrative intact

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| "Gemini API key not configured" | Add key to lib/secrets.dart or Settings screen |
| "All models exhausted" | Wait for quota reset (20 req/day per model) or use paid key |
| Build fails | Run `flutter clean && flutter pub get && flutter build apk --debug` |
| App crashes on launch | Check logcat for missing permissions or config |