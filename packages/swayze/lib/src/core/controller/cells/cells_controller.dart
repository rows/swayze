import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../controller.dart';
import '../../../widgets/table_body/cells/cells.dart';

export 'cell_data.dart';

/// Map [AxisDirection] into [IntVector2]
const _moveVectors = <AxisDirection, IntVector2>{
  AxisDirection.up: IntVector2(0, -1),
  AxisDirection.down: IntVector2(0, 1),
  AxisDirection.left: IntVector2(-1, 0),
  AxisDirection.right: IntVector2(1, 0),
};

/// A signature of callbacks responsible to convert a cell from a raw type to
/// [CellDataType]
typedef SwayzeCellsControllerCellParser<CellDataType extends SwayzeCellData>
    = CellDataType Function(dynamic rawCell);

/// A [ChangeNotifier] that is in charge of managing the state of all cells in
/// a table and to communicate state changes to its listeners.
///
/// ## There are two ways of modifying it state:
/// - From raw cells:
/// Ideally for communicating changes from an external format of cells such as
/// JSON.
/// The changes should be made via [putRawCells]. The controller constructor
/// also receives a iterable of raw cells.
/// The cells will be parsed to [CellDataType] via [cellParser].
///
/// - From parsed cells:
/// Changes via parsed cells should be made via [updateState].
///
/// ```
/// cellsController.updateState((modifier) {
///      modifier.putCell(
///        TestCellData(
///          position: const SwayzeCellPosition(column: 0, row: 0),
///          value: 'some new cell',
///        ),
///      );
/// });
/// ```
/// The parameter on the callback passed to [updateState] is a [CellsModifier].
///
/// After each [updateState], all listeners of [SwayzeCellsController] will be
/// notified.
///
///
/// See also:
/// - [SwayzeTableDataController] which controls data regarding table,
///   columns and rows.
/// - [CellsModifier] which is the interface for changes on cells state
/// - [Cells] the internal widget that listen for changes on this state and
///   updates the UI.
class SwayzeCellsController<CellDataType extends SwayzeCellData>
    extends ChangeNotifier implements DataController, SubController {
  @override
  final SwayzeController parent;
  SwayzeCellsControllerCellParser<CellDataType> cellParser;

  MatrixMap<CellDataType>? _cellMatrixNullable = MatrixMap();

  MatrixMap<CellDataType> get _cellMatrix {
    if (_cellMatrixNullable == null) {
      throw UnsupportedError(
        'Used Cells modifier after disposal. '
        'It is not possible to modify cells after disposal.',
      );
    }
    return _cellMatrixNullable!;
  }

  /// Operations performed in the last [updateState] execution.
  List<CellOperation> _lastPerformedOperations = [];

  SwayzeCellsController({
    required this.parent,
    required this.cellParser,
    required Iterable<dynamic> initialRawCells,
  }) {
    for (final initialCell in initialRawCells) {
      PutCellOperation<CellDataType>(cellParser(initialCell))
          .commit(_cellMatrix);
    }
  }

  /// Parse all [rawCells] and save in the state, notifying listeners.
  @protected
  @visibleForTesting
  void putRawCells(Iterable<dynamic> rawCells) {
    updateState((modifier) {
      for (final initialCell in rawCells) {
        modifier.putCell(cellParser(initialCell));
      }
    });
  }

  /// A map of each listener passed to [addCellOperationsListener] tied to the
  /// actual listener passed to [addListener].
  final _cellOperationsListeners =
      <ValueChanged<List<CellOperation>>, VoidCallback>{};

  /// Add a listener that receives the last performed operations that
  /// triggered the update.
  void addCellOperationsListener(ValueChanged<List<CellOperation>> listener) {
    void cellsOperationsListener() {
      listener(_lastPerformedOperations);
    }

    _cellOperationsListeners[listener] = cellsOperationsListener;
    super.addListener(cellsOperationsListener);
  }

  /// Remove a closure previously registered on [addCellOperationsListener].
  void removeCellOperationsListener(
    ValueChanged<List<CellOperation>> listener,
  ) {
    final specializedListener = _cellOperationsListeners.remove(listener);
    if (specializedListener == null) {
      return;
    }

    super.removeListener(specializedListener);
  }

  /// The way to create changes in the cell state externally.
  void updateState(
    void Function(CellsModifier<CellDataType> modifier) stateUpdate,
  ) {
    _lastPerformedOperations.clear();
    final modifier = CellsModifier<CellDataType>._();
    stateUpdate(modifier);
    if (modifier._performedOperations.isEmpty) {
      return;
    }
    _lastPerformedOperations = modifier._performedOperations;
    modifier._commitChanges(_cellMatrix);
    notifyListeners();
  }

  /// Access the table of cells in a read only interface.
  MatrixMapReadOnly<CellDataType> get cellMatrixReadOnly => _cellMatrix;

  /// Given an [IntVector2] and an [AxisDirection], return the next coordinate
  /// in the current block of cells.
  ///
  /// If the base cell has a value, it traverses the cells until it finds an
  /// empty cell, and returns the previous coordinate (the last with value).
  ///
  /// If the base cell does not have value, it traverses the cells until it
  /// finds a cell with value, and returns the previous coordinate (the last
  /// empty).
  ///
  /// The base cell is the given [originalCoordinate] if
  /// [useNeighboringCellAsBase] is `false`, or the neighboring cell to the
  /// [originalCoordinate] in the given [AxisDirection] if
  /// [useNeighboringCellAsBase] is `true` (the default).
  ///
  /// An optional [limit] may be passed to limit how many coordinates can be
  /// checked.
  IntVector2 getNextCoordinateInCellsBlock({
    required IntVector2 originalCoordinate,
    required AxisDirection direction,
    bool useNeighboringCellAsBase = true,
    int? limit,
  }) {
    final axis = axisDirectionToAxis(direction);
    var previousCoordinate = useNeighboringCellAsBase
        ? originalCoordinate
        : originalCoordinate - _moveVectors[direction]!;
    var currentCoordinate = useNeighboringCellAsBase
        ? originalCoordinate + _moveVectors[direction]!
        : originalCoordinate;

    final headerController =
        parent.tableDataController.getHeaderControllerFor(axis: axis);

    final effectiveLimit = limit ?? headerController.value.totalCount - 1;

    final isBaseCellFilled =
        _cellMatrix[currentCoordinate]?.hasVisibleContent == true;

    /// Conditions to stop iterating and finding the next cell.
    ///
    /// - if the previous coordinate and new coordinate are the same
    /// (it probably means we reached a edge of the grid).
    /// - If the base cell was filled, then we'll keep iterating while we find
    /// filled cells.
    /// - If the base cell was not filled, then we'll keep iterating while we
    /// find empty cells.
    bool shouldContinueLookup(IntVector2 prev, IntVector2 curr) {
      if (prev == curr) {
        return false;
      }

      // Check if the current cell is hidden, if so, skip it.
      final value = axis == Axis.vertical ? curr.dy : curr.dx;
      final headerData = headerController.value.customSizedHeaders[value];
      if (headerData?.hidden == true) {
        return true;
      }

      final hasValue = _cellMatrix[curr]?.hasVisibleContent == true;
      return isBaseCellFilled == hasValue;
    }

    // Iteratively move the current coordinate until [shouldContinueLookup]
    // finds the last coordinate in the current block.
    do {
      previousCoordinate = currentCoordinate;
      currentCoordinate += _moveVectors[direction]!;
      currentCoordinate = IntVector2(
        axis == Axis.horizontal
            ? max(0, min(currentCoordinate.dx, effectiveLimit))
            : currentCoordinate.dx,
        axis == Axis.vertical
            ? max(0, min(currentCoordinate.dy, effectiveLimit))
            : currentCoordinate.dy,
      );
    } while (shouldContinueLookup(previousCoordinate, currentCoordinate));

    final currentCellIsEmpty =
        _cellMatrix[currentCoordinate]?.hasNoVisibleContent == true;

    return (isBaseCellFilled != currentCellIsEmpty)
        ? previousCoordinate
        : currentCoordinate;
  }

  /// Given a [IntVector2] and a [AxisDirection] return the next coordinate
  /// that is not hidden.
  IntVector2 getNextCoordinate({
    required IntVector2 originalCoordinate,
    required AxisDirection direction,
  }) {
    final axis = axisDirectionToAxis(direction);
    final headerController =
        parent.tableDataController.getHeaderControllerFor(axis: axis);
    var newCoordinate = originalCoordinate;

    bool shouldContinueLookup(IntVector2 curr) {
      final value = axis == Axis.vertical ? curr.dy : curr.dx;
      final headerData = headerController.value.customSizedHeaders[value];
      return headerData?.hidden == true;
    }

    // Iteratively move the current coordinate until [shouldContinueLookup]
    // finds the a suitable coordinate.
    do {
      newCoordinate += _moveVectors[direction]!;

      final elasticCount = headerController.value.maxElasticCount;
      final count = headerController.value.count;

      final position =
          axis == Axis.horizontal ? newCoordinate.dx : newCoordinate.dy;

      final maxPosition = elasticCount != null
          // in case the user has set a max elastic count, we should
          // limit the grid expansion to that count, however, if that limit
          // is lower than the table size, we should prioritize the table size
          // over it.
          ? min(position, max(elasticCount - 1, count - 1))
          : position;

      newCoordinate = IntVector2(
        axis == Axis.horizontal ? max(0, maxPosition) : newCoordinate.dx,
        axis == Axis.vertical ? max(0, maxPosition) : newCoordinate.dy,
      );
    } while (shouldContinueLookup(newCoordinate));

    return newCoordinate;
  }

  @override
  void dispose() {
    _cellMatrixNullable!.clear();
    _cellMatrixNullable = null;
    super.dispose();
  }
}

/// A interface to map changes in the cell state ina specific state update.
///
/// It is accessible trough the callback passed to
/// [SwayzeCellsController.updateState].
///
/// Updates made here are not immediately applied to the matrix, instead, they
/// are made after the execution of the callback passed to
/// [SwayzeCellsController.updateState].
class CellsModifier<CellDataType extends SwayzeCellData> {
  CellsModifier._();

  final List<CellOperation<CellDataType>> _performedOperations = [];

  void deleteCell(IntVector2 position) {
    _performedOperations.add(DeleteCellOperation(position));
  }

  void putCell(CellDataType cellData) {
    _performedOperations.add(PutCellOperation(cellData));
  }

  /// Explicitly add a [CellOperation].
  /// Useful if you want to subclass and create your own operations.
  void addOperation(CellOperation<CellDataType> operation) {
    _performedOperations.add(operation);
  }

  void _commitChanges(MatrixMap<CellDataType> matrix) {
    for (final operation in _performedOperations) {
      operation.commit(matrix);
    }
  }
}
