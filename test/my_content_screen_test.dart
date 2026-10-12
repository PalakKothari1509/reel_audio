import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/my_content_screen.dart';

void main() {
  group('MyContentScreen', () {
    testWidgets('shows App Bar, loading indicator, and refresh button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyContentScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('My Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Refresh'), findsOneWidget);
    });
  });
}
