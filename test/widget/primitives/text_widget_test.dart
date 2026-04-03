import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/text_widget.dart';

void main() {
  Widget buildWidget(Map<String, dynamic> component) {
    return MaterialApp(
      home: Scaffold(body: TextWidget(component: component)),
    );
  }

  testWidgets('renders text content', (tester) async {
    await tester.pumpWidget(buildWidget({'type': 'text', 'content': 'Hello World'}));
    expect(find.text('Hello World'), findsOneWidget);
  });

  testWidgets('renders h1 variant', (tester) async {
    await tester.pumpWidget(buildWidget({'type': 'text', 'content': 'Title', 'variant': 'h1'}));
    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('renders h2 variant', (tester) async {
    await tester.pumpWidget(buildWidget({'type': 'text', 'content': 'Subtitle', 'variant': 'h2'}));
    expect(find.text('Subtitle'), findsOneWidget);
  });

  testWidgets('renders h3 variant', (tester) async {
    await tester.pumpWidget(buildWidget({'type': 'text', 'content': 'Section', 'variant': 'h3'}));
    expect(find.text('Section'), findsOneWidget);
  });

  testWidgets('renders body variant', (tester) async {
    await tester.pumpWidget(buildWidget({'type': 'text', 'content': 'Body text', 'variant': 'body'}));
    expect(find.text('Body text'), findsOneWidget);
  });

  testWidgets('renders caption variant', (tester) async {
    await tester.pumpWidget(buildWidget({'type': 'text', 'content': 'Caption text', 'variant': 'caption'}));
    expect(find.text('Caption text'), findsOneWidget);
  });

  testWidgets('handles missing content gracefully', (tester) async {
    await tester.pumpWidget(buildWidget({'type': 'text'}));
    // Missing content defaults to empty string
    expect(find.text(''), findsOneWidget);
  });
}
