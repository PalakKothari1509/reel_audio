import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/asset_completeness_service.dart';
import 'package:reel_audio/content_library.dart';
import 'package:reel_audio/dashboard_screen.dart';

void main() {
  testWidgets('debug dashboard', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('dbg');
    ContentLibraryStore.useDirectory(tempDir);
    addTearDown(() {
      ContentLibraryStore.resetDirectory();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pump(const Duration(seconds: 1));
    // Check whether the loading indicator is still shown.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 30));
    // If we got here, check what is rendered.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}