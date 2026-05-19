import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bounce_ball_two/screens/preload_screen.dart';

void main() {
  testWidgets('PreloadScreen builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PreloadScreen(onReady: () {})),
    );
    await tester.pump();
  });
}
