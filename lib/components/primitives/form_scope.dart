import 'package:flutter/widgets.dart';

/// Provides a shared scope for Input and Button widgets within a Card
/// so that buttons with `collect_inputs: true` can gather all sibling
/// input values when pressed.
class FormScope extends InheritedWidget {
  final FormScopeState state;

  const FormScope({
    required this.state,
    required super.child,
    super.key,
  });

  static FormScopeState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FormScope>()?.state;
  }

  @override
  bool updateShouldNotify(FormScope oldWidget) => state != oldWidget.state;
}

/// Holds registered [TextEditingController]s keyed by input name.
class FormScopeState {
  final Map<String, TextEditingController> _controllers = {};

  void register(String name, TextEditingController controller) {
    _controllers[name] = controller;
  }

  void unregister(String name) {
    _controllers.remove(name);
  }

  /// Collects current values from all registered inputs.
  Map<String, String> collectValues() {
    return {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
  }
}

/// Stateful wrapper that creates and owns a [FormScopeState].
class FormScopeWidget extends StatefulWidget {
  final Widget child;

  const FormScopeWidget({required this.child, super.key});

  @override
  State<FormScopeWidget> createState() => _FormScopeWidgetState();
}

class _FormScopeWidgetState extends State<FormScopeWidget> {
  final _state = FormScopeState();

  @override
  Widget build(BuildContext context) {
    return FormScope(state: _state, child: widget.child);
  }
}
