import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

// ── Background music ──────────────────────────────────────────────────────────
//
// Tracks are bundled in the app, not picked from the phone each time: the whole
// render already works offline, and licensing is then one decision made once rather
// than something to get right per reel.
//
// Deliberately NOT the trending audio you hear on Reels. Those are licensed
// recordings — bake one into the file and Instagram mutes the reel, or worse. Real
// trending audio is added in Instagram when you post, where the licence already
// exists. What ships here is royalty-free bed music that can safely live in the file.

/// One bundled track. `asset` is the path inside pubspec's assets list.
class MusicTrack {
  final String name;
  final String mood;
  final String asset;

  const MusicTrack({required this.name, required this.mood, required this.asset});
}

/// The library. Add a file to assets/music/, list it in pubspec.yaml, add it here.
///
/// Empty until tracks are added — the app treats "no music" as a normal state rather
/// than an error, so it works fine with none.
const kMusicLibrary = <MusicTrack>[
  // MusicTrack(name: 'Sunny Day',  mood: 'Playful', asset: 'assets/music/playful_1.mp3'),
  // MusicTrack(name: 'Warm Hug',   mood: 'Warm',    asset: 'assets/music/warm_1.mp3'),
  // MusicTrack(name: 'Soft Light', mood: 'Gentle',  asset: 'assets/music/gentle_1.mp3'),
];

bool get hasMusic => kMusicLibrary.isNotEmpty;

/// Copies a bundled track out to a real file, because FFmpeg needs a path on disk
/// and an asset only exists inside the APK.
///
/// Cached by name: the same track in ten reels is unpacked once.
Future<String> unpackTrack(MusicTrack track, String workDir) async {
  final target = '$workDir/music_${track.asset.split('/').last}';
  final file = File(target);
  if (await file.exists() && await file.length() > 0) return target;

  final data = await rootBundle.load(track.asset);
  await file.writeAsBytes(data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  ));
  return target;
}

// ── Levels ────────────────────────────────────────────────────────────────────

/// How loud the music sits under the narration.
///
/// Fixed rather than ducked on purpose. Ducking earns its keep when music needs to
/// swell in the gaps, and a 30 second reel with near-continuous narration barely has
/// any. Mis-tuned ducking also pumps — the music breathing around every word — which
/// is far more noticeable on a short reel than music that is simply a bit quiet.
const double kMusicGain = 0.15;

/// Target loudness for the one-off normalise pass, in LUFS.
///
/// Every track is levelled to this when it is added, so one gain works for all of
/// them. Without it a loud track steps on the voice while a quiet one vanishes, and
/// no single number suits both.
const String kNormaliseFilter = 'loudnorm=I=-23:TP=-2:LRA=7';
