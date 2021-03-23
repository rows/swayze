import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/src/widgets/headers/header.dart';
import 'package:swayze/src/widgets/headers/header_item.dart';
import 'package:swayze_math/swayze_math.dart';

import 'test_utils/create_cells_controller.dart';
import 'test_utils/create_swayze_controller.dart';
import 'test_utils/create_table_data.dart';
import 'test_utils/create_test_victim.dart';
import 'test_utils/fonts.dart';

void main() async {
  await loadFonts();

  group('with mouse', () {
    testWidgets(
      'should be able to scroll a long table',
      (WidgetTester tester) async {
        final verticalScrollController = ScrollController();
        final tables = [
          TestTableWrapper(
            verticalScrollController: verticalScrollController,
            swayzeController: createSwayzeController(
              cellsController: createCellsController(
                cells: <TestCellData>[
                  TestCellData(
                    position: const IntVector2(0, 30),
                    value: '0, 30',
                  ),
                  TestCellData(
                    position: const IntVector2(1, 30),
                    value: '1, 30',
                  ),
                  TestCellData(
                    position: const IntVector2(2, 30),
                    value: '2, 30',
                  ),
                  TestCellData(
                    position: const IntVector2(3, 30),
                    value: '3, 30',
                  ),
                  TestCellData(
                    position: const IntVector2(8, 30),
                    value: '8, 30',
                  ),
                  TestCellData(
                    position: const IntVector2(9, 30),
                    value: '9, 30',
                  ),
                  TestCellData(
                    position: const IntVector2(10, 30),
                    value: '10, 30',
                  ),
                  TestCellData(
                    position: const IntVector2(11, 30),
                    value: '11, 30',
                  ),
                ],
              ),
              tableDataController: createTableController(
                id: 'TestTableKey1',
                tableRowCount: 1000,
                tableColumnCount: 1000,
              ),
            ),
          ),
        ];
        await tester.pumpWidget(
          TestSwayzeVictim(
            verticalScrollController: verticalScrollController,
            tables: tables,
          ),
        );

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -750), // I guess this is because touch devices(??)
          100,
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/scroll-long-tables-vertical.png'),
        );

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(-750, 0), // I guess this is because touch devices(??)
          100,
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/scroll-long-tables-horizontal.png'),
        );
      },
    );

    testWidgets(
      'should be able to scroll vertically to see other tables',
      (WidgetTester tester) async {
        final verticalScrollController = ScrollController();
        final tables = [
          TestTableWrapper(
            key: const ValueKey('TestTableKey1'),
            verticalScrollController: verticalScrollController,
            swayzeController: createSwayzeController(
              cellsController: createCellsController(
                cells: [
                  TestCellData(
                    position: const IntVector2(0, 0),
                    value: 'Table1 Cell 0,0',
                  ),
                ],
              ),
              tableDataController: createTableController(
                id: 'TestTableKey1',
                tableRowCount: 12,
              ),
            ),
          ),
          TestTableWrapper(
            key: const ValueKey('TestTableKey2'),
            verticalScrollController: verticalScrollController,
            swayzeController: createSwayzeController(
              cellsController: createCellsController(
                cells: [
                  TestCellData(
                    position: const IntVector2(0, 0),
                    value: 'Table2 Cell 0,0',
                  ),
                ],
              ),
              tableDataController: createTableController(
                id: '2',
                tableRowCount: 12,
              ),
            ),
          ),
          TestTableWrapper(
            key: const ValueKey('TestTableKey3'),
            verticalScrollController: verticalScrollController,
            swayzeController: createSwayzeController(
              cellsController: createCellsController(
                cells: [
                  TestCellData(
                    position: const IntVector2(0, 0),
                    value: 'Table3 Cell 0,0',
                  ),
                ],
              ),
              tableDataController: createTableController(
                id: '3',
                tableRowCount: 12,
              ),
            ),
          ),
        ];
        await tester.pumpWidget(
          TestSwayzeVictim(
            tables: tables,
            verticalScrollController: verticalScrollController,
          ),
        );
        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/multiple-tables-1.png'),
        );

        expect(
          find.byKey(const ValueKey('TestTableKey1')),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey('TestTableKey2')),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey('TestTableKey3')),
          findsNothing,
        );

        await tester.fling(
          find.byType(CustomScrollView).first,
          const Offset(0, -450), // I guess this is because touch devices(??)
          120,
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('TestTableKey1')),
          findsNothing,
        );

        expect(
          find.byKey(const ValueKey('TestTableKey2')),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey('TestTableKey3')),
          findsOneWidget,
        );

        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/multiple-tables-2.png'),
        );
      },
    );
  });

  group('with keyboard', () {
    testWidgets(
      'should be able to scroll table when active cell moves out of viewport',
      (WidgetTester tester) async {
        final verticalScrollController = ScrollController();
        await tester.pumpWidget(
          TestSwayzeVictim(
            verticalScrollController: verticalScrollController,
            tables: [
              TestTableWrapper(
                verticalScrollController: verticalScrollController,
                autofocus: true,
                swayzeController: createSwayzeController(
                  tableDataController: createTableController(
                    tableColumnCount: 26,
                    tableRowCount: 50,
                  ),
                ),
              ),
            ],
          ),
        );

        expect(find.bySemanticsLabel('1'), findsOneWidget);
        expect(find.bySemanticsLabel('19'), findsNothing);

        final target = tester.getCenter(
          find.descendant(
            of: find.byType(Header).last,
            matching: find.byType(HeaderItem).last,
          ),
        );

        // click on last visible row:
        await tester.tapAt(Offset(target.dx + 26, target.dy - 26));
        await tester.pumpAndSettle();

        // Move 3 coordinates vertically
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('1'), findsNothing);
        expect(find.bySemanticsLabel('19'), findsOneWidget);

        // Move to the top with block navigation
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('1'), findsOneWidget);
        expect(find.bySemanticsLabel('19'), findsNothing);

        expect(find.bySemanticsLabel('A'), findsOneWidget);
        expect(find.bySemanticsLabel('Z'), findsNothing);

        // Move to the right with block navigation
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('A'), findsNothing);
        expect(find.bySemanticsLabel('Z'), findsOneWidget);
      },
    );

    testWidgets(
      'should be able to scroll table when selection moves out of viewport',
      (WidgetTester tester) async {
        final verticalScrollController = ScrollController();
        await tester.pumpWidget(
          TestSwayzeVictim(
            verticalScrollController: verticalScrollController,
            tables: [
              TestTableWrapper(
                verticalScrollController: verticalScrollController,
                autofocus: true,
                swayzeController: createSwayzeController(
                  tableDataController: createTableController(
                    tableColumnCount: 26,
                    tableRowCount: 50,
                  ),
                ),
              ),
            ],
          ),
        );

        expect(find.bySemanticsLabel('1'), findsOneWidget);
        expect(find.bySemanticsLabel('19'), findsNothing);

        final target = tester.getCenter(
          find.descendant(
            of: find.byType(Header).last,
            matching: find.byType(HeaderItem).last,
          ),
        );

        // click on last visible row:
        await tester.tapAt(Offset(target.dx + 26, target.dy - 26));
        await tester.pumpAndSettle();

        // Move 3 coordinates vertically
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('1'), findsNothing);
        expect(find.bySemanticsLabel('19'), findsOneWidget);

        // Move to the top with block navigation
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('1'), findsOneWidget);
        expect(find.bySemanticsLabel('19'), findsNothing);

        expect(find.bySemanticsLabel('A'), findsOneWidget);
        expect(find.bySemanticsLabel('Z'), findsNothing);

        // Move to the right with block navigation
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('A'), findsNothing);
        expect(find.bySemanticsLabel('Z'), findsOneWidget);
      },
    );
  });
}
