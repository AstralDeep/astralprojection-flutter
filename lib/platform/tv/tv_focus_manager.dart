import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// T070 -- Wraps content with FocusTraversalGroup and D-pad/remote shortcuts.
///
/// Arrow keys map to directional focus traversal so that TV remotes and
/// keyboard D-pads can navigate between focusable widgets.
class TvFocusManager extends StatelessWidget {
  final Widget child;

  const TvFocusManager({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowUp):
              DirectionalFocusIntent(TraversalDirection.up),
          SingleActivator(LogicalKeyboardKey.arrowDown):
              DirectionalFocusIntent(TraversalDirection.down),
          SingleActivator(LogicalKeyboardKey.arrowLeft):
              DirectionalFocusIntent(TraversalDirection.left),
          SingleActivator(LogicalKeyboardKey.arrowRight):
              DirectionalFocusIntent(TraversalDirection.right),
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DirectionalFocusIntent:
                DirectionalFocusAction(context: context),
          },
          child: child,
        ),
      ),
    );
  }
}

/// Custom action that moves focus in the requested direction.
class DirectionalFocusAction extends Action<DirectionalFocusIntent> {
  DirectionalFocusAction({required this.context});

  final BuildContext context;

  @override
  void invoke(DirectionalFocusIntent intent) {
    final node = FocusManager.instance.primaryFocus;
    if (node != null) {
      node.focusInDirection(intent.direction);
    }
  }
}
