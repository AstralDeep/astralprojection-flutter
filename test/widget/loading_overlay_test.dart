import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/common/loading_overlay.dart';

void main() {
  testWidgets('renders spinner and loading message text', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LoadingOverlay(),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // First message in rotation is 'Loading...'
    expect(find.text('Loading...'), findsOneWidget);
  });
}
