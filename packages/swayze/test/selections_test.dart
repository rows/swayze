import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/src/widgets/table_body/selections/primary_selection/primary_selection.dart';
import 'package:swayze/src/widgets/table_body/selections/secondary_selections/secondary_selections.dart';
import 'package:swayze/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import 'test_utils/create_cells_controller.dart';
import 'test_utils/create_selection_controller.dart';
import 'test_utils/create_swayze_controller.dart';
import 'test_utils/create_table_data.dart';
import 'test_utils/create_test_victim.dart';
import 'test_utils/fonts.dart';
import 'test_utils/get_cell_offset.dart';
import 'test_utils/type_of.dart';

void main() async {
  await loadFonts();

  testWidgets(
    'should be able to create a mouse cell selection',
    (WidgetTester tester) async {
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

      final from = getCellOffset(tester, column: 1, row: 1);
      final to = getCellOffset(tester, column: 2, row: 2);

      // Note: this test is using touch interactions (as flutter, at this point
      // does not support configuration of PointerDeviceKind), which means that
      // if the table is big enough it will scroll instead of creating a
      // selection
      //
      // Ideally in this test we would also scroll and take a new screenshot
      // to make sure selections are beeing moved with the table
      await tester.timedDragFrom(
        from,
        to - from,
        const Duration(milliseconds: 300),
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/cells-selection.png'),
      );
    },
  );

  testWidgets(
    'should only show selections for the currently active table',
    (WidgetTester tester) async {
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

      // No table is focused, therefore no active cell
      expect(find.byType(PrimarySelection), findsNothing);
      expect(find.byType(SecondarySelections), findsNothing);

      // Create a selection on the second table
      await tester.tapAt(
        getCellOffset(tester, tableIndex: 1, column: 2, row: 2),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(typeOf<SliverSwayzeTable<TestCellData>>()).at(1),
          matching: find.byType(PrimarySelection),
        ),
        findsOneWidget,
      );

      // Click on the first table
      await tester.tapAt(
        getCellOffset(tester, column: 2, row: 2),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(typeOf<SliverSwayzeTable<TestCellData>>()).at(1),
          matching: find.byType(PrimarySelection),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('should show and update data selections',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1024, 1024);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    // resets the screen to its original size after the test end
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    final verticalScrollController = ScrollController();

    late final TestSwayzeSelectionController firstTableSelectionController;

    await tester.pumpWidget(
      TestSwayzeVictim(
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
              selectionController: firstTableSelectionController =
                  createSelectionsController(
                dataSelectionsValueListenable: TestDataSelectionNotifier(
                  <Selection>[
                    TestDataSelection(
                      left: 1,
                      top: 0,
                      right: 4,
                      bottom: 4,
                      color: const Color(0xFFFF0055),
                    ),
                    TestDataSelection(
                      top: 3,
                      left: 8,
                      right: 11,
                      color: const Color(0xFF00FFFF),
                    ),
                    TestDataSelection(
                      top: 6,
                      bottom: 8,
                      color: const Color(0xFF00FF00),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TestTableWrapper(
            verticalScrollController: verticalScrollController,
            swayzeController: createSwayzeController(
              tableDataController: createTableController(
                tableColumnCount: 15,
                tableRowCount: 15,
              ),
              selectionController: createSelectionsController(
                dataSelectionsValueListenable: TestDataSelectionNotifier(
                  <TestDataSelection>[
                    TestDataSelection(
                      top: 6,
                      bottom: 8,
                      color: const Color(0xFF00FF00),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TestTableWrapper(
            verticalScrollController: verticalScrollController,
            swayzeController: createSwayzeController(
              tableDataController: createTableController(
                tableColumnCount: 10,
                tableRowCount: 25,
              ),
              selectionController: createSelectionsController(
                dataSelectionsValueListenable: TestDataSelectionNotifier(
                  <TestDataSelection>[
                    TestDataSelection(
                      top: 1,
                      right: 4,
                      bottom: 28,
                      color: const Color(0xFF00FF00),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TestSwayzeVictim),
      matchesGoldenFile('goldens/cells-data-selection.png'),
    );

    firstTableSelectionController.dataSelectionsValueListenable.value =
        BuiltList.from(
      <TestDataSelection>[
        TestDataSelection(
          top: 1,
          left: 4,
          bottom: 10,
          color: const Color(0xFF70afc0),
        ),
      ],
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TestSwayzeVictim),
      matchesGoldenFile('goldens/cells-data-selection-2.png'),
    );
  });
}
