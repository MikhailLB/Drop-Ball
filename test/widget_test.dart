import 'package:flutter_test/flutter_test.dart';
import 'package:gravity_rush/app.dart';

void main() {
  testWidgets('App loads without error', (WidgetTester tester) async {
    await tester.pumpWidget(const GravityRushApp());
    await tester.pump();
  });
}
