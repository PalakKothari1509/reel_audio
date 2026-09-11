# Character faces

Put a reference picture of each character here and it ships inside the app — the cast
has faces from the moment it is installed, with nothing to set up, and they survive a
reinstall or a new phone. A face picked from the gallery still overrides the bundled
one, so any of them can be changed without a new build.

## Adding one

1. Save the picture here named exactly as the character is named in kDefaultCast: `Ria.jpg`, `Rio.jpg`,
   `Cuty.jpg`, `Mumma.jpg`, `Papa.jpg`, `Daadi.jpg`, `Teacher.jpg`
2. List it in `pubspec.yaml` under `flutter: assets:`
3. Set `assetPath` on that character in `kDefaultCast` in `lib/characters.dart`:

```dart
CharacterRef(
  name: 'Ria',
  description: '...',
  assetPath: 'assets/characters/Ria.jpg',
),
```

All three steps are needed. A file listed in pubspec but not referenced in
`kDefaultCast` is dead weight in the APK; one referenced but not listed in pubspec
fails at runtime, not at build time.

## What makes a good reference

- **One character alone**, face clearly visible, looking towards the camera
- **Plain background** — a busy one gets copied into the generated pictures
- **Square-ish**, around 512x512. Bigger is wasted; every file ships in the APK
- **PNG or JPG.** PNG for anything with transparency
- The style you want the reels to have — the generator copies the reference, so a
  rough sketch gives rough results

## Why both a picture and a description

The description in `kDefaultCast` keeps the clothes, hair and colours the same, because
the exact same wording goes into every prompt. The picture keeps the *face* the same,
which words never manage: describe "toddler girl with pigtails" ten times and you get
ten different children. Neither alone is enough.
