import 'package:flutter/foundation.dart';
import 'package:swayze_math/swayze_math.dart';

import 'cell_data.dart';

/// A definition of a mutative operation on the state of cells to be performed
/// on [matrix]
@immutable
abstract class CellOperation<CellDataType extends SwayzeCellData> {
  const CellOperation();

  /// Whether this operation affects a specific region of the matrix
  /// defined by [range].
  bool affects(Range2D range);

  /// Commit this operation into a [cellMatrix]
  void commit(MatrixMap<CellDataType> cellMatrix);
}

/// A description of a [CellOperation] that updates or inserts [cellData] into
/// the cell matrix.
class PutCellOperation<CellDataType extends SwayzeCellData>
    extends CellOperation<CellDataType> {
  final CellDataType cellData;

  const PutCellOperation(this.cellData) : super();

  @override
  bool affects(Range2D range) {
    return range.containsVector(cellData.position);
  }

  @override
  void commit(MatrixMap<CellDataType> matrix) {
    // when trying to put an empty cell, free resources instead
    if (cellData.isEmpty) {
      matrix.remove(
        colIndex: cellData.position.dx,
        rowIndex: cellData.position.dy,
      );
      return;
    }

    matrix[cellData.position] = cellData;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PutCellOperation &&
          runtimeType == other.runtimeType &&
          cellData == other.cellData;

  @override
  int get hashCode => cellData.hashCode;

  @override
  String toString() {
    return 'PutCellOperation:${cellData.position}';
  }
}

/// A description of a [CellOperation] that removes a cell located
/// on [position].
class DeleteCellOperation<CellDataType extends SwayzeCellData>
    extends CellOperation<CellDataType> {
  final IntVector2 position;

  const DeleteCellOperation(this.position) : super();

  @override
  bool affects(Range2D range) {
    return range.containsVector(position);
  }

  @override
  void commit(MatrixMap<CellDataType> matrix) {
    matrix.remove(
      colIndex: position.dx,
      rowIndex: position.dy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteCellOperation &&
          runtimeType == other.runtimeType &&
          position == other.position;

  @override
  int get hashCode => position.hashCode;

  @override
  String toString() {
    return 'DeleteCellOperation:$position';
  }
}
