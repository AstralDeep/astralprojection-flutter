import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/device_profile_provider.dart';
import '../../platform/tv/tv_theme.dart';
import '../dynamic_renderer.dart';

/// Renders a tabbed interface with content driven by the SDUI schema.
///
/// Schema: { type: "tabs", variant: "default", tabs: [{ label: "Tab Name", value: "tab_id"?, content: [Component[]] }] }
class TabsWidget extends StatefulWidget {
  final Map<String, dynamic> component;
  final void Function(String action, Map<String, dynamic> payload) sendEvent;

  const TabsWidget({
    required this.component,
    required this.sendEvent,
    super.key,
  });

  @override
  State<TabsWidget> createState() => _TabsWidgetState();
}

class _TabsWidgetState extends State<TabsWidget> with TickerProviderStateMixin {
  late TabController _tabController;
  late List<dynamic> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = widget.component['tabs'] as List<dynamic>? ?? [];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant TabsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTabs = widget.component['tabs'] as List<dynamic>? ?? [];
    if (newTabs.length != _tabs.length) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabs = newTabs;
      _tabController = TabController(length: _tabs.length, vsync: this);
      _tabController.addListener(_onTabChanged);
    } else {
      _tabs = newTabs;
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index >= 0 && index < _tabs.length) {
      final tab = _tabs[index] as Map<String, dynamic>? ?? {};
      final value = tab['value'] as String? ?? tab['label'] as String? ?? '';
      widget.sendEvent('tab_changed', {
        'id': widget.component['id'] ?? '',
        'value': value,
        'index': index,
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Wraps [child] with a Focus widget that shows a highlight border on TV.
  Widget _buildFocusWrapper(BuildContext context, Widget child) {
    final dp = Provider.of<DeviceProfileProvider>(context, listen: false);
    if (dp.deviceType != 'tv') return child;

    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            decoration: hasFocus
                ? BoxDecoration(
                    border: Border.all(
                      color: TvTheme.focusBorderColor,
                      width: TvTheme.focusBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  )
                : null,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: _tabs.length > 4,
      tabs: [
        for (final tab in _tabs)
          Tab(
            text: (tab is Map<String, dynamic>)
                ? (tab['label'] as String? ?? '')
                : '',
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFocusWrapper(context, tabBar),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final tab in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: SingleChildScrollView(
                      child: _buildTabContent(tab),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(dynamic tab) {
    if (tab is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }
    final content = tab['content'] as List<dynamic>? ?? [];
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }
    return DynamicRenderer.renderChildren(content);
  }
}
