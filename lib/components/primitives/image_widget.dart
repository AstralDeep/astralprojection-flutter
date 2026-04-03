import 'package:flutter/material.dart';

/// Renders a network image with optional size constraints.
///
/// Schema: { type: "image", url: "https://...", alt: "Description", width: "200px"?, height: "150px"? }
class ImageWidget extends StatelessWidget {
  final Map<String, dynamic> component;

  const ImageWidget({required this.component, super.key});

  /// Parses dimension strings like "200px", "150", or raw numbers to doubles.
  static double? _parseDimension(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;
      return double.tryParse(cleaned);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = component['url'] as String? ?? '';
    final alt = component['alt'] as String? ?? '';
    final width = _parseDimension(component['width']);
    final height = _parseDimension(component['height']);

    if (url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          width: width,
          height: height ?? 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
          ),
        ),
      );
    }

    return Semantics(
      image: true,
      label: alt.isNotEmpty ? alt : 'Image',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: alt.isNotEmpty ? alt : null,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height ?? 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.0,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height ?? 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                  if (alt.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        alt,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }
}
