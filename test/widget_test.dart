import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beadot/app.dart';

void main() {
  testWidgets("BeadotApp builds a MaterialApp", (WidgetTester tester) async {
    await tester.pumpWidget(const BeadotApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
