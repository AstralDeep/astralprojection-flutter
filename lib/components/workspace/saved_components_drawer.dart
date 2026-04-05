import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_shell_provider.dart';
import '../../state/web_socket_provider.dart';
import '../dynamic_renderer.dart';

/// Saved components drawer with grid layout, drag-and-drop combine,
/// "Condense All" button, per-component delete, and full-screen inspect.
///
/// Wired to WebSocket messages: save_component, get_saved_components,
/// delete_saved_component, combine_components, condense_components
/// per contracts/sdui-protocol.md.
class SavedComponentsDrawer extends StatefulWidget {
  const SavedComponentsDrawer({super.key});

  @override
  State<SavedComponentsDrawer> createState() => _SavedComponentsDrawerState();
}

class _SavedComponentsDrawerState extends State<SavedComponentsDrawer> {
  List<Map<String, dynamic>> _savedComponents = [];
  bool _isLoading = false;
  String? _lastChatId;

  @override
  void initState() {
    super.initState();
    _requestSavedComponents();
    _listenForUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = Provider.of<AppShellProvider>(context);
    if (_lastChatId != null && shell.activeChatId != _lastChatId) {
      _requestSavedComponents();
    }
    _lastChatId = shell.activeChatId;
  }

  void _requestSavedComponents() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    ws.sendEvent('get_saved_components', {});
    setState(() => _isLoading = true);
  }

  void _listenForUpdates() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    ws.addListener(_onWsUpdate);
  }

  void _onWsUpdate() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final components = ws.savedComponents;
    if (components != null) {
      setState(() {
        _savedComponents = List<Map<String, dynamic>>.from(components);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    ws.removeListener(_onWsUpdate);
    super.dispose();
  }

  void _deleteComponent(String componentId) {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    ws.sendEvent('delete_saved_component', {'component_id': componentId});
    setState(() {
      _savedComponents.removeWhere((c) => c['id'] == componentId);
    });
  }

  void _combineComponents(String sourceId, String targetId) {
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    ws.sendEvent('combine_components', {
      'source_id': sourceId,
      'target_id': targetId,
    });
  }

  void _condenseAll() {
    if (_savedComponents.length < 2) return;
    final ws = Provider.of<WebSocketProvider>(context, listen: false);
    final ids = _savedComponents.map((c) => c['id'] as String).toList();
    ws.sendEvent('condense_components', {'component_ids': ids});
  }

  void _inspectComponent(Map<String, dynamic> component) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    component['title'] ?? component['type'] ?? 'Component',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: DynamicRenderer(
                      component: component['data'] ?? component),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ws = Provider.of<WebSocketProvider>(context);
    final isCombining = ws.combineStatus.isNotEmpty;
    final combineError = ws.combineError;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Saved Components',
                  style: theme.textTheme.titleMedium),
              if (_savedComponents.length >= 2)
                TextButton.icon(
                  onPressed: isCombining ? null : _condenseAll,
                  icon: isCombining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.compress, size: 18),
                  label: Text(isCombining
                      ? (ws.combineStatusMessage.isNotEmpty
                          ? ws.combineStatusMessage
                          : 'Condensing...')
                      : 'Condense All'),
                ),
            ],
          ),

          // Combine error banner
          if (combineError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 16, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(combineError,
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Content
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_savedComponents.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No saved components yet.\nSave a component from the chat to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: _savedComponents.length,
                itemBuilder: (ctx, index) {
                  final component = _savedComponents[index];
                  return _buildComponentCard(component);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComponentCard(Map<String, dynamic> component) {
    final id = component['id'] as String? ?? '';
    final title = component['title'] as String? ??
        component['type'] as String? ??
        'Component';
    final type = component['type'] as String? ?? '';

    return LongPressDraggable<String>(
      data: id,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 160,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _cardContent(title, type, id),
      ),
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          final sourceId = details.data;
          if (sourceId != id) {
            _combineComponents(sourceId, id);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: isHovering
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: isHovering ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _cardContent(title, type, id),
          );
        },
      ),
    );
  }

  Widget _cardContent(String title, String type, String id) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          final comp = _savedComponents.firstWhere(
            (c) => c['id'] == id,
            orElse: () => <String, dynamic>{},
          );
          if (comp.isNotEmpty) _inspectComponent(comp);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  InkWell(
                    onTap: () => _deleteComponent(id),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(type,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor)),
              const Spacer(),
              Icon(Icons.drag_indicator,
                  size: 16, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }
}
