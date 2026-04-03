import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/table_widget.dart';

void main() {
  void noOpSendEvent(String action, Map<String, dynamic> payload) {}

  Widget buildWidget(Map<String, dynamic> component) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TableWidget(
            component: component,
            sendEvent: noOpSendEvent,
          ),
        ),
      ),
    );
  }

  testWidgets('renders headers and rows', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'table',
      'headers': ['Name', 'Age'],
      'rows': [
        ['Alice', '30'],
        ['Bob', '25'],
      ],
    }));

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('pagination controls appear when total_rows is set', (tester) async {
    await tester.pumpWidget(buildWidget({
      'type': 'table',
      'headers': ['Col1'],
      'rows': [
        ['Row1'],
      ],
      'total_rows': 100,
      'page_size': 10,
      'page_offset': 0,
    }));

    expect(find.text('Rows per page: '), findsOneWidget);
    expect(find.byIcon(Icons.first_page), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.last_page), findsOneWidget);
  });
}
