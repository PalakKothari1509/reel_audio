# Background music

Drop royalty-free tracks here, then list them in two places:

1. `pubspec.yaml` under `flutter: assets:`
2. `kMusicLibrary` in `lib/music.dart`

## Normalise first — this is the important step

Every track must be levelled to the same loudness before it goes in, so one volume
setting works for all of them. Without this a loud track drowns the narration while a
quiet one disappears, and no single number suits both.

```bash
ffmpeg -i original.mp3 -af loudnorm=I=-23:TP=-2:LRA=7 -c:a libmp3lame -b:a 128k playful_1.mp3
```

Done once, here, rather than on every render.

## What to use

Royalty-free only — Pixabay Music, the YouTube Audio Library, Free Music Archive.
Check the licence allows commercial use and note where each track came from.

**Not trending audio from Reels.** Those are licensed recordings. Bake one into the
file and Instagram mutes the reel or takes it down. Trending audio is added in
Instagram when you post, where the licence already covers it.

## Suggested set

Four to six is plenty: two playful, two warm, one or two gentle. Aim for 30-60 seconds
each; anything shorter loops more often than it needs to.

Keep them small — every track ships inside the APK. At 128 kbps mono, a minute is
about 500 KB.
