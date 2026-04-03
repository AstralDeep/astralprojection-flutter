import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/input_widget.dart';

void main() {
  void noOpSendEvent(String action, Map<String, dynamic> payload) {}

  Widget buildWidget(Map<String, dynamic> component,
      {void Function(String, Map<String, dynamic>)? sendEvent}) {
    return MaterialApp(
      home: Scaffold(
        body: InputWidget(
          component: component,
          sendEvent: sendEvent ?? noOpSendEvent,
        ),
      ),
    );
  }

  testWidgets('renders placeholder', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'input',
      'placeholder': 'Enter text...',
      'name': 'field1',
    }));
    expect(find.text('Enter text...'), findsOneWidget);
  });

  testWidgets('sends form_submit event on submit', (tester) async {
    String? capturedAction;
    Map<String, dynamic>? capturedPayload;

    await tester.pumpWidget(buildWidget(
      {
        'type': 'input',
        'name': 'username',
        'placeholder': 'Enter username',
      },
      sendEvent: (action, payload) {
        capturedAction = action;
        capturedPayload = payload;
      },
    ));

    await tester.enterText(find.byType(TextField), 'testuser');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(capturedAction, 'form_submit');
    expect(capturedPayload, isNotNull);
    expect((capturedPayload!['fields'] as Map)['username'], 'testuser');
  });

  testWidgets('pre-fills value', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'input',
      'name': 'email',
      'value': 'test@example.com',
    }));

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, 'test@example.com');
  });
}
