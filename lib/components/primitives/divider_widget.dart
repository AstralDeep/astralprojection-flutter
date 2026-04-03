import 'package:flutter/material.dart';

/// Renders a horizontal divider with vertical margin.
///
/// Schema: { type: "divider", variant: "solid" }
class DividerWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const DividerWidget({required this.component, super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        height: 1.0,
        thickness: 1.0,
      ),
    );
  }
}
