import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:astral/components/primitives/card_widget.dart';
import 'package:astral/state/web_socket_provider.dart';

void main() {
  void noOpSendEvent(String action, Map<String, dynamic> payload) {}

  Widget buildWidget(Map<String, dynamic> component) {
    return MaterialApp(
      home: Scaffold(
        body: CardWidget(
          component: component,
          sendEvent: noOpSendEvent,
        ),
      ),
    );
  }

  testWidgets('renders title', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'card',
      'title': 'My Card',
      'content': [],
    }));
    expect(find.text('My Card'), findsOneWidget);
  });

  testWidgets('renders with content children via DynamicRenderer', (tester) async {
    // DynamicRenderer requires a WebSocketProvider in the tree.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WebSocketProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: CardWidget(
              component: {
                'type': 'card',
                'title': 'Card Title',
                'content': [
                  {'type': 'text', 'content': 'Child text'},
                ],
              },
              sendEvent: noOpSendEvent,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Card Title'), findsOneWidget);
    expect(find.text('Child text'), findsOneWidget);
  });
}
