import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// T044 - Renders a color picker with a preview box and label.
///
/// Schema: { type: "color_picker", label: "Pick a color",
///           color_key: "bg_color", value: "#000000" }
class ColorPickerWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const ColorPickerWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = _parseHex(widget.component['value']?.toString());
  }

  @override
  void didUpdateWidget(covariant ColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.component['value'] != widget.component['value']) {
      _currentColor = _parseHex(widget.component['value']?.toString());
    }
  }

  /// Parses a hex color string (e.g. "#FF5733" or "FF5733") into a [Color].
  /// Returns [Colors.black] when the input is null or malformed.
  static Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;

    var cleaned = hex.replaceFirst('#', '');

    // Support 6-char (RRGGBB) and 8-char (AARRGGBB) hex strings.
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return Colors.black;

    return Color(value);
  }

  /// Converts a [Color] to a 6-character hex string prefixed with '#'.
  static String _toHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  Future<void> _showPickerDialog() async {
    Color pickedColor = _currentColor;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            widget.component['label']?.toString() ?? 'Pick a color',
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (color) => pickedColor = color,
              enableAlpha: false,
              hexInputBar: true,
              labelTypes: const [],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _currentColor = pickedColor);

      final colorKey =
          widget.component['color_key']?.toString() ?? 'color';

      widget.sendEvent('form_submit', {
        'fields': {colorKey: _toHex(pickedColor)},
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.component['label']?.toString() ?? 'Pick a color';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: _showPickerDialog,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
