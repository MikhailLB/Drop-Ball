import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gravity_rush/screens/flow_screen.dart';

void main() {
  testWidgets('FlowScreen builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FlowScreen()));
    await tester.pump();
  });
}
