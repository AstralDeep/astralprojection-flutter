import 'package:flutter/material.dart';

// --- HtmlView ---
class HtmlViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const HtmlViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'];
    String textContent = "HTML content (rendering not fully implemented)";
    if (content is Map && content.containsKey('viz_type')) {
       final vizType = content['viz_type'];
       final vizContent = content['content'];
      if (vizType == 'table' && vizContent is Map) {
        final columnsData = vizContent['columns'] as List<dynamic>? ?? [];
        final rowsData = vizContent['rows'] as List<dynamic>? ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columnsData.map((c) => DataColumn(label: Text(c.toString()))).toList(),
            rows: rowsData.map((row) {
              final cells = row as List<dynamic>? ?? [];
              return DataRow(cells: cells.map((cell) => DataCell(Text(cell?.toString() ?? ''))).toList());
            }).toList(),
          ),
        );
      }
      textContent = vizContent?.toString() ?? 'Unsupported HTML viz type';
    } else {
        textContent = content?.toString() ?? 'Invalid HTML content';
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(textContent),
    );
  }
}