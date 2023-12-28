import 'package:flutter/widgets.dart';

import '../core/config/config.dart';
import '../core/controller/controller.dart';
import '../core/delegates/cell_delegate.dart';
import '../core/style/style.dart';
import 'table.dart' show SliverSwayzeTable;

/// A scope to make internal state and context accessible all internal elements
/// on swayze.
///
/// See also:
/// * [SliverSwayzeTable] the widget created by the package-user that adds this
/// scope into the widget tree.
abstract class InternalScope<CellDataType extends SwayzeCellData> {
  /// The main controller specified to this table.
  SwayzeController get controller;

  /// The style specified to this table.
  SwayzeStyle get style;

  CellDelegate<CellDataType> get cellDelegate;

  /// Current swayze configuration.
  SwayzeConfig get config;

  /// Access the scope from a [context] subtree.
  /// Should be called by descendants of [InternalScopeProvider].
  ///
  /// It reads the widget, therefore it does not create context dependency.
  static InternalScope of(BuildContext context) {
    return context
        .getElementForInheritedWidgetOfExactType<InternalScopeProvider>()!
        .widget as InternalScopeProvider;
  }
}

/// A [InheritedWidget] that exposes [InternalScope] to its descendants.
///
/// Access the scope via [InternalScope.of].
class InternalScopeProvider<CellDataType extends SwayzeCellData>
    extends InheritedWidget implements InternalScope<CellDataType> {
  @override
  final SwayzeController controller;

  @override
  final SwayzeStyle style;

  @override
  final CellDelegate<CellDataType> cellDelegate;

  @override
  final SwayzeConfig config;

  const InternalScopeProvider({
    Key? key,
    required Widget child,
    required this.controller,
    required this.style,
    required this.cellDelegate,
    required this.config,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InternalScopeProvider oldWidget) {
    return false; // The scope per se will not be changed
  }
}
