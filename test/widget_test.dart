import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gravity_rush/screens/game_flow_screen.dart';

void main() {
  testWidgets('GameFlow screen builds without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameFlowScreen()));
    await tester.pump();
  });
}
