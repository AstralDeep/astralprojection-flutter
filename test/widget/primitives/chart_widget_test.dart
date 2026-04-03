import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/bar_chart_widget.dart';
import 'package:astral/components/primitives/line_chart_widget.dart';
import 'package:astral/components/primitives/pie_chart_widget.dart';
import 'package:astral/components/primitives/plotly_chart_widget.dart';

void main() {
  group('BarChartWidget', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BarChartWidget(component: {
            'type': 'bar_chart',
            'title': 'Monthly Sales',
            'labels': ['Jan', 'Feb'],
            'datasets': [
              {'label': '2025', 'data': [100, 200], 'color': '#4285f4'},
            ],
          }),
        ),
      ));
      expect(find.text('Monthly Sales'), findsOneWidget);
    });

    testWidgets('renders without errors given valid data', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BarChartWidget(component: {
            'type': 'bar_chart',
            'title': 'Test',
            'labels': ['A', 'B', 'C'],
            'datasets': [
              {'label': 'Set1', 'data': [10, 20, 30], 'color': '#ff0000'},
            ],
          }),
        ),
      ));
      expect(find.byType(BarChart), findsOneWidget);
    });
  });

  group('LineChartWidget', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LineChartWidget(component: {
            'type': 'line_chart',
            'title': 'Growth',
            'labels': ['Q1', 'Q2'],
            'datasets': [
              {'label': 'Revenue', 'data': [10, 25], 'color': '#34a853'},
            ],
          }),
        ),
      ));
      expect(find.text('Growth'), findsOneWidget);
    });

    testWidgets('renders without errors given valid data', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LineChartWidget(component: {
            'type': 'line_chart',
            'title': 'Test',
            'labels': ['A', 'B'],
            'datasets': [
              {'label': 'Set1', 'data': [5, 15], 'color': '#00ff00'},
            ],
          }),
        ),
      ));
      expect(find.byType(LineChart), findsOneWidget);
    });
  });

  group('PieChartWidget', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PieChartWidget(component: {
            'type': 'pie_chart',
            'title': 'Market Share',
            'labels': ['A', 'B'],
            'data': [60, 40],
            'colors': ['#4285f4', '#ea4335'],
          }),
        ),
      ));
      expect(find.text('Market Share'), findsOneWidget);
    });

    testWidgets('renders without errors given valid data', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PieChartWidget(component: {
            'type': 'pie_chart',
            'title': 'Test',
            'labels': ['X', 'Y', 'Z'],
            'data': [30, 40, 30],
          }),
        ),
      ));
      expect(find.byType(PieChart), findsOneWidget);
    });
  });

  group('PlotlyChartWidget', () {
    testWidgets('shows placeholder message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PlotlyChartWidget(component: {
            'type': 'plotly_chart',
            'title': 'Complex Viz',
            'data': [
              {'type': 'scatter', 'x': [1, 2], 'y': [3, 4]},
            ],
          }),
        ),
      ));
      expect(find.text('Complex Viz'), findsOneWidget);
      expect(find.text('Plotly chart \u2013 view in browser'), findsOneWidget);
    });
  });
}
