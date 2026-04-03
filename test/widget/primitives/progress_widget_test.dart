import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/progress_widget.dart';

void main() {
  Widget buildWidget(Map<String, dynamic> component) {
    return MaterialApp(
      home: Scaffold(body: ProgressWidget(component: component)),
    );
  }

  testWidgets('renders progress bar', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'progress',
      'value': 0.5,
    }));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('displays percentage', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'progress',
      'value': 0.75,
      'show_percentage': true,
    }));
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('renders label', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'progress',
      'value': 0.3,
      'label': 'Uploading...',
    }));
    expect(find.text('Uploading...'), findsOneWidget);
  });
}
