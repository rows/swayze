import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/intents.dart';
import 'package:swayze/src/widgets/headers/header.dart';
import 'package:swayze/src/widgets/headers/header_item.dart';
import 'package:swayze/src/widgets/table_body/selections/primary_selection/primary_selection.dart';
import 'package:swayze/src/widgets/table_body/selections/secondary_selections/secondary_selections.dart';
import 'package:swayze_math/swayze_math.dart';

import 'test_utils/create_cells_controller.dart';
import 'test_utils/create_swayze_controller.dart';
import 'test_utils/create_table_data.dart';
import 'test_utils/create_test_victim.dart';
import 'test_utils/fonts.dart';
import 'test_utils/get_cell_offset.dart';

Size getPrimarySelectionSize(WidgetTester tester) {
  final selection = find.descendant(
    of: find.byType(PrimarySelection).first,
    matching: find.byType(PrimarySelectionPainter),
  );

  final primarySelectionPainter =
      selection.evaluate().first.widget as PrimarySelectionPainter;

  return primarySelectionPainter.size;
}

Offset getActiveCellOffset(WidgetTester tester) {
  final selection = find.descendant(
    of: find.byType(PrimarySelection).first,
    matching: find.byType(PrimarySelectionPainter),
  );

  final primarySelectionPainter =
      selection.evaluate().first.widget as PrimarySelectionPainter;

  return tester.getTopLeft(selection) +
      primarySelectionPainter.activeCellRect.center;
}

Rect? globalPaintBounds(RenderObject renderObject) {
  final translation = renderObject.getTransformTo(null).getTranslation();
  return renderObject.paintBounds.shift(Offset(translation.x, translation.y));
}

void main() async {
  await loadFonts();

  group('selection', () {
    group('select table', () {
      testWidgets('default behavior', (tester) async {
        final verticalScrollController = ScrollController();

        await tester.pumpWidget(
          TestSwayzeVictim(
            verticalScrollController: verticalScrollController,
            tables: [
              TestTableWrapper(
                verticalScrollController: verticalScrollController,
                swayzeController: createSwayzeController(
                  tableDataController: createTableController(
                    tableColumnCount: 5,
                    tableRowCount: 5,
                  ),
                ),
              ),
            ],
          ),
        );

        await tester.tapAt(getCellOffset(tester, column: 1, row: 1));
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pumpAndSettle();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/table-selection.png'),
        );
      });
      testWidgets('override', (tester) async {
        final verticalScrollController = ScrollController();

        bool? actionCalled;

        await tester.pumpWidget(
          Actions(
            actions: {
              SelectTableIntent: CallbackAction<SelectTableIntent>(
                onInvoke: (intent) {
                  actionCalled = true;
                  return null;
                },
              ),
            },
            child: TestSwayzeVictim(
              verticalScrollController: verticalScrollController,
              tables: [
                TestTableWrapper(
                  verticalScrollController: verticalScrollController,
                  swayzeController: createSwayzeController(
                    tableDataController: createTableController(
                      tableColumnCount: 5,
                      tableRowCount: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.tapAt(getCellOffset(tester, column: 1, row: 1));
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pumpAndSettle();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);

        expect(actionCalled, true);
      });
    });

    group('move active cell', () {
      testWidgets('default behavior', (tester) async {
        final verticalScrollController = ScrollController();
        await tester.pumpWidget(
          TestSwayzeVictim(
            verticalScrollController: verticalScrollController,
            tables: [
              TestTableWrapper(
                autofocus: true,
                verticalScrollController: verticalScrollController,
                swayzeController: createSwayzeController(
                  tableDataController: createTableController(
                    tableColumnCount: 5,
                    tableRowCount: 5,
                  ),
                ),
              ),
            ],
          ),
        );

        // wait for autofocus to kick in...
        await tester.pump(const Duration(milliseconds: 50));

        final initialOffset = getActiveCellOffset(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        final middleOffset = getActiveCellOffset(tester);

        expect(
          middleOffset - initialOffset,
          equals(const Offset(120, 33)),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        final finalOffset = getActiveCellOffset(tester);

        expect(finalOffset, initialOffset);
      });

      testWidgets('override', (tester) async {
        final verticalScrollController = ScrollController();
        AxisDirection? direction;
        await tester.pumpWidget(
          Actions(
            actions: {
              MoveActiveCellIntent: CallbackAction<MoveActiveCellIntent>(
                onInvoke: (intent) {
                  direction = intent.direction;
                  return null;
                },
              ),
            },
            child: TestSwayzeVictim(
              verticalScrollController: verticalScrollController,
              tables: [
                TestTableWrapper(
                  autofocus: true,
                  verticalScrollController: verticalScrollController,
                  swayzeController: createSwayzeController(
                    tableDataController: createTableController(
                      tableColumnCount: 5,
                      tableRowCount: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // wait for autofocus to kick in...
        await tester.pump(const Duration(milliseconds: 50));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        expect(direction, AxisDirection.down);
      });
    });
    group('move active cell by block', () {
      testWidgets('default behavior', (tester) async {
        final swayzeController = createSwayzeController(
          tableDataController: createTableController(
            tableColumnCount: 10,
            tableRowCount: 10,
          ),
        );

        swayzeController.cellsController.updateState((modifier) {
          modifier.putCell(
            TestCellData(
              position: const IntVector2(0, 0),
              value: 'Table1 Cell 0,0',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(3, 0),
              value: 'Table1 Cell 0,3',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(4, 0),
              value: 'Table1 Cell 0,3',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(5, 0),
              value: 'Table1 Cell 0,3',
            ),
          );
        });

        await tester.pumpWidget(
          TestSwayzeVictim(
            tables: [
              TestTableWrapper(
                autofocus: true,
                swayzeController: swayzeController,
              ),
            ],
          ),
        );

        // wait for autofocus to kick in...
        await tester.pump(const Duration(milliseconds: 50));

        // Start on 0,0
        expect(
          getActiveCellOffset(tester),
          getCellOffset(tester, column: 0, row: 0),
        );

        // Go to block right - 3, 0
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(
          getActiveCellOffset(tester),
          getCellOffset(tester, column: 3, row: 0),
        );

        // Go to block right - 5, 0
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(
          getActiveCellOffset(tester),
          getCellOffset(tester, column: 5, row: 0),
        );

        // Go to block down - 5, 9
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(
          getActiveCellOffset(tester),
          getCellOffset(tester, column: 5, row: 9),
        );

        // Go to block left - 0, 9
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(
          getActiveCellOffset(tester),
          getCellOffset(tester, column: 0, row: 9),
        );
      });

      testWidgets('override', (tester) async {
        AxisDirection? direction;
        final swayzeController = createSwayzeController(
          tableDataController: createTableController(
            tableColumnCount: 10,
            tableRowCount: 10,
          ),
        );

        swayzeController.cellsController.updateState((modifier) {
          modifier.putCell(
            TestCellData(
              position: const IntVector2(0, 0),
              value: 'Table1 Cell 0,0',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(3, 0),
              value: 'Table1 Cell 3,0',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(4, 0),
              value: 'Table1 Cell 4,0',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(5, 0),
              value: 'Table1 Cell 5,0',
            ),
          );
        });

        await tester.pumpWidget(
          Actions(
            actions: {
              MoveActiveCellByBlockIntent:
                  CallbackAction<MoveActiveCellByBlockIntent>(
                onInvoke: (intent) {
                  direction = intent.direction;
                  return null;
                },
              ),
            },
            child: TestSwayzeVictim(
              tables: [
                TestTableWrapper(
                  autofocus: true,
                  swayzeController: swayzeController,
                ),
              ],
            ),
          ),
        );

        // wait for autofocus to kick in...
        await tester.pump(const Duration(milliseconds: 50));

        // Go to block right - 3, 0
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(direction, AxisDirection.right);
      });
    });

    group('expand selection', () {
      testWidgets('default behavior', (tester) async {
        await tester.pumpWidget(
          TestSwayzeVictim(
            tables: [
              TestTableWrapper(
                autofocus: true,
                swayzeController: createSwayzeController(
                  tableDataController: createTableController(
                    tableColumnCount: 5,
                    tableRowCount: 5,
                  ),
                ),
              ),
            ],
          ),
        );

        expect(find.byType(PrimarySelection), findsNothing);
        expect(find.byType(SecondarySelections), findsNothing);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(find.byType(PrimarySelection), findsOneWidget);
        expect(find.byType(SecondarySelections), findsNothing);

        final size = getPrimarySelectionSize(tester);
        expect(size.width, equals(240.0));
        expect(size.height, equals(66.0));
      });
      testWidgets('override', (tester) async {
        AxisDirection? direction;
        await tester.pumpWidget(
          Actions(
            actions: {
              ExpandSelectionIntent: CallbackAction<ExpandSelectionIntent>(
                onInvoke: (intent) {
                  direction = intent.direction;
                  return null;
                },
              ),
            },
            child: TestSwayzeVictim(
              tables: [
                TestTableWrapper(
                  autofocus: true,
                  swayzeController: createSwayzeController(
                    tableDataController: createTableController(
                      tableColumnCount: 5,
                      tableRowCount: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(direction, AxisDirection.right);
      });
    });
    group('expand selection by block', () {
      testWidgets('default behavior', (tester) async {
        final swayzeController = createSwayzeController(
          tableDataController: createTableController(
            tableColumnCount: 10,
            tableRowCount: 10,
          ),
        );

        swayzeController.cellsController.updateState((modifier) {
          modifier.putCell(
            TestCellData(
              position: const IntVector2(0, 0),
              value: 'Table1 Cell 0,0',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(3, 0),
              value: 'Table1 Cell 0,3',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(4, 0),
              value: 'Table1 Cell 0,3',
            ),
          );
          modifier.putCell(
            TestCellData(
              position: const IntVector2(5, 0),
              value: 'Table1 Cell 0,3',
            ),
          );
        });

        await tester.pumpWidget(
          TestSwayzeVictim(
            tables: [
              TestTableWrapper(
                autofocus: true,
                swayzeController: swayzeController,
              ),
            ],
          ),
        );

        // wait for autofocus to kick in...
        await tester.pump(const Duration(milliseconds: 50));

        // Start on 0,0
        expect(
          getActiveCellOffset(tester),
          getCellOffset(tester, column: 0, row: 0),
        );

        // Go to block right - 3, 0
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(getPrimarySelectionSize(tester), const Size(480, 33));

        // Go to block right - 5, 0
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(getPrimarySelectionSize(tester), const Size(720, 33));

        // Go to block down - 5, 9
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(getPrimarySelectionSize(tester), const Size(720, 33 * 10));

        // Go to block left - 0, 9
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(getPrimarySelectionSize(tester), const Size(120, 33 * 10));
      });
      testWidgets('override', (tester) async {
        AxisDirection? direction;
        await tester.pumpWidget(
          Actions(
            actions: {
              ExpandSelectionByBlockIntent:
                  CallbackAction<ExpandSelectionByBlockIntent>(
                onInvoke: (intent) {
                  direction = intent.direction;
                  return null;
                },
              ),
            },
            child: TestSwayzeVictim(
              tables: [
                TestTableWrapper(
                  autofocus: true,
                  swayzeController: createSwayzeController(
                    tableDataController: createTableController(
                      tableColumnCount: 10,
                      tableRowCount: 10,
                    ),
                    cellsController: createCellsController(
                      cells: [
                        TestCellData(
                          position: const IntVector2(0, 0),
                          value: 'Table1 Cell 0,0',
                        ),
                        TestCellData(
                          position: const IntVector2(3, 0),
                          value: 'Table1 Cell 0,3',
                        ),
                        TestCellData(
                          position: const IntVector2(4, 0),
                          value: 'Table1 Cell 0,3',
                        ),
                        TestCellData(
                          position: const IntVector2(5, 0),
                          value: 'Table1 Cell 0,3',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // wait for autofocus to kick in...
        await tester.pump(const Duration(milliseconds: 50));

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(direction, AxisDirection.right);
      });
    });
    group('mouse table body selection', () {
      testWidgets('override', (tester) async {
        final verticalScrollController = ScrollController();

        IntVector2? startPosition;
        IntVector2? updatePosition;

        await tester.pumpWidget(
          Actions(
            actions: {
              TableBodySelectionStartIntent:
                  CallbackAction<TableBodySelectionStartIntent>(
                onInvoke: (intent) {
                  startPosition = intent.cellCoordinate;
                  return null;
                },
              ),
              TableBodySelectionUpdateIntent:
                  CallbackAction<TableBodySelectionUpdateIntent>(
                onInvoke: (intent) {
                  updatePosition = intent.cellCoordinate;
                  return null;
                },
              ),
            },
            child: TestSwayzeVictim(
              verticalScrollController: verticalScrollController,
              tables: [
                TestTableWrapper(
                  verticalScrollController: verticalScrollController,
                  swayzeController: createSwayzeController(
                    tableDataController: createTableController(
                      tableColumnCount: 5,
                      tableRowCount: 5,
                    ),
                  ),
                ),
                TestTableWrapper(
                  verticalScrollController: verticalScrollController,
                  swayzeController: createSwayzeController(
                    tableDataController: createTableController(
                      tableColumnCount: 5,
                      tableRowCount: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final from = getCellOffset(tester, column: 1, row: 1);
        final to = getCellOffset(tester, column: 2, row: 2);

        await tester.timedDragFrom(
          from,
          to - from,
          const Duration(milliseconds: 300),
        );
        await tester.pumpAndSettle();
        expect(startPosition, const IntVector2(1, 1));
        expect(updatePosition, const IntVector2(2, 2));
      });
    });
    group('mouse header selection', () {
      testWidgets('override', (tester) async {
        int? startPosition;
        int? updatePosition;

        await tester.pumpWidget(
          Actions(
            actions: {
              HeaderSelectionStartIntent:
                  CallbackAction<HeaderSelectionStartIntent>(
                onInvoke: (intent) {
                  startPosition = intent.header;
                  return null;
                },
              ),
              HeaderSelectionUpdateIntent:
                  CallbackAction<HeaderSelectionUpdateIntent>(
                onInvoke: (intent) {
                  updatePosition = intent.header;
                  return null;
                },
              ),
            },
            child: TestSwayzeVictim(
              tables: [
                TestTableWrapper(
                  swayzeController: createSwayzeController(
                    tableDataController: createTableController(
                      tableColumnCount: 5,
                      tableRowCount: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        final columnHeaders = find.descendant(
          of: find.byType(Header).at(0),
          matching: find.byType(HeaderItem),
        );

        final from = tester.getCenter(columnHeaders.at(1));
        final to = tester.getCenter(columnHeaders.at(3));

        await tester.timedDragFrom(
          from,
          to - from,
          const Duration(milliseconds: 500),
        );

        await tester.pumpAndSettle();
        expect(startPosition, 1);
        expect(updatePosition, 3);
      });
    });
  });
}
