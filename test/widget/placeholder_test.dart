import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/common/placeholder_widget.dart';

void main() {
  testWidgets('renders unknown component type name', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PlaceholderWidget(
          componentType: 'fancy_widget',
          componentId: 'test-123',
        ),
      ),
    ));

    expect(find.text('Unknown component: "fancy_widget"'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });
}
