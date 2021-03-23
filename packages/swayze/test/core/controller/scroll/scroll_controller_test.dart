import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../test_utils/create_cells_controller.dart';
import '../../../test_utils/create_swayze_controller.dart';
import '../../../test_utils/create_table_data.dart';
import '../../../test_utils/create_test_victim.dart';
import '../../../test_utils/fonts.dart';
import '../../../test_utils/get_cell_offset.dart';

TestSwayzeVictim _createTables(SwayzeController swayzeTable2Controller) {
  final verticalScrollController = ScrollController();
  final table1 = TestTableWrapper(
    verticalScrollController: verticalScrollController,
    swayzeController: createSwayzeController(
      cellsController: createCellsController(),
      tableDataController: createTableController(
        id: 'TestTableKey1',
        tableRowCount: 10,
        tableColumnCount: 5,
      ),
    ),
  );

  final table2 = TestTableWrapper(
    verticalScrollController: verticalScrollController,
    swayzeController: swayzeTable2Controller,
  );

  return TestSwayzeVictim(
    verticalScrollController: verticalScrollController,
    tables: [table1, table2],
  );
}

void main() async {
  await loadFonts();

  group('golden tests', () {
    late SwayzeController swayzeTable2Controller;
    late TestSwayzeVictim swayzeVictim;
    setUp(() {
      swayzeTable2Controller = createSwayzeController(
        cellsController: createCellsController(),
        tableDataController: createTableController(
          id: 'TestTableKey2',
          tableRowCount: 100,
          tableColumnCount: 100,
          frozenColumns: 1,
          frozenRows: 1,
          customColumnSizes: {
            1: 200,
            2: 200,
            50: 200,
          },
          customRowSizes: {
            1: 200,
            2: 200,
            50: 200,
          },
        ),
      );

      swayzeVictim = _createTables(swayzeTable2Controller);
    });

    group('leading edge', () {
      group('visible', () {
        testWidgets(
          'header-leading-visible-horizontal',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 1, row: 1, tableIndex: 1),
            );

            // make scroll show index 1 partially
            swayzeTable2Controller.scroll.horizontalScrollController!
                .jumpTo(175);

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(1, Axis.horizontal);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile(
                'goldens/header-leading-visible-horizontal.png',
              ),
            );
          },
        );
        testWidgets(
          'header-leading-visible-vertical',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 1, row: 1, tableIndex: 1),
            );

            // make scroll show index 1 partially
            swayzeTable2Controller.scroll.verticalScrollController!.jumpTo(400);

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(1, Axis.vertical);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile('goldens/header-leading-visible-vertical.png'),
            );
          },
        );
        testWidgets(
          'cell-leading-visible',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 1, row: 1, tableIndex: 1),
            );

            // make scroll show index 1 partially
            swayzeTable2Controller.scroll.verticalScrollController!.jumpTo(475);
            swayzeTable2Controller.scroll.horizontalScrollController!
                .jumpTo(175);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile('goldens/cell-leading-visible-before.png'),
            );

            swayzeTable2Controller.scroll.jumpToCoordinate(
              const IntVector2.symmetric(1),
            );

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile('goldens/cell-leading-visible.png'),
            );
          },
        );
      });
      group('offscreen', () {
        testWidgets(
          'header-leading-offscreen-horizontal',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 1, row: 1, tableIndex: 1),
            );

            // make header index 1 be out of the viewport
            swayzeTable2Controller.scroll.horizontalScrollController!
                .jumpTo(2000);

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(1, Axis.horizontal);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile(
                'goldens/header-leading-offscreen-horizontal.png',
              ),
            );
          },
        );
        testWidgets(
          'header-leading-offscreen-vertical',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 1, row: 1, tableIndex: 1),
            );

            // make header index 1  be out of the viewport
            swayzeTable2Controller.scroll.verticalScrollController!
                .jumpTo(2000);

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(1, Axis.vertical);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile(
                'goldens/header-leading-offscreen-vertical.png',
              ),
            );
          },
        );
        testWidgets(
          'cell-leading-offscreen',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 1, row: 1, tableIndex: 1),
            );

            // make cell be out of the viewport
            swayzeTable2Controller.scroll.verticalScrollController!
                .jumpTo(2000);
            swayzeTable2Controller.scroll.horizontalScrollController!
                .jumpTo(2000);

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll
                .jumpToCoordinate(const IntVector2.symmetric(1));

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile('goldens/cell-leading-offscreen.png'),
            );
          },
        );
      });
    });

    group('trailing edge', () {
      group('visible', () {
        testWidgets(
          'header-trailing-visible-horizontal',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 0, row: 0, tableIndex: 1),
            );

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(5, Axis.horizontal);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile(
                'goldens/header-trailing-visible-horizontal.png',
              ),
            );
          },
        );
        testWidgets(
          'header-trailing-visible-vertical',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 0, row: 0, tableIndex: 1),
            );

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(5, Axis.vertical);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile('goldens/header-trailing-visible-vertical.png'),
            );
          },
        );
        testWidgets(
          'cell-trailing-visible',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 0, row: 0, tableIndex: 1),
            );

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll
                .jumpToCoordinate(const IntVector2.symmetric(5));

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile('goldens/cell-trailing-visible.png'),
            );
          },
        );
      });
      group('offscreen', () {
        testWidgets(
          'header-trailing-offscreen-horizontal',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 0, row: 0, tableIndex: 1),
            );

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(10, Axis.horizontal);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile(
                'goldens/header-trailing-offscreen-horizontal.png',
              ),
            );
          },
        );
        testWidgets(
          'header-trailing-offscreen-vertical',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 0, row: 0, tableIndex: 1),
            );

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll.jumpToHeader(10, Axis.vertical);

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile(
                'goldens/header-trailing-offscreen-vertical.png',
              ),
            );
          },
        );
        testWidgets(
          'cell-trailing-offscreen',
          (WidgetTester tester) async {
            await tester.pumpWidget(swayzeVictim);

            await tester.tapAt(
              getCellOffset(tester, column: 1, row: 1, tableIndex: 1),
            );

            await tester.pumpAndSettle();

            swayzeTable2Controller.scroll
                .jumpToCoordinate(const IntVector2.symmetric(10));

            await tester.pumpAndSettle();

            await expectLater(
              find.byType(TestSwayzeVictim),
              matchesGoldenFile('goldens/cell-trailing-offscreen.png'),
            );
          },
        );
      });
    });

    group('on screen', () {
      testWidgets(
        'on-screen-header',
        (WidgetTester tester) async {
          await tester.pumpWidget(swayzeVictim);

          await tester.tapAt(
            getCellOffset(tester, column: 0, row: 0, tableIndex: 1),
          );

          await tester.pumpAndSettle();

          swayzeTable2Controller.scroll.jumpToHeader(1, Axis.horizontal);

          await tester.pumpAndSettle();

          await expectLater(
            find.byType(TestSwayzeVictim),
            matchesGoldenFile('goldens/on-screen-header.png'),
          );
        },
      );
      testWidgets(
        'on-screen-cell',
        (WidgetTester tester) async {
          await tester.pumpWidget(swayzeVictim);

          swayzeTable2Controller.scroll.verticalScrollController!.jumpTo(100);

          await tester.tapAt(
            getCellOffset(tester, column: 0, row: 0, tableIndex: 1),
          );

          await tester.pumpAndSettle();

          await expectLater(
            find.byType(TestSwayzeVictim),
            matchesGoldenFile('goldens/on-screen-cell-before.png'),
          );

          await tester.pumpAndSettle();

          swayzeTable2Controller.scroll
              .jumpToCoordinate(const IntVector2.symmetric(2));
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(TestSwayzeVictim),
            matchesGoldenFile('goldens/on-screen-cell.png'),
          );
        },
      );
    });
  });
}
