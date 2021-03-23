import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

import '../../../test_utils/create_cells_controller.dart';

void main() {
  group('PutCellOperation', () {
    test('commit', () {
      final cellsMatrix = MatrixMap<TestCellData>();
      cellsMatrix[const IntVector2(0, 0)] = TestCellData(
        position: const IntVector2(0, 0),
        value: 'ohlala',
      );

      PutCellOperation<TestCellData>(
        TestCellData(
          position: const IntVector2(0, 0),
          value: 'newvalue',
        ),
      ).commit(cellsMatrix);

      expect(
        cellsMatrix[const IntVector2(0, 0)]!.value,
        'newvalue',
      );
    });
    test('affects', () {
      final operation = PutCellOperation<TestCellData>(
        TestCellData(
          position: const IntVector2(0, 0),
          value: 'newvalue',
        ),
      );

      expect(
        operation.affects(
          Range2D.fromSides(
            const Range(0, 2),
            const Range(0, 2),
          ),
        ),
        true,
      );

      expect(
        operation.affects(
          Range2D.fromSides(
            const Range(4, 6),
            const Range(4, 6),
          ),
        ),
        false,
      );
    });
  });
  group('DeleteCellOperation', () {
    test('commit', () {
      final cellsMatrix = MatrixMap<TestCellData>();
      cellsMatrix[const IntVector2(0, 0)] = TestCellData(
        position: const IntVector2(0, 0),
        value: 'ohlala',
      );

      const DeleteCellOperation<TestCellData>(
        IntVector2(0, 0),
      ).commit(cellsMatrix);

      expect(cellsMatrix[const IntVector2(0, 0)], null);
    });
    test('affects', () {
      const operation = DeleteCellOperation<TestCellData>(
        IntVector2(0, 0),
      );

      expect(
        operation.affects(
          Range2D.fromSides(
            const Range(0, 2),
            const Range(0, 2),
          ),
        ),
        true,
      );

      expect(
        operation.affects(
          Range2D.fromSides(
            const Range(4, 6),
            const Range(4, 6),
          ),
        ),
        false,
      );
    });
  });
}
