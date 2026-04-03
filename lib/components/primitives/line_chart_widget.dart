import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Renders a line chart using fl_chart.
///
/// Schema: { type: "line_chart", title: "Growth", labels: ["Q1","Q2"],
///   datasets: [{ label: "Revenue", data: [10,25], color: "#34a853" }] }
class LineChartWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const LineChartWidget({
    required this.component,
    super.key,
  });

  static Color _parseHex(String hex) {
    final buffer = hex.replaceFirst('#', '');
    final value = int.tryParse(buffer, radix: 16) ?? 0x34A853;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final title = component['title']?.toString() ?? '';
    final labels = (component['labels'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final datasets = component['datasets'] as List<dynamic>? ?? [];

    final lineBars = <LineChartBarData>[];
    for (final ds in datasets) {
      final dsMap = ds as Map<String, dynamic>;
      final data = dsMap['data'] as List<dynamic>? ?? [];
      final colorHex = dsMap['color']?.toString() ?? '#34a853';
      final color = _parseHex(colorHex);

      final spots = <FlSpot>[];
      for (var i = 0; i < data.length; i++) {
        spots.add(FlSpot(i.toDouble(), (data[i] as num).toDouble()));
      }

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.15),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: lineBars,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 ||
                            idx >= labels.length ||
                            value != idx.toDouble()) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          if (datasets.length > 1) _buildLegend(datasets),
        ],
      ),
    );
  }

  Widget _buildLegend(List<dynamic> datasets) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        children: [
          for (final ds in datasets)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseHex(
                      (ds as Map<String, dynamic>)['color']?.toString() ??
                          '#34a853',
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  ds['label']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
