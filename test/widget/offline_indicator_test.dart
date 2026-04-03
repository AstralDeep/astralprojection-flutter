import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/common/offline_indicator.dart';

void main() {
  testWidgets('renders connection lost text', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [OfflineIndicator()],
        ),
      ),
    ));

    expect(
      find.text('Connection lost \u2014 reconnecting...'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
