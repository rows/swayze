import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

import '../../../test_utils/create_cells_controller.dart';

class _MockSwayzeController extends Mock implements SwayzeController {}

class _MockSwayzeTableDataController extends Mock
    implements SwayzeTableDataController {}

class _MockSwayzeHeaderController extends Mock
    implements SwayzeHeaderController {}

@isTest
void testCellsController(
  String desc,
  Function(
    SwayzeCellsController<TestCellData> cellsController,
  )
      body, {
  List<dynamic> initialRawCells = const <dynamic>[],
  SwayzeCellsControllerCellParser<TestCellData>? cellParser,
}) {
  final cellsController = SwayzeCellsController(
    parent: _MockSwayzeController(),
    cellParser: cellParser ??
        (dynamic position) => TestCellData(
              position: position as IntVector2,
              value: '${position.dx}-${position.dy}',
            ),
    initialRawCells: initialRawCells,
  );

  test(desc, () {
    body(cellsController);
    cellsController.dispose();
  });
}

void main() {
  group('Cells controller', () {
    testCellsController(
      'initial raw cells',
      (cellsController) {
        expect(
          cellsController.cellMatrixReadOnly[const IntVector2(0, 0)]!.value,
          equals('uba uba'),
        );
      },
      initialRawCells: const <dynamic>[IntVector2(0, 0)],
      cellParser: (dynamic position) => TestCellData(
        position: position as IntVector2,
        value: 'uba uba',
      ),
    );
    testCellsController(
      'put raw cells',
      (cellsController) {
        cellsController.putRawCells(
          const <dynamic>[IntVector2(0, 0)],
        );

        expect(
          cellsController.cellMatrixReadOnly[const IntVector2(0, 0)]!.value,
          equals('0-0'),
        );
      },
      initialRawCells: <dynamic>[],
      cellParser: (dynamic position) => TestCellData(
        position: position as IntVector2,
        value: '${position.dx}-${position.dy}',
      ),
    );

    group('update state', () {
      testCellsController(
        'put cell',
        (cellsController) {
          var count = 0;
          cellsController.addListener(() => count++);

          cellsController.updateState((modifier) {
            modifier.putCell(
              TestCellData(
                position: const IntVector2(0, 0),
                value: 'some',
              ),
            );
            modifier.putCell(
              TestCellData(
                position: const IntVector2(1, 1),
                value: 'another',
              ),
            );
            modifier.putCell(
              TestCellData(
                position: const IntVector2(2, 2),
                value: 'i am gonna be substituted',
              ),
            );
            // insert empty
            modifier.putCell(
              TestCellData(
                position: const IntVector2(2, 2),
              ),
            );
          });

          expect(count, equals(1));
          expect(
            cellsController.cellMatrixReadOnly[const IntVector2(0, 0)]!.value,
            equals('some'),
          );
          expect(
            cellsController.cellMatrixReadOnly[const IntVector2(1, 1)]!.value,
            equals('another'),
          );
          expect(
            cellsController.cellMatrixReadOnly[const IntVector2(2, 2)],
            isNull,
          );
        },
      );
      testCellsController(
        'delete cell',
        (cellsController) {
          var count = 0;
          cellsController.addListener(() => count++);
          cellsController.updateState((modifier) {
            modifier.deleteCell(const IntVector2(0, 0));
          });
          expect(count, equals(1));
          expect(
            cellsController.cellMatrixReadOnly[const IntVector2(0, 0)],
            null,
          );
        },
        initialRawCells: const <dynamic>[IntVector2(0, 0)],
      );
    });
  });

  group('getNextCoordinateInCellsBlock', () {
    setUpAll(() {
      registerFallbackValue(Axis.horizontal);
    });

    void addHeaderControllerMock(
      SwayzeCellsController cellsController, {
      required int count,
      Iterable<SwayzeHeaderData> headerData = const {},
      int freezeCount = 0,
    }) {
      final tableDataController = _MockSwayzeTableDataController();
      final headerController = _MockSwayzeHeaderController();

      when(
        () => tableDataController.getHeaderControllerFor(
          axis: any(named: 'axis'),
        ),
      ).thenReturn(headerController);

      when(() => headerController.value).thenReturn(
        SwayzeHeaderState(
          count: count,
          defaultHeaderExtent: 100,
          headerData: headerData,
          frozenCount: freezeCount,
        ),
      );
      when(() => cellsController.parent.tableDataController)
          .thenReturn(tableDataController);
    }

    testCellsController(
      'should be able move a block of empty cell until limit',
      (cellsController) {
        addHeaderControllerMock(cellsController, count: 11);

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(0, 0),
            direction: AxisDirection.right,
          ),
          const IntVector2(10, 0),
        );

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(0, 0),
            direction: AxisDirection.down,
          ),
          const IntVector2(0, 10),
        );

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(10, 10),
            direction: AxisDirection.up,
          ),
          const IntVector2(10, 0),
        );

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(10, 10),
            direction: AxisDirection.left,
          ),
          const IntVector2(0, 10),
        );
      },
      initialRawCells: <dynamic>[],
    );

    testCellsController(
      'should be able to move from an empty cell until it finds a filled cell',
      (cellsController) {
        addHeaderControllerMock(cellsController, count: 11);

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(0, 0),
            direction: AxisDirection.down,
          ),
          const IntVector2(0, 5),
        );
      },
      initialRawCells: const <dynamic>[IntVector2(0, 5)],
    );

    testCellsController(
      'should be able to move from an filled cell until it finds an empty cell',
      (cellsController) {
        addHeaderControllerMock(cellsController, count: 11);

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(0, 0),
            direction: AxisDirection.down,
          ),
          const IntVector2(0, 3),
        );
      },
      initialRawCells: const <dynamic>[
        IntVector2(0, 0),
        IntVector2(0, 1),
        IntVector2(0, 2),
        IntVector2(0, 3),
      ],
    );

    testCellsController(
      'should be able to skip an hidden cell',
      (cellsController) {
        addHeaderControllerMock(
          cellsController,
          count: 11,
          headerData: [
            const SwayzeHeaderData(hidden: true, index: 5, extent: null)
          ],
        );

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(0, 0),
            direction: AxisDirection.down,
          ),
          const IntVector2(0, 6),
        );
      },
      initialRawCells: const <dynamic>[
        IntVector2(0, 5),
        IntVector2(0, 6),
      ],
    );

    testCellsController(
      'should respect given limit',
      (cellsController) {
        addHeaderControllerMock(cellsController, count: 11);

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(0, 0),
            direction: AxisDirection.down,
            limit: 1,
          ),
          const IntVector2(0, 1),
        );
      },
      initialRawCells: const <dynamic>[
        IntVector2(0, 0),
        IntVector2(0, 1),
        IntVector2(0, 2),
        IntVector2(0, 3),
      ],
    );

    testCellsController(
      'should be able to use the given cell as base, instead of neighbor',
      (cellsController) {
        addHeaderControllerMock(cellsController, count: 11);

        expect(
          cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: const IntVector2(0, 0),
            direction: AxisDirection.down,
            useNeighboringCellAsBase: false,
          ),
          const IntVector2(0, 1),
        );
      },
      initialRawCells: const <dynamic>[
        IntVector2(0, 1),
        IntVector2(0, 2),
        IntVector2(0, 3),
      ],
    );
  });

  group('getNextCoordinate', () {
    setUpAll(() {
      registerFallbackValue(Axis.horizontal);
    });

    void addHeaderControllerMock(
      SwayzeCellsController cellsController, {
      int count = 11,
      Iterable<SwayzeHeaderData> headerData = const {},
      int freezeCount = 0,
    }) {
      final tableDataController = _MockSwayzeTableDataController();
      final headerController = _MockSwayzeHeaderController();

      when(
        () => tableDataController.getHeaderControllerFor(
          axis: any(named: 'axis'),
        ),
      ).thenReturn(headerController);

      when(() => headerController.value).thenReturn(
        SwayzeHeaderState(
          count: count,
          defaultHeaderExtent: 100,
          headerData: headerData,
          frozenCount: freezeCount,
        ),
      );
      when(() => cellsController.parent.tableDataController)
          .thenReturn(tableDataController);
    }

    testCellsController('should be able move in the given direction',
        (cellsController) {
      addHeaderControllerMock(cellsController);

      expect(
        cellsController.getNextCoordinate(
          originalCoordinate: const IntVector2(0, 0),
          direction: AxisDirection.right,
        ),
        const IntVector2(1, 0),
      );

      expect(
        cellsController.getNextCoordinate(
          originalCoordinate: const IntVector2(0, 0),
          direction: AxisDirection.down,
        ),
        const IntVector2(0, 1),
      );

      expect(
        cellsController.getNextCoordinate(
          originalCoordinate: const IntVector2(10, 10),
          direction: AxisDirection.up,
        ),
        const IntVector2(10, 9),
      );

      expect(
        cellsController.getNextCoordinate(
          originalCoordinate: const IntVector2(10, 10),
          direction: AxisDirection.left,
        ),
        const IntVector2(9, 10),
      );
    });

    testCellsController('should be able to skip an hidden cell',
        (cellsController) {
      addHeaderControllerMock(
        cellsController,
        headerData: [
          const SwayzeHeaderData(hidden: true, index: 1, extent: null)
        ],
      );

      expect(
        cellsController.getNextCoordinate(
          originalCoordinate: const IntVector2(0, 0),
          direction: AxisDirection.down,
        ),
        const IntVector2(0, 2),
      );
    });
  });
}
