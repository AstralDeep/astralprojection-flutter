import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/button_widget.dart';

void main() {
  void noOpSendEvent(String action, Map<String, dynamic> payload) {}

  Widget buildWidget(Map<String, dynamic> component,
      {void Function(String, Map<String, dynamic>)? sendEvent}) {
    return MaterialApp(
      home: Scaffold(
        body: ButtonWidget(
          component: component,
          sendEvent: sendEvent ?? noOpSendEvent,
        ),
      ),
    );
  }

  testWidgets('renders label', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'button',
      'label': 'Click Me',
      'action': 'test_action',
    }));
    expect(find.text('Click Me'), findsOneWidget);
  });

  testWidgets('renders primary variant as ElevatedButton', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'button',
      'label': 'Primary',
      'action': 'test',
      'variant': 'primary',
    }));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('renders secondary variant as OutlinedButton', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'button',
      'label': 'Secondary',
      'action': 'test',
      'variant': 'secondary',
    }));
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('calls sendEvent on tap', (tester) async {
    String? capturedAction;
    Map<String, dynamic>? capturedPayload;

    await tester.pumpWidget(buildWidget(
      {
        'type': 'button',
        'label': 'Submit',
        'action': 'do_submit',
        'payload': {'key': 'value'},
      },
      sendEvent: (action, payload) {
        capturedAction = action;
        capturedPayload = payload;
      },
    ));

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(capturedAction, 'do_submit');
    expect(capturedPayload, containsPair('key', 'value'));
  });
}
