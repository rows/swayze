import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'table_focus_state.dart';

abstract class TableFocus implements ValueListenable<TableFocusState> {
  static TableFocus of(BuildContext context) {
    return context
        .findAncestorWidgetOfExactType<_TableFocusProviderScope>()!
        .state;
  }

  /// Expose API to request focus for this widget's [FocusNode].
  void requestFocus();
}

/// A [StatefulWidget] that detects changes on the [FocusNode] and
/// [FocusScopeNode] to create a [TableFocusState] and add it to the tree
/// context via [_TableFocusProviderScope].
///
/// Descendant widgets can access the state via [TableFocus.of].
///
/// See also:
/// - [TableFocusState] the interface where the descendant widgets access
///   this widgets state.
class TableFocusProvider extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The [FocusNode] of the current table.
  final FocusNode focusNode;

  /// The Node that of the parent [FocusScope] which enables the tables
  /// to check which was the last focused table.
  final FocusScopeNode focusScopeNode;

  const TableFocusProvider({
    Key? key,
    required this.child,
    required this.focusNode,
    required this.focusScopeNode,
  }) : super(key: key);

  @override
  _TableFocusProviderState createState() => _TableFocusProviderState();
}

class _TableFocusProviderState extends State<TableFocusProvider>
    implements TableFocus {
  /// A internal [ValueNotifier] that actually keeps the state.
  late final _notifier = ValueNotifier(
    TableFocusState(
      hasFocus: widget.focusNode.hasFocus,
      isActive: widget.focusScopeNode.focusedChild == widget.focusNode,
    ),
  );

  @override
  void initState() {
    // Listen for changes in the current FocusNode and in the current
    // FocusScope group.
    widget.focusNode.addListener(updateFocusState);
    widget.focusScopeNode.addListener(updateFocusState);

    // compute initial values
    updateFocusState();

    super.initState();
  }

  @override
  void dispose() {
    _notifier.dispose();
    widget.focusNode.removeListener(updateFocusState);
    widget.focusScopeNode.removeListener(updateFocusState);

    super.dispose();
  }

  /// Register a callback to be called when the focus state changes.
  @override
  void addListener(VoidCallback listener) {
    _notifier.addListener(listener);
  }

  /// Remove a previously registered callback from the list of callbacks
  /// that are called on state changes.
  @override
  void removeListener(VoidCallback listener) {
    _notifier.removeListener(listener);
  }

  /// The current [TableFocusState].
  @override
  TableFocusState get value => _notifier.value;

  /// Updates the [TableFocusState].
  ///
  /// The isActive prop is calculated by checking if the last (or current)
  /// [FocusScopeNode.focusedChild] is the same nome as the current
  /// widget's [FocusNode].
  void updateFocusState() {
    _notifier.value = TableFocusState(
      hasFocus: widget.focusNode.hasFocus,
      isActive: widget.focusScopeNode.focusedChild == widget.focusNode,
    );
  }

  /// Expose API to request focus for this widget's [FocusNode].
  @override
  void requestFocus() {
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return _TableFocusProviderScope(
      state: this,
      child: widget.child,
    );
  }
}

/// A [InheritedWidget] that makes a [TableFocus] accessible to
/// its descendants.
///
/// It does not trigger dependency updates.
///
/// To access [state] on descendants, use [TableFocus.of].
///
/// See also:
/// - [_TableFocusProviderState.build] where this widget is added to the tree.
class _TableFocusProviderScope extends InheritedWidget {
  /// The [TableFocus] to be accessed by descendants.
  final TableFocus state;

  const _TableFocusProviderScope({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_TableFocusProviderScope oldWidget) {
    return false;
  }
}
