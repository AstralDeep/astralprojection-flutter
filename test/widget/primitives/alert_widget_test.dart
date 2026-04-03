import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/alert_widget.dart';

void main() {
  Widget buildWidget(Map<String, dynamic> component) {
    return MaterialApp(
      home: Scaffold(body: AlertWidget(component: component)),
    );
  }

  testWidgets('renders message', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'alert',
      'message': 'Something happened',
      'variant': 'info',
    }));
    expect(find.text('Something happened'), findsOneWidget);
  });

  testWidgets('renders info icon for info variant', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'alert',
      'message': 'Info message',
      'variant': 'info',
    }));
    expect(find.byIcon(Icons.info), findsOneWidget);
  });

  testWidgets('renders check_circle icon for success variant', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'alert',
      'message': 'Success message',
      'variant': 'success',
    }));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('renders warning icon for warning variant', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'alert',
      'message': 'Warning message',
      'variant': 'warning',
    }));
    expect(find.byIcon(Icons.warning), findsOneWidget);
  });

  testWidgets('renders error icon for error variant', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'alert',
      'message': 'Error message',
      'variant': 'error',
    }));
    expect(find.byIcon(Icons.error), findsOneWidget);
  });
}
