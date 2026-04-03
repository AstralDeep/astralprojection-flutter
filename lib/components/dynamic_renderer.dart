import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/web_socket_provider.dart';
import 'common/placeholder_widget.dart';

// Primitive widget imports
import 'primitives/container_widget.dart';
import 'primitives/text_widget.dart';
import 'primitives/button_widget.dart';
import 'primitives/input_widget.dart';
import 'primitives/card_widget.dart';
import 'primitives/table_widget.dart';
import 'primitives/list_widget.dart';
import 'primitives/alert_widget.dart';
import 'primitives/progress_widget.dart';
import 'primitives/metric_widget.dart';
import 'primitives/code_widget.dart';
import 'primitives/image_widget.dart';
import 'primitives/grid_widget.dart';
import 'primitives/tabs_widget.dart';
import 'primitives/divider_widget.dart';
import 'primitives/collapsible_widget.dart';
import 'primitives/bar_chart_widget.dart';
import 'primitives/line_chart_widget.dart';
import 'primitives/pie_chart_widget.dart';
import 'primitives/plotly_chart_widget.dart';
import 'primitives/color_picker_widget.dart';
import 'primitives/file_upload_widget.dart';
import 'primitives/file_download_widget.dart';

/// Maps AstralBody backend snake_case component types to Flutter widget builders.
///
/// Each builder receives the raw component Map from the backend and a sendEvent
/// callback for dispatching ui_event messages.
typedef PrimitiveBuilder = Widget Function(
  Map<String, dynamic> component,
  void Function(String action, Map<String, dynamic> payload) sendEvent,
);

final Map<String, PrimitiveBuilder> primitiveMap = {
  'container': (c, s) => ContainerWidget(component: c, sendEvent: s),
  'text': (c, s) => TextWidget(component: c),
  'button': (c, s) => ButtonWidget(component: c, sendEvent: s),
  'input': (c, s) => InputWidget(component: c, sendEvent: s),
  'card': (c, s) => CardWidget(component: c, sendEvent: s),
  'table': (c, s) => TableWidget(component: c, sendEvent: s),
  'list': (c, s) => ListWidget(component: c),
  'alert': (c, s) => AlertWidget(component: c),
  'progress': (c, s) => ProgressWidget(component: c),
  'metric': (c, s) => MetricWidget(component: c),
  'code': (c, s) => CodeWidget(component: c),
  'image': (c, s) => ImageWidget(component: c),
  'grid': (c, s) => GridWidget(component: c, sendEvent: s),
  'tabs': (c, s) => TabsWidget(component: c, sendEvent: s),
  'divider': (c, s) => DividerWidget(component: c),
  'collapsible': (c, s) => CollapsibleWidget(component: c, sendEvent: s),
  'bar_chart': (c, s) => BarChartWidget(component: c),
  'line_chart': (c, s) => LineChartWidget(component: c),
  'pie_chart': (c, s) => PieChartWidget(component: c),
  'plotly_chart': (c, s) => PlotlyChartWidget(component: c),
  'color_picker': (c, s) => ColorPickerWidget(component: c, sendEvent: s),
  'file_upload': (c, s) => FileUploadWidget(component: c, sendEvent: s),
  'file_download': (c, s) => FileDownloadWidget(component: c, sendEvent: s),
};

/// The list of all supported SDUI component types, sent in register_ui.
List<String> get supportedCapabilities => primitiveMap.keys.toList();

/// Recursively renders an SDUI component tree.
class DynamicRenderer extends StatelessWidget {
  final Map<String, dynamic> component;

  const DynamicRenderer({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final type = component['type'] as String? ?? '';
    final builder = primitiveMap[type];
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);

    if (builder != null) {
      return builder(component, wsProvider.sendEvent);
    }

    return PlaceholderWidget(
      componentType: type,
      componentId: component['id'] as String?,
    );
  }

  /// Render a list of component maps as a column of DynamicRenderers.
  static Widget renderChildren(List<dynamic> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1 && children.first is Map<String, dynamic>) {
      return DynamicRenderer(component: children.first as Map<String, dynamic>);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in children)
          if (child is Map<String, dynamic>) DynamicRenderer(component: child),
      ],
    );
  }
}
