import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/src/widgets/table_body/cells/cell/cell.dart';
import 'package:swayze/src/widgets/table_body/cells/cells.dart';
import 'package:swayze/src/widgets/table_body/mouse_hover/mouse_hover.dart';
import 'package:swayze/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../test_utils/create_cell_delegate.dart';
import '../../../test_utils/create_cells_controller.dart';
import '../../../test_utils/create_swayze_controller.dart';
import '../../../test_utils/internal_widgets.dart';
import '../../../test_utils/type_of.dart';

Widget wrapCells(Widget content) {
  return wrapWithScope(
    MouseHoverTableBody(child: content),
  );
}

class TestCellMatrix extends MatrixMap<TestCellData> {
  final TestCellData Function(int column, int row) stubContentBuilder;

  TestCellMatrix(this.stubContentBuilder);

  @override
  void forEachExistingItemOn({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
    required MatrixMapIterator<TestCellData> iterate,
  }) {
    for (final rowIndex in rowIndices) {
      for (final columnIndex in colIndices) {
        iterate(
          stubContentBuilder(columnIndex, rowIndex),
          columnIndex,
          rowIndex,
        );
      }
    }
  }
}

class _MockSwayzeController extends Mock implements SwayzeController {}

class TestCellsController extends SwayzeCellsController<TestCellData> {
  final TestCellMatrix fakeTableMatrix;

  TestCellsController(this.fakeTableMatrix)
      : super(
          parent: _MockSwayzeController(),
          cellParser: (dynamic _) => _ as TestCellData,
          initialRawCells: <TestCellData>[],
        );

  @override
  MatrixMapReadOnly<TestCellData> get cellMatrixReadOnly => fakeTableMatrix;
}

Element cellElementAt(int index, Widget cellsWidget, WidgetTester tester) {
  final childFinder = find.descendant(
    of: find.byWidget(cellsWidget),
    matching: find.byType(typeOf<Cell<TestCellData>>()),
  );
  return tester.element(childFinder.at(index));
}

void main() {
  group('cells on scroll', () {
    testWidgets('renders the right cells', (tester) async {
      const horizontalRange = Range(0, 4);
      const verticalRange = Range(0, 3);

      const visibleColumnsIndices = [0, 1, 2];
      const visibleRows = [0, 2];

      const columnSizes = [10.0, 10.0, 10.0, 0.0];
      const rowSizes = [5.0, 0.0, 5.0];

      const columnOffsets = [0.0, 10.0, 20.0, 30.0];
      const rowOffsets = [0.0, 5.0, 5.0];

      final cellsWidget = Cells(
        cellDelegate: TestCellDelegate(),
        columnOffsets: columnOffsets,
        rowOffsets: rowOffsets,
        horizontalRange: horizontalRange,
        verticalRange: verticalRange,
        visibleColumnsIndices: visibleColumnsIndices,
        visibleRowsIndices: visibleRows,
        columnSizes: columnSizes,
        rowSizes: rowSizes,
        swayzeController: createSwayzeController(
          cellsController: TestCellsController(
            TestCellMatrix(
              (colIndex, rowIndex) => TestCellData(
                position: IntVector2(colIndex, rowIndex),
                value: '$colIndex-$rowIndex',
              ),
            ),
          ),
        ),
        swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
      );

      await tester.pumpWidget(
        wrapCells(cellsWidget),
      );

      // validate amount of cells on mount
      final childFinder = find.descendant(
        of: find.byWidget(cellsWidget),
        matching: find.byType(typeOf<Cell<TestCellData>>()),
      );
      expect(childFinder, findsNWidgets(6));

      var index = 0;
      // validate each cell content, position and offset
      for (var row = 0; row < 3; row++) {
        for (var column = 0; column < 4; column++) {
          if (row == 1) {
            // row 1 is hidden
            continue;
          }
          if (column == 3) {
            // column 3 is hidden
            continue;
          }

          final element = cellElementAt(
            index,
            cellsWidget,
            tester,
          );

          final parentData =
              (element.renderObject!).parentData! as CellParentData;
          expect(
            parentData.size,
            const Size(10, 5),
          );
          expect(
            parentData.offset,
            Offset(columnOffsets[column], rowOffsets[row]),
          );

          final widget = element.widget as Cell<TestCellData>;

          expect(widget.data.value, '$column-$row');

          index++;
        }
      }
    });
    testWidgets(
      'creates new cells and drops old ones on scroll update',
      (tester) async {
        const startingColumnOffset = [0.0, 10.0, 20.0];
        const startingRowOffsets = [0.0, 5.0];

        const startingHorizontalRange = Range(0, 3);
        const startingVerticalRange = Range(0, 2);

        const startingColumnSizes = [10.0, 10.0, 10.0];
        const startingRowSizes = [5.0, 5.0];

        final startingCellsWidget = Cells(
          cellDelegate: TestCellDelegate(),
          columnOffsets: startingColumnOffset,
          rowOffsets: startingRowOffsets,
          horizontalRange: startingHorizontalRange,
          verticalRange: startingVerticalRange,
          visibleColumnsIndices: startingHorizontalRange.iterable,
          visibleRowsIndices: startingVerticalRange.iterable,
          columnSizes: startingColumnSizes,
          rowSizes: startingRowSizes,
          swayzeController: createSwayzeController(
            cellsController: TestCellsController(
              TestCellMatrix(
                (colIndex, rowIndex) => TestCellData(
                  position: IntVector2(colIndex, rowIndex),
                  value: '$colIndex-$rowIndex',
                ),
              ),
            ),
          ),
          swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
        );

        await tester.pumpWidget(
          wrapCells(startingCellsWidget),
        );

        // update the amount and which columns/rows are visible
        const columnOffsets = [0.0, 10.0, 20.0];
        const rowOffsets = [0.0, 5.0, 10.0, 15.0];

        const horizontalRange = Range(2, 5);
        const verticalRange = Range(1, 5);

        const columnSizes = [10.0, 10.0, 10.0];
        const rowSizes = [5.0, 5.0, 5.0, 5.0];

        final cellsWidget = Cells(
          cellDelegate: TestCellDelegate(),
          columnOffsets: columnOffsets,
          rowOffsets: rowOffsets,
          horizontalRange: horizontalRange,
          verticalRange: verticalRange,
          visibleColumnsIndices: horizontalRange.iterable,
          visibleRowsIndices: verticalRange.iterable,
          columnSizes: columnSizes,
          rowSizes: rowSizes,
          swayzeController: createSwayzeController(
            cellsController: TestCellsController(
              TestCellMatrix(
                (colIndex, rowIndex) => TestCellData(
                  position: IntVector2(colIndex, rowIndex),
                  value: '$colIndex-$rowIndex-new',
                ),
              ),
            ),
          ),
          swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
        );

        await tester.pumpWidget(
          wrapCells(cellsWidget),
        );

        // validate the new number of cells
        final childFinder2 = find.descendant(
          of: find.byType(typeOf<Cells<TestCellData>>()),
          matching: find.byType(typeOf<Cell<TestCellData>>()),
        );
        expect(childFinder2, findsNWidgets(12));

        // validate if only the new fetched cells has new content
        for (var row = 0; row < 4; row++) {
          for (var column = 0; column < 3; column++) {
            final index = (row * 3) + column;

            final element = cellElementAt(
              index,
              cellsWidget,
              tester,
            );

            final parentData =
                (element.renderObject!).parentData! as CellParentData;
            expect(
              parentData.size,
              const Size(10, 5),
            );
            expect(
              parentData.offset,
              Offset(columnOffsets[column], rowOffsets[row]),
            );

            final widget = element.widget as Cell<TestCellData>;

            final realColumn = horizontalRange.start + column;
            final realRow = verticalRange.start + row;
            var content = '$realColumn-$realRow';

            // new cells will have a '-new' content
            if (realColumn >= 3 || realRow >= 2) {
              content += '-new';
            }

            expect(widget.data.value, content);
          }
        }
      },
    );
  });

  group('empty cells', () {
    testWidgets('do not render empty cells', (tester) async {
      // call cells controller in which every cell in the row zero is empty
      final cellsController = TestCellsController(
        TestCellMatrix((colIndex, rowIndex) {
          if (rowIndex == 0) {
            return TestCellData(
              position: IntVector2(colIndex, rowIndex),
            );
          }
          return TestCellData(
            position: IntVector2(colIndex, rowIndex),
            value: '$colIndex-$rowIndex',
          );
        }),
      );

      final cellsWidget = Cells(
        cellDelegate: TestCellDelegate(),
        columnOffsets: const [0.0, 10.0, 20.0],
        rowOffsets: const [0.0, 10.0, 20.0],
        horizontalRange: const Range(0, 3),
        verticalRange: const Range(0, 3),
        visibleColumnsIndices: const Range(0, 3).iterable,
        visibleRowsIndices: const Range(0, 3).iterable,
        columnSizes: List<double>.filled(3, 10.0),
        rowSizes: List<double>.filled(3, 10.0),
        swayzeController: createSwayzeController(
          cellsController: cellsController,
        ),
        swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
      );

      await tester.pumpWidget(
        wrapCells(cellsWidget),
      );

      // validate amount of cells on mount
      final childFinder = find.descendant(
        of: find.byWidget(cellsWidget),
        matching: find.byType(typeOf<Cell<TestCellData>>()),
      );
      expect(childFinder, findsNWidgets(6)); // first row is ignored

      final element = cellElementAt(
        0,
        cellsWidget,
        tester,
      );

      final widget = element.widget as Cell<TestCellData>;

      expect(widget.data.value, '0-1');
    });
  });

  group('on cell store update', () {
    testWidgets('sync cells', (tester) async {
      final cellsController = SwayzeCellsController<TestCellData>(
        parent: _MockSwayzeController(),
        cellParser: (dynamic _) => _ as TestCellData,
        initialRawCells: <dynamic>[],
      );

      final cellsWidget = Cells(
        cellDelegate: TestCellDelegate(),
        columnOffsets: const [0.0, 10.0, 20.0],
        rowOffsets: const [0.0, 10.0, 20.0],
        horizontalRange: const Range(0, 3),
        verticalRange: const Range(0, 3),
        visibleColumnsIndices: const Range(0, 3).iterable,
        visibleRowsIndices: const Range(0, 3).iterable,
        columnSizes: List<double>.filled(3, 10.0),
        rowSizes: List<double>.filled(3, 10.0),
        swayzeController: createSwayzeController(
          cellsController: cellsController,
        ),
        swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
      );

      await tester.pumpWidget(
        wrapCells(
          cellsWidget,
        ),
      );

      /** insert new cell */
      expect(
        find.descendant(
          of: find.byWidget(cellsWidget),
          matching: find.byType(typeOf<Cell<TestCellData>>()),
        ),
        findsNWidgets(0),
      );

      cellsController.putRawCells(<dynamic>[
        TestCellData(
          position: const IntVector2(0, 0),
          value: 'Some value 1',
        ),
        TestCellData(
          position: const IntVector2(1, 0),
          value: 'Some value 2',
        ),
      ]);
      await tester.pumpAndSettle();

      // has added one cell
      expect(
        find.descendant(
          of: find.byWidget(cellsWidget),
          matching: find.byType(typeOf<Cell<TestCellData>>()),
        ),
        findsNWidgets(2),
      );

      final widget1 = cellElementAt(
        0,
        cellsWidget,
        tester,
      ).widget as Cell<TestCellData>;

      expect(widget1.data.value, 'Some value 1');

      final widget2 = cellElementAt(
        1,
        cellsWidget,
        tester,
      ).widget as Cell<TestCellData>;

      expect(widget2.data.value, 'Some value 2');

      /** update cell */
      cellsController.putRawCells(<dynamic>[
        TestCellData(
          position: const IntVector2(0, 0),
          value: 'Some other value',
        ),
      ]);
      await tester.pumpAndSettle();

      // has updated one cell
      expect(
        find.descendant(
          of: find.byWidget(cellsWidget),
          matching: find.byType(typeOf<Cell<TestCellData>>()),
        ),
        findsNWidgets(2),
      );

      final widgetUpdated = cellElementAt(
        0,
        cellsWidget,
        tester,
      ).widget as Cell<TestCellData>;

      expect(widgetUpdated.data.value, 'Some other value');

      /** update cell OUTSIDE THE VIEWPORT */
      cellsController.putRawCells(<dynamic>[
        TestCellData(
          position: const IntVector2(100, 100),
          value: 'A cell outside the viewport',
        ),
      ]);
      await tester.pumpAndSettle();

      // has not updated anything
      expect(
        find.descendant(
          of: find.byWidget(cellsWidget),
          matching: find.byType(typeOf<Cell<TestCellData>>()),
        ),
        findsNWidgets(2),
      );

      /** remove cell */
      cellsController.updateState((modifier) {
        modifier.deleteCell(
          const IntVector2(1, 0),
        );
      });
      await tester.pumpAndSettle();

      // has removed one cell
      expect(
        find.descendant(
          of: find.byWidget(cellsWidget),
          matching: find.byType(typeOf<Cell<TestCellData>>()),
        ),
        findsNWidgets(1),
      );

      /** update to empty cell */
      cellsController.updateState((modifier) {
        modifier.putCell(
          TestCellData(
            position: const IntVector2(0, 0),
          ),
        );
      });
      await tester.pumpAndSettle();

      // has removed one cell
      expect(
        find.descendant(
          of: find.byWidget(cellsWidget),
          matching: find.byType(typeOf<Cell<TestCellData>>()),
        ),
        findsNWidgets(0),
      );
    });
  });

  testWidgets('renders cells with new sizes', (tester) async {
    const startingHorizontalRange = Range(0, 4);
    const startingVerticalRange = Range(0, 4);

    const startingColumnSizes = [10.0, 20.0, 10.0, 10.0];
    const startingRowSizes = [5.0, 5.0, 10.0, 5.0];

    const startingColumnOffsets = [0.0, 10.0, 30.0, 40.0];
    const startingRowOffsets = [0.0, 5.0, 10.0, 20.0];

    final startingCellsWidget = Cells(
      cellDelegate: TestCellDelegate(),
      columnOffsets: startingColumnOffsets,
      rowOffsets: startingRowOffsets,
      horizontalRange: startingHorizontalRange,
      verticalRange: startingVerticalRange,
      visibleColumnsIndices: startingHorizontalRange.iterable,
      visibleRowsIndices: startingVerticalRange.iterable,
      columnSizes: startingColumnSizes,
      rowSizes: startingRowSizes,
      swayzeController: createSwayzeController(
        cellsController: TestCellsController(
          TestCellMatrix(
            (colIndex, rowIndex) => TestCellData(
              position: IntVector2(colIndex, rowIndex),
              value: '$colIndex-$rowIndex-old',
            ),
          ),
        ),
      ),
      swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
    );

    await tester.pumpWidget(
      wrapCells(startingCellsWidget),
    );

    // validate amount of cells on mount
    final childFinder = find.descendant(
      of: find.byWidget(startingCellsWidget),
      matching: find.byType(typeOf<Cell<TestCellData>>()),
    );
    expect(childFinder, findsNWidgets(16));

    const horizontalRange = Range(0, 4);
    const verticalRange = Range(0, 4);

    const columnSizes = [10.0, 10.0, 20.0, 10.0];
    const rowSizes = [5.0, 5.0, 0.0, 5.0];

    const columnOffsets = [0.0, 10.0, 20.0, 40.0];
    const rowOffsets = [0.0, 5.0, 10.0, 10.0];

    const visibleColumnsIndices = [0, 1, 2, 3];
    const visibleRows = [0, 1, 3];

    final cellsWidget = Cells(
      cellDelegate: TestCellDelegate(),
      columnOffsets: columnOffsets,
      rowOffsets: rowOffsets,
      horizontalRange: horizontalRange,
      verticalRange: verticalRange,
      columnSizes: columnSizes,
      visibleColumnsIndices: visibleColumnsIndices,
      visibleRowsIndices: visibleRows,
      rowSizes: rowSizes,
      swayzeController: createSwayzeController(
        cellsController: TestCellsController(
          TestCellMatrix(
            (colIndex, rowIndex) => TestCellData(
              position: IntVector2(colIndex, rowIndex),
              value: '$colIndex-$rowIndex-new',
            ),
          ),
        ),
      ),
      swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
    );

    await tester.pumpWidget(
      wrapCells(cellsWidget),
    );

    // validate the new number of cells
    final childFinder2 = find.descendant(
      of: find.byWidget(cellsWidget),
      matching: find.byType(typeOf<Cell<TestCellData>>()),
    );
    expect(childFinder2, findsNWidgets(12));

    var index = 0;
    // validate each cell content, position and offset
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 4; column++) {
        if (row == 2) {
          // row 2 is hidden
          continue;
        }

        final element = cellElementAt(
          index,
          cellsWidget,
          tester,
        );

        final parentData =
            (element.renderObject!).parentData! as CellParentData;
        expect(
          parentData.size,
          Size(columnSizes[column], rowSizes[row]),
        );
        expect(
          parentData.offset,
          Offset(columnOffsets[column], rowOffsets[row]),
        );

        final widget = element.widget as Cell<TestCellData>;

        // expect with old context because header update alone is not
        // supposed to change the cells content
        expect(widget.data.value, '$column-$row-old');

        index++;
      }
    }
  });

  testWidgets(
    'renders cells with new sizes and possible new ranges',
    (tester) async {
      const startingColumnOffsets = [0.0, 10.0, 20.0];
      const startingRowOffsets = [0.0, 5.0, 10.0];

      const startingHorizontalRange = Range(0, 3);
      const startingVerticalRange = Range(0, 3);

      const startingColumnSizes = [10.0, 10.0, 10.0];
      const startingRowSizes = [5.0, 5.0, 10.0];

      final startingCellsWidget = Cells(
        cellDelegate: TestCellDelegate(),
        columnOffsets: startingColumnOffsets,
        rowOffsets: startingRowOffsets,
        horizontalRange: startingHorizontalRange,
        verticalRange: startingVerticalRange,
        visibleColumnsIndices: startingHorizontalRange.iterable,
        visibleRowsIndices: startingVerticalRange.iterable,
        columnSizes: startingColumnSizes,
        rowSizes: startingRowSizes,
        swayzeController: createSwayzeController(
          cellsController: TestCellsController(
            TestCellMatrix(
              (colIndex, rowIndex) => TestCellData(
                position: IntVector2(colIndex, rowIndex),
                value: '$colIndex-$rowIndex-old',
              ),
            ),
          ),
        ),
        swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
      );

      await tester.pumpWidget(
        wrapCells(startingCellsWidget),
      );

      // validate amount of cells on mount
      final childFinder = find.descendant(
        of: find.byWidget(startingCellsWidget),
        matching: find.byType(typeOf<Cell<TestCellData>>()),
      );
      expect(childFinder, findsNWidgets(9));

      const columnOffsets = [0.0, 5.0, 10.0, 25.0];
      const rowOffsets = [0.0, 5.0, 10.0];

      const horizontalRange = Range(0, 4);
      const verticalRange = Range(0, 3);

      const columnSizes = [5.0, 5.0, 5.0, 10.0];
      const rowSizes = [5.0, 5.0, 5.0];

      final cellsWidget = Cells(
        cellDelegate: TestCellDelegate(),
        columnOffsets: columnOffsets,
        rowOffsets: rowOffsets,
        horizontalRange: horizontalRange,
        verticalRange: verticalRange,
        visibleColumnsIndices: horizontalRange.iterable,
        visibleRowsIndices: verticalRange.iterable,
        columnSizes: columnSizes,
        rowSizes: rowSizes,
        swayzeController: createSwayzeController(
          cellsController: TestCellsController(
            TestCellMatrix(
              (colIndex, rowIndex) => TestCellData(
                position: IntVector2(colIndex, rowIndex),
                value: '$colIndex-$rowIndex-new',
              ),
            ),
          ),
        ),
        swayzeStyle: SwayzeStyle.defaultSwayzeStyle,
      );

      await tester.pumpWidget(
        wrapCells(cellsWidget),
      );

      // validate the new number of cells
      final childFinder2 = find.descendant(
        of: find.byWidget(cellsWidget),
        matching: find.byType(typeOf<Cell<TestCellData>>()),
      );
      expect(childFinder2, findsNWidgets(12));

      // validate each cell content, position and offset
      for (var row = 0; row < 3; row++) {
        for (var column = 0; column < 4; column++) {
          final index = (row * 4) + column;

          final element = cellElementAt(
            index,
            cellsWidget,
            tester,
          );

          final parentData =
              (element.renderObject!).parentData! as CellParentData;
          expect(
            parentData.size,
            Size(columnSizes[column], rowSizes[row]),
          );
          expect(
            parentData.offset,
            Offset(columnOffsets[column], rowOffsets[row]),
          );

          final widget = element.widget as Cell<TestCellData>;

          // last column is the on added due to resize
          if (column == 3) {
            expect(widget.data.value, '$column-$row-new');
          } else {
            expect(widget.data.value, '$column-$row-old');
          }
        }
      }
    },
  );
}
