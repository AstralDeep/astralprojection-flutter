import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Renders a pie chart using fl_chart.
///
/// Schema: { type: "pie_chart", title: "Market Share", labels: ["A","B","C"],
///   data: [45,30,25], colors: ["#4285f4","#34a853","#ea4335"] }
class PieChartWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const PieChartWidget({
    required this.component,
    super.key,
  });

  static const _defaultColors = [
    '#4285f4',
    '#34a853',
    '#ea4335',
    '#fbbc05',
    '#8e24aa',
    '#00acc1',
    '#ff7043',
  ];

  static Color _parseHex(String hex) {
    final buffer = hex.replaceFirst('#', '');
    final value = int.tryParse(buffer, radix: 16) ?? 0x4285F4;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final title = component['title']?.toString() ?? '';
    final labels = (component['labels'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final data = (component['data'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final colors = (component['colors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final sections = <PieChartSectionData>[];
    final total = data.fold<double>(0, (sum, v) => sum + v);

    for (var i = 0; i < data.length; i++) {
      final colorHex =
          i < colors.length ? colors[i] : _defaultColors[i % _defaultColors.length];
      final percentage = total > 0 ? (data[i] / total * 100) : 0.0;

      sections.add(PieChartSectionData(
        value: data[i],
        color: _parseHex(colorHex),
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 80,
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
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          if (labels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _parseHex(
                              i < colors.length
                                  ? colors[i]
                                  : _defaultColors[i % _defaultColors.length],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          labels[i],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
