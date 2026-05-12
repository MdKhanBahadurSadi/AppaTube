import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appatube/app/app.dart';

void main() {
  testWidgets('Appatube basic test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppaTubeApp());

    // Verify that our app starts.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
