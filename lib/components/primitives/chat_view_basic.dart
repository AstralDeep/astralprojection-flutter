import 'package:flutter/material.dart';

// --- ChatViewBasic ---
class ChatViewBasicWidget extends StatelessWidget {
  final Map<String, dynamic> primitive;
  const ChatViewBasicWidget({required this.primitive, super.key});

  @override
  Widget build(BuildContext context) {
    final content = primitive['content'] as List<dynamic>? ?? [];
    final title = primitive['config']?['title']?.toString() ?? 'Chat';
    return Container(
      height: 300, 
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          Expanded(
            child: content.isEmpty
                ? const Center(child: Text("No messages."))
                : ListView.builder(
                    itemCount: content.length,
                    itemBuilder: (ctx, idx) {
                      final item = content[idx] as Map<String, dynamic>? ?? {};
                      return ListTile(
                        title: Text(item['text']?.toString() ?? ''),
                        subtitle: Text(item['role']?.toString() ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}