import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/metric_widget.dart';

void main() {
  Widget buildWidget(Map<String, dynamic> component) {
    return MaterialApp(
      home: Scaffold(body: MetricWidget(component: component)),
    );
  }

  testWidgets('renders title and value', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'metric',
      'title': 'Revenue',
      'value': '\$1.2M',
    }));
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('\$1.2M'), findsOneWidget);
  });

  testWidgets('renders optional subtitle', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'metric',
      'title': 'Revenue',
      'value': '\$1.2M',
      'subtitle': 'Q4 2025',
    }));
    expect(find.text('Q4 2025'), findsOneWidget);
  });

  testWidgets('renders optional progress bar', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'metric',
      'title': 'Goal',
      'value': '80%',
      'progress': 0.8,
    }));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
