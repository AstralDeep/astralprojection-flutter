import 'package:flutter/material.dart';
import '../dynamic_renderer.dart';

class CardWidget extends StatefulWidget {
  final Map<String, dynamic> primitive;
  final void Function(Map<String, dynamic>)? sendAction;

  const CardWidget({
    required this.primitive,
    this.sendAction,
    super.key,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final oldChildren = oldWidget.primitive['children'] as List?;
    final newChildren = widget.primitive['children'] as List?;

    // If a child was added, scroll to the bottom.
    if ((newChildren?.length ?? 0) > (oldChildren?.length ?? 0)) {
      // Schedule the scroll to happen after the new frame is rendered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.primitive['config'] as Map<String, dynamic>? ?? {};
    final children = widget.primitive['children'] as List<dynamic>? ?? [];

    // --- Style Parsing ---
    final width = _parseDouble(config['width']);
    final height = _parseDouble(config['height']);

    final decoration = BoxDecoration(
      color: _parseColor(config['backgroundColor'], defaultValue: Colors.white),
      border: _parseBorder(config['border']),
      borderRadius: _parseBorderRadius(config['borderRadius']),
      boxShadow: _parseBoxShadows(config['boxShadow']),
    );

    return Container(
      width: width,
      height: height,
      padding: _parseEdgeInsets(config['padding'], defaultValue: const EdgeInsets.all(16.0)),
      margin: _parseEdgeInsets(config['margin']),
      decoration: decoration,
      child: ListView.builder(
        controller: _scrollController,
        // The key is important for Flutter to properly handle state when the list changes
        key: ValueKey(widget.primitive['id']),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final childPrimitive = children[index] as Map<String, dynamic>? ?? {};
          if (childPrimitive.isEmpty) {
            return const SizedBox.shrink(); // Return empty space for invalid child
          }
          return DynamicRenderer(
            key: ValueKey(childPrimitive['id'] ?? 'child_$index'),
            primitive: childPrimitive,
            sendAction: widget.sendAction,
          );
        },
      ),
    );
  }
}


// --- CSS Style Parsing Helpers ---

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  }
  return null;
}

EdgeInsets? _parseEdgeInsets(dynamic value, {EdgeInsets? defaultValue}) {
  final doubleValue = _parseDouble(value);
  return doubleValue != null ? EdgeInsets.all(doubleValue) : defaultValue;
}

Border? _parseBorder(String? value) {
  if (value == null || value.toLowerCase() == 'none') return null;
  final parts = value.split(' ').where((s) => s.isNotEmpty).toList();
  if (parts.length < 3) return Border.all(); // Default fallback

  final width = _parseDouble(parts[0]) ?? 1.0;
  // parts[1] is 'solid', 'dotted', etc. We only support solid for now.
  final color = _parseColor(parts[2], defaultValue: Colors.black);

  return Border.all(color: color, width: width);
}

BorderRadius? _parseBorderRadius(dynamic value) {
  final doubleValue = _parseDouble(value);
  return doubleValue != null ? BorderRadius.circular(doubleValue) : null;
}

Color _parseColor(String? value, {required Color defaultValue}) {
  if (value == null) return defaultValue;

  String hex = value.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length == 3) {
    hex = hex.split('').map((c) => c + c).join('');
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length == 8) {
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue != null) {
      return Color(intValue);
    }
  }
  // Basic color name support
  switch (value.toLowerCase()) {
      case 'white': return Colors.white;
      case 'black': return Colors.black;
      case 'transparent': return Colors.transparent;
      // Add more as needed
  }
  return defaultValue;
}

List<BoxShadow>? _parseBoxShadows(String? value) {
  if (value == null || value.toLowerCase() == 'none') return null;

  // This is a simplified parser for a single shadow.
  // Example: '0 1px 3px rgba(0,0,0,0.1)'
  final parts = value.split(RegExp(r'\s+(?![^(]*\))')); // Split by space, but not inside parentheses
  try {
    final offsetX = _parseDouble(parts[0]) ?? 0;
    final offsetY = _parseDouble(parts[1]) ?? 0;
    final blurRadius = _parseDouble(parts[2]) ?? 0;
    final spreadRadius = parts.length > 4 ? (_parseDouble(parts[3]) ?? 0.0) : 0.0;
    final colorString = parts.last;
    
    Color color = Colors.black.withValues(alpha: 0.2); // Default
    if (colorString.toLowerCase().startsWith('rgba')) {
      final rgbaParts = colorString.replaceAll(RegExp(r'rgba\(|\)'), '').split(',');
      final r = int.parse(rgbaParts[0]);
      final g = int.parse(rgbaParts[1]);
      final b = int.parse(rgbaParts[2]);
      final a = double.parse(rgbaParts[3]);
      color = Color.fromRGBO(r, g, b, a);
    } else {
      color = _parseColor(colorString, defaultValue: Colors.black.withValues(alpha: 0.2));
    }
    
    return [
      BoxShadow(
        color: color,
        offset: Offset(offsetX, offsetY),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      )
    ];
  } catch (e) {
    return null; // Return null if parsing fails
  }
}