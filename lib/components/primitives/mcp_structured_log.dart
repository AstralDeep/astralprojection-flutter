import 'package:flutter/material.dart';

// --- McpStructuredLogView ---
class McpStructuredLogViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const McpStructuredLogViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] as List<dynamic>? ?? [];
    return Container(
      height: 200, 
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey)),
      child: content.isEmpty
          ? const Text("No structured logs.")
          : ListView.builder(
              itemCount: content.length,
              itemBuilder: (context, index) => Text(content[index].toString()),
            ),
    );
  }
}