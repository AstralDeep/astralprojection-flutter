import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/list_widget.dart';

void main() {
  Widget buildWidget(Map<String, dynamic> component) {
    return MaterialApp(
      home: Scaffold(body: ListWidget(component: component)),
    );
  }

  testWidgets('renders unordered list with bullet prefixes', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'list',
      'items': ['Apple', 'Banana'],
      'ordered': false,
    }));

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    // Bullet character \u2022
    expect(find.text('\u2022 '), findsNWidgets(2));
  });

  testWidgets('renders ordered list with number prefixes', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'list',
      'items': ['First', 'Second'],
      'ordered': true,
    }));

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('1. '), findsOneWidget);
    expect(find.text('2. '), findsOneWidget);
  });
}
