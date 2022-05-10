import 'package:meta/meta.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

@isTest
void testMatrixMap(
  String desc,
  Function(MatrixMap<String> matrixMap) body, {
  String? skip,
}) {
  final matrixMap = MatrixMap<String>();
  test(desc, () => body(matrixMap), skip: skip);
}

void main() {
  group('MatrixMap', () {
    testMatrixMap('isEmpty', (matrixMap) {
      expect(matrixMap.isEmpty, equals(true));
      matrixMap.put('some item', colIndex: 0, rowIndex: 0);
      expect(matrixMap.isEmpty, equals(false));
      matrixMap.clear();
      expect(matrixMap.isEmpty, equals(true));
    });

    testMatrixMap('Insert items', (matrixMap) {
      matrixMap[const IntVector2(10, 12)] = 'item 1';
      expect(
        matrixMap[const IntVector2(10, 12)],
        'item 1',
      );

      matrixMap.put('item 2', colIndex: 1, rowIndex: 12);
      expect(
        matrixMap.elementAt(colIndex: 1, rowIndex: 12),
        'item 2',
      );

      matrixMap.put('item 3', colIndex: 1, rowIndex: 12);
      expect(
        matrixMap.elementAt(colIndex: 1, rowIndex: 12),
        'item 3',
      );

      matrixMap.put('item 4', colIndex: 3, rowIndex: 13);
      expect(
        matrixMap.elementAt(colIndex: 3, rowIndex: 13),
        'item 4',
      );

      final items = <String>[];

      matrixMap.forEachExistingItemOn(
        colIndices: [1, 3, 4],
        rowIndices: [10, 11, 12, 13, 14],
        iterate: (item, colIndex, rowIndex) => items.add(item),
      );
      // item 1 is not in range and item 2 was overwritten
      expect(items, ['item 3', 'item 4']);
    });

    testMatrixMap('item removal', (matrixMap) {
      matrixMap[const IntVector2.symmetric(10)] = 'item 1';
      expect(
        matrixMap.elementAt(colIndex: 10, rowIndex: 10),
        'item 1',
      );

      // remove existing item
      final returned1 = matrixMap.remove(colIndex: 10, rowIndex: 10);
      expect(
        matrixMap.elementAt(colIndex: 10, rowIndex: 10),
        null,
      );
      expect(returned1, equals('item 1'));

      // remove non-existing item
      final returned2 = matrixMap.remove(colIndex: 0, rowIndex: 0);
      expect(returned2, isNull);

      matrixMap.put('item 2', colIndex: 10, rowIndex: 10);
      matrixMap.put('item 3', colIndex: 11, rowIndex: 10);
      expect(
        matrixMap.elementAt(colIndex: 10, rowIndex: 10),
        'item 2',
      );
      expect(
        matrixMap.elementAt(colIndex: 11, rowIndex: 10),
        'item 3',
      );

      matrixMap.removeWhereInRow(10, (colIndex, value) => value == 'item 3');
      expect(
        matrixMap.elementAt(colIndex: 10, rowIndex: 10),
        'item 2',
      );
      expect(
        matrixMap.elementAt(colIndex: 11, rowIndex: 10),
        null,
      );

      matrixMap.clearRow(10);
      expect(
        matrixMap.elementAt(colIndex: 10, rowIndex: 10),
        null,
      );

      matrixMap.put('some item', colIndex: 20, rowIndex: 20);
      matrixMap.clear();
      expect(
        matrixMap.elementAt(colIndex: 20, rowIndex: 20),
        null,
      );
    });

    testMatrixMap('iterating', (matrixMap) {
      matrixMap[const IntVector2(0, 0)] = 'item1';
      matrixMap[const IntVector2(2, 2)] = 'item2';

      final existingItemsIteration = <IntVector2>[];
      matrixMap.forEachExistingItemOn(
        colIndices: [0, 2],
        rowIndices: [0, 2],
        iterate: (item, colIndex, rowIndex) {
          existingItemsIteration.add(IntVector2(colIndex, rowIndex));
        },
      );

      final allPositionsItemsIteration = <IntVector2>[];
      matrixMap.forEachPositionOn(
        colIndices: const Range(0, 3).iterable,
        rowIndices: const Range(0, 3).iterable,
        iterate: (item, colIndex, rowIndex) {
          allPositionsItemsIteration.add(IntVector2(colIndex, rowIndex));
        },
      );

      expect(existingItemsIteration, [
        const IntVector2(0, 0),
        const IntVector2(2, 2),
      ]);

      expect(allPositionsItemsIteration, [
        const IntVector2(0, 0),
        const IntVector2(1, 0),
        const IntVector2(2, 0),
        const IntVector2(0, 1),
        const IntVector2(1, 1),
        const IntVector2(2, 1),
        const IntVector2(0, 2),
        const IntVector2(1, 2),
        const IntVector2(2, 2),
      ]);
    });

    testMatrixMap('forEachInRange', (matrixMap) {
      final forEachInRange = <IntVector2>[];
      final iterable = matrixMap.forEachInRange(
        colIndices: const Range(0, 3).iterable,
        rowIndices: const Range(0, 3).iterable,
      );
      for (final result in iterable) {
        if (result.position.dx == 2 && result.position.dy == 1) {
          break;
        }

        forEachInRange.add(IntVector2(result.position.dx, result.position.dy));
      }

      expect(forEachInRange, [
        const IntVector2(0, 0),
        const IntVector2(1, 0),
        const IntVector2(2, 0),
        const IntVector2(0, 1),
        const IntVector2(1, 1),
      ]);
    });

    testMatrixMap('computeSize', (matrixMap) {
      matrixMap[const IntVector2(0, 0)] = 'item1';
      matrixMap[const IntVector2(2, 2)] = 'item2';
      expect(matrixMap.computeSize(), const IntVector2(3, 3));

      matrixMap[const IntVector2(5, 0)] = 'item1';
      matrixMap[const IntVector2(2, 52)] = 'item2';
      expect(matrixMap.computeSize(), const IntVector2(6, 53));
    });
  });
}
