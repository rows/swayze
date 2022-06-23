import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show Axis;
import 'package:swayze_math/swayze_math.dart';

import '../../../config.dart' as config;
import '../controller.dart';

export 'header_state.dart';

/// A [ControllerBase] that manages some data on table.
///
/// Information that doesn't generate UI updates on Swayze:
/// [tableData] meta information of table.
///
/// Information that generate UI updates if changed:
/// [columns] and [rows] that are [SwayzeHeaderController].
///
/// It is possible to listen for particular changes on [columns] and [rows]
/// which are both [ValueListenable]s. To listen for change in both columns and
/// rows, [addListener] can be called directly.
///
/// See also:
/// - [SwayzeCellsController] which controls data regarding cells in the table.
class SwayzeTableDataController<ParentType extends SwayzeController>
    extends DataController implements SubController<ParentType>, Listenable {
  @override
  final ParentType parent;

  /// Table identifier
  final String id;

  /// A [SwayzeHeaderController] for the horizontal axis.
  final SwayzeHeaderController columns;

  /// A [SwayzeHeaderController] for the vertical axis
  final SwayzeHeaderController rows;

  /// The maximum amount of columns allowed in elastic expansion.
  final int? _maxElasticColumns;

  /// The maximum amount of rows allowed in elastic expansion.
  final int? _maxElasticRows;

  /// Merged [Listenable] to listen for changes on [columns] and [rows].
  late final _columnsAndRowsListenable = Listenable.merge([columns, rows]);

  SwayzeTableDataController({
    required this.id,
    required this.parent,
    required int columnCount,
    required int rowCount,
    required Iterable<SwayzeHeaderData> columns,
    required Iterable<SwayzeHeaderData> rows,
    required int frozenColumns,
    required int frozenRows,
    int? maxElasticColumns,
    int? maxElasticRows,
  })  : columns = SwayzeHeaderController._(
          initialState: SwayzeHeaderState(
            defaultHeaderExtent: config.kDefaultCellWidth,
            count: columnCount,
            headerData: columns,
            frozenCount: frozenColumns,
            maxElasticCount: maxElasticColumns,
          ),
        ),
        rows = SwayzeHeaderController._(
          initialState: SwayzeHeaderState(
            defaultHeaderExtent: config.kDefaultCellHeight,
            count: rowCount,
            headerData: rows,
            frozenCount: frozenRows,
            maxElasticCount: maxElasticRows,
          ),
        ),
        _maxElasticColumns = maxElasticColumns,
        _maxElasticRows = maxElasticRows,
        super() {
    parent.selection.addListener(handleSelectionChange);
  }

  /// A [Range2D] that represents the table to include all columns and rows
  Range2D get tableRange => Range2D.fromLTWH(
        const IntVector2.symmetric(0),
        IntVector2(
          columns.value.totalCount,
          rows.value.totalCount,
        ),
      );

  @override
  void dispose() {
    parent.selection.removeListener(handleSelectionChange);
    columns.dispose();
    rows.dispose();
  }

  /// Handle changes to the listenable to compute a new
  /// [SwayzeHeaderState].
  ///
  /// The Autoscroll and the reactions to selections in HeaderState create a
  /// cycle of updating selections and viewport size.
  ///
  /// WHile autoscrolling:
  ///   SwayzeSelectionController changes -> HeaderState updates cols/rows
  ///     -> AutoScrollController updates selection
  ///     -> HeaderState updates cols/row
  ///
  /// In order to break the cycle we [scheduleMicrotask] on
  /// [HeaderState]'s reaction to [SwayzeSelectionController] changes.
  ///
  /// This means that now, wHile autoscrolling:
  ///   SwayzeSelectionController changes
  ///   <<schedule microtask>> HeaderState updates cols/rows
  ///   AutoScrollController updates selection
  ///   <<schedule microtask>> HeaderState updates cols/rows
  void handleSelectionChange() {
    final selections = [
      ...parent.selection.userSelectionState.selections,
      parent.selection.fillSelectionState.selection,
      ...parent.selection.dataSelections,
    ].whereNotNull();

    final currentElasticEdge = IntVector2(
      columns.value.elasticCount,
      rows.value.elasticCount,
    );

    final elasticEdge = selections.fold<IntVector2>(
      const IntVector2.symmetric(0),
      (acc, selection) {
        final rowEdge = selection.bottom;
        final columnEdge = selection.right;

        return acc.copyWith(
          x: columnEdge == null ? acc.dx : max(acc.dx, columnEdge),
          y: rowEdge == null ? acc.dy : max(acc.dy, rowEdge),
        );
      },
    );

    if (currentElasticEdge == elasticEdge) {
      return;
    }

    scheduleMicrotask(() {
      columns.updateElasticCount(
        min(_maxElasticColumns ?? elasticEdge.dx, elasticEdge.dx),
      );
      rows.updateElasticCount(
        min(_maxElasticRows ?? elasticEdge.dy, elasticEdge.dy),
      );
    });
  }

  /// Retrieve a [SwayzeHeaderController] for a particular [axis].
  ///
  /// [Axis.horizontal] will return [columns]
  /// [Axis.vertical] will return [rows]
  SwayzeHeaderController getHeaderControllerFor({required Axis axis}) {
    return axis == Axis.horizontal ? columns : rows;
  }

  @override
  void addListener(VoidCallback listener) {
    _columnsAndRowsListenable.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _columnsAndRowsListenable.removeListener(listener);
  }
}

/// A [ValueListenable] that keeps the state of columns or rows in a table.
///
/// It follows an immutable patter where the state should be updated via
/// [updateState].
///
/// The state is stored as [SwayzeHeaderState].
///
/// The current value should be accessed via [value].
///
/// See also:
/// - [SwayzeTableDataController.columns] and [SwayzeTableDataController.rows]
///   that holds this information.
class SwayzeHeaderController extends ValueNotifier<SwayzeHeaderState>
    implements ControllerBase {
  SwayzeHeaderController._({
    required SwayzeHeaderState initialState,
  }) : super(initialState);

  void updateState(
    SwayzeHeaderState Function(SwayzeHeaderState previousState) stateUpdate,
  ) {
    value = stateUpdate(value);
  }

  /// Given a new elastic count, check if the new value will have impact on
  /// the total size of the grid and update it.
  ///
  /// To update the elastic count we need to make sure that:
  ///  1. its diferent from the previous one;
  ///  2. its bigger than the table's size and that the previous elastic count
  ///     was already affecting the table's size;
  ///
  /// If this conditions aren't met, the elastic count update won't have any
  /// impact on the UX and therefore can be skipped.
  void updateElasticCount(int newElasticCount) {
    if (newElasticCount == value.elasticCount) {
      return;
    }

    if (newElasticCount <= value.count && value.elasticCount <= value.count) {
      return;
    }

    value = value.copyWith(elasticCount: newElasticCount);
  }

  @protected
  @override
  set value(SwayzeHeaderState newValue) {
    super.value = newValue;
  }
}
