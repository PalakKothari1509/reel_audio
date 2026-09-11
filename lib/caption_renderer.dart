import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'video_builder.dart';

// ── Captions ──────────────────────────────────────────────────────────────────
//
// Each caption is drawn by Flutter and saved as a transparent PNG, which FFmpeg then
// lays over the clip.
//
// Not FFmpeg's own drawtext, and the reason matters: drawtext does no complex-script
// shaping unless the build happens to include HarfBuzz. Devanagari needs it — without
// it conjuncts and matras land in the wrong places and "क्यूटी" comes out mangled.
// A caption feature that breaks in the one language it is for is worse than none.
//
// Flutter shapes Devanagari correctly already, and drawing it here also means the
// styling is ordinary Flutter code rather than escaped filter strings.

/// White rounded box with a black border, the style the reels already use.
class CaptionStyle {
  /// Share of the frame width the caption may fill.
  static const double widthFraction = 0.86;
  static const double fontSize = 54;
  static const double borderWidth = 5;
  static const double cornerRadius = 26;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 34, vertical: 22);
  // Where it sits on screen is kCaptionFromTop in video_builder.dart — the overlay
  // filter is what actually places it, so the number lives with the filter.
}

/// Draws one caption and returns the PNG path, or null when there's nothing to draw.
Future<String?> renderCaptionPng({
  required String text,
  required String outPath,
}) async {
  final caption = text.trim();
  if (caption.isEmpty) return null;

  final maxTextWidth = kVideoWidth * CaptionStyle.widthFraction -
      CaptionStyle.padding.horizontal;

  final painter = TextPainter(
    text: TextSpan(
      text: caption,
      style: const TextStyle(
        color: Colors.black,
        fontSize: CaptionStyle.fontSize,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 3,
    ellipsis: '…',
  )..layout(maxWidth: maxTextWidth);

  final boxWidth = painter.width + CaptionStyle.padding.horizontal;
  final boxHeight = painter.height + CaptionStyle.padding.vertical;

  // Half the border sits outside the rounded rectangle, so leave room or it clips.
  final pad = CaptionStyle.borderWidth;
  final imageWidth = (boxWidth + pad * 2).ceil();
  final imageHeight = (boxHeight + pad * 2).ceil();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final box = RRect.fromRectAndRadius(
    Rect.fromLTWH(pad, pad, boxWidth, boxHeight),
    const Radius.circular(CaptionStyle.cornerRadius),
  );

  canvas.drawRRect(box, Paint()..color = Colors.white);
  canvas.drawRRect(
    box,
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = CaptionStyle.borderWidth,
  );

  painter.paint(
    canvas,
    Offset(pad + CaptionStyle.padding.left, pad + CaptionStyle.padding.top),
  );

  final image = await recorder.endRecording().toImage(imageWidth, imageHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) return null;

  final file = File(outPath);
  if (await file.exists()) await file.delete();
  await file.writeAsBytes(bytes.buffer.asUint8List());
  return outPath;
}

/// Draws one caption per script line and returns their paths, nulls included so the
/// list still lines up with the lines.
Future<List<String?>> renderCaptions({
  required List<String> lines,
  required String workDir,
}) async {
  final paths = <String?>[];
  for (var i = 0; i < lines.length; i++) {
    paths.add(await renderCaptionPng(
      text: lines[i],
      outPath: '$workDir/caption_$i.png',
    ));
  }
  return paths;
}
