import 'package:flutter/material.dart';

// --- LogView ---
class LogViewWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const LogViewWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'];
    final config = primitive['config'] as Map<String, dynamic>? ?? {};
    final styleConfig = config['style'] as Map<String, dynamic>? ?? {};
    
    final height = styleConfig['height'] != null
        ? double.tryParse(styleConfig['height'].toString().replaceAll('px', ''))
        : null;
    final title = config['title']?.toString() ?? "Logs";

    double marginTopValue = 8.0; 
    if (styleConfig['marginTop'] != null) {
      // Ensure robust parsing for marginTopValue
      String marginTopString = styleConfig['marginTop'].toString();
      if (marginTopString.endsWith('px')) {
        marginTopString = marginTopString.substring(0, marginTopString.length - 2);
      }
      marginTopValue = double.tryParse(marginTopString) ?? 8.0;
    }

    List<dynamic> entries = [];
    if (content is List) {
      entries = content;
    } else if (content != null) {
      entries = [content];
    }

    Widget logListContent;
    if (entries.isEmpty) {
      logListContent = Center(
          child: Text('No log entries.',
              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)));
    } else {
      logListContent = ListView.builder(
        shrinkWrap: height == null,
        physics: height == null ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, idx) {
          final entry = entries[idx];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              entry.toString(),
              style: const TextStyle(
                  color: Colors.black87, fontFamily: 'monospace', fontSize: 13),
            ),
          );
        },
      );
    }

    Widget logContainer = Container(
      margin: EdgeInsets.symmetric(vertical: marginTopValue), // Use the parsed marginTopValue
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(height: 16),
          Expanded( // <<<<<<<<<<<<<<<< CORRECTED HERE
            child: logListContent,
          ),
        ],
      )
    );
    
     if (height != null) {
       return SizedBox(height: height, child: logContainer); // Constrain the whole widget if height is specified
     } else {
       return logContainer;
     }
  }
}