import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reel_audio/insights_screen.dart';

void main() {
  group('InsightsScreen', () {
    testWidgets('shows App Bar, loading indicator, and refresh button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InsightsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Insights'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Refresh'), findsOneWidget);
    });
  });
}
