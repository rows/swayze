import 'dart:math';

import '../swayze_math.dart';
import 'int_vector2.dart';

/// A function signature to iterate on a  [MatrixMap] of type [T]
typedef MatrixMapIterator<T> = void Function(
  T item,
  int colIndex,
  int rowIndex,
);

/// A function signature to iterate on a  [MatrixMap] of type [T]
typedef MaybeMatrixMapIterator<T> = void Function(
  T? item,
  int colIndex,
  int rowIndex,
);

/// Holds the value and position of an item in a [MatrixMapReadOnly].
class MatrixMapIterableResult<T> {
  final IntVector2 position;
  final T value;

  const MatrixMapIterableResult({required this.position, required this.value});
}

/// A read only interface for instances of [MatrixMap]
abstract class MatrixMapReadOnly<T> {
  /// Check if there is any item in this matrix
  bool get isEmpty;

  /// Calculate the horizontal and vertical edges of the matrix.
  IntVector2 computeSize();

  /// Get item in a specific position
  T? elementAt({
    required int colIndex,
    required int rowIndex,
  });

  /// Get element at a position corresponding to [coordinate].
  T? operator [](IntVector2 coordinate);

  /// Iterate in all items of this matrix map
  void forEach(
    MatrixMapIterator<T> iterate,
  );

  /// Iterate in all existing items in a given list of columns and rows.
  ///
  ///
  /// It ignores empty positions. To avoid that, use [forEachPositionOn].
  void forEachExistingItemOn({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
    required MatrixMapIterator<T> iterate,
  });

  /// Iterate in all positions, with existing items or not in a given list of
  /// columns and rows.
  ///
  /// If it is not necessary to iterate over empty position,
  /// prefer [forEachExistingItemOn].
  void forEachPositionOn({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
    required MaybeMatrixMapIterator<T> iterate,
  });

  /// Iterates all positions in the given list of columns and rows.
  Iterable<MatrixMapIterableResult<T?>> forEachInRange({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
  });

  /// Iterate in all items of this matrix map in a specific row.
  void forEachInRow(
    int rowIndex,
    MatrixMapIterator<T> iterate,
  );
}

/// A data structure that organizes items of [T] in a 2d map with [int] keys.
///
/// This structure prioritize rows over columns.
class MatrixMap<T> implements MatrixMapReadOnly<T> {
  /// A map rows. Each row is a map of items organized by columns
  final Map<int, Map<int, T>> _rows = {};

  /// [MatrixMapReadOnly.isEmpty]
  @override
  bool get isEmpty => _rows.isEmpty;

  /// [MatrixMapReadOnly.computeSize]
  @override
  IntVector2 computeSize() {
    var maxX = 0;
    var maxY = 0;

    for (final rowEntry in _rows.entries) {
      maxY = max(maxY, rowEntry.key);
      for (final columnEntry in rowEntry.value.entries) {
        maxX = max(maxX, columnEntry.key);
      }
    }

    return IntVector2(maxX + 1, maxY + 1);
  }

  /// [MatrixMapReadOnly.elementAt]
  @override
  T? elementAt({
    required int colIndex,
    required int rowIndex,
  }) {
    final rowMap = _rows[rowIndex];
    if (rowMap == null) {
      return null;
    }
    return rowMap[colIndex];
  }

  @override
  T? operator [](IntVector2 coordinate) => elementAt(
        colIndex: coordinate.dx,
        rowIndex: coordinate.dy,
      );

  /// Add item to a column/row position
  void put(
    T item, {
    required int colIndex,
    required int rowIndex,
  }) {
    final row = _rows[rowIndex] ?? <int, T>{};
    row[colIndex] = item;
    _rows[rowIndex] = row;
  }

  /// Insert an [item] into the matrix in the give [coordinate].
  void operator []=(IntVector2 coordinate, T item) {
    put(item, colIndex: coordinate.dx, rowIndex: coordinate.dy);
  }

  /// Remove items at column [colIndex] and row [rowIndex]
  /// Returns the removed item if found or null otherwise
  T? remove({
    required int colIndex,
    required int rowIndex,
  }) {
    final rowMap = _rows[rowIndex];
    if (rowMap == null) {
      return null;
    }
    final removed = rowMap.remove(colIndex);
    if (rowMap.isEmpty) {
      _rows.remove(rowIndex);
    }
    return removed;
  }

  /// [MatrixMapReadOnly.forEach]
  @override
  void forEach(
    MatrixMapIterator<T> iterate,
  ) {
    _rows.forEach((rowIndex, _columns) {
      _columns.forEach((colIndex, item) {
        iterate(item, colIndex, rowIndex);
      });
    });
  }

  @override
  void forEachExistingItemOn({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
    required MatrixMapIterator<T> iterate,
  }) {
    for (final rowIndex in rowIndices) {
      final row = _rows[rowIndex];
      if (row == null) {
        continue;
      }
      for (final colIndex in colIndices) {
        final cell = row[colIndex];
        if (cell == null) {
          continue;
        }
        iterate(cell, colIndex, rowIndex);
      }
    }
  }

  @override
  void forEachPositionOn({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
    required MaybeMatrixMapIterator<T> iterate,
  }) {
    for (final rowIndex in rowIndices) {
      final row = _rows[rowIndex];
      for (final colIndex in colIndices) {
        final cell = row?[colIndex];
        iterate(cell, colIndex, rowIndex);
      }
    }
  }

  /// See [MatrixMapReadOnly.forEachInRange].
  ///
  /// Returns a lazy [Iterable] of [MatrixMapIterableResult] that contains the
  /// item's value as well as its position.
  @override
  Iterable<MatrixMapIterableResult<T?>> forEachInRange({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
  }) sync* {
    for (final rowIndex in rowIndices) {
      final row = _rows[rowIndex];
      for (final colIndex in colIndices) {
        final cell = row?[colIndex];

        yield MatrixMapIterableResult(
          position: IntVector2(colIndex, rowIndex),
          value: cell,
        );
      }
    }
  }

  /// [MatrixMapReadOnly.forEachInRow]
  @override
  void forEachInRow(
    int rowIndex,
    MatrixMapIterator<T> iterate,
  ) {
    final rowMap = _rows[rowIndex];
    if (rowMap == null) {
      return;
    }
    rowMap.forEach((colIndex, item) {
      iterate(item, colIndex, rowIndex);
    });
  }

  /// Remove items in row [rowIndex] that respect to a [predicate]
  void removeWhereInRow(
    int rowIndex,
    bool Function(int colIndex, T value) predicate,
  ) {
    final rowMap = _rows[rowIndex];
    if (rowMap == null) {
      return;
    }
    rowMap.removeWhere(predicate);
  }

  // Removes all entries of this matrix that satisfy the given [predicate].
  void removeWhere(
    bool Function(int colIndex, int rowIndex, T value) predicate,
  ) {
    _rows.forEach((rowIndex, column) {
      column.removeWhere(
        (colIndex, value) => predicate(colIndex, rowIndex, value),
      );
    });
  }

  /// Remove an entire row from the collection
  void clearRow(int rowIndex) {
    _rows.remove(rowIndex);
  }

  /// Clear all items in the collection
  void clear() {
    _rows.clear();
  }

  @override
  String toString() {
    var matrixMap = 'MatrixMap:';

    _rows.forEach((key, value) {
      matrixMap += '''
      row $key: $value
      ''';
    });

    return matrixMap;
  }
}
