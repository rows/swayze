import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/src/widgets/headers/header.dart';
import 'package:swayze/src/widgets/headers/header_item.dart';
import 'package:swayze/src/widgets/table_body/selections/primary_selection/primary_selection.dart';
import 'package:swayze/src/widgets/table_body/selections/secondary_selections/secondary_selections.dart';
import 'package:swayze_math/swayze_math.dart';

import 'test_utils/create_swayze_controller.dart';
import 'test_utils/create_table_data.dart';
import 'test_utils/create_test_victim.dart';
import 'test_utils/fonts.dart';

void main() async {
  await loadFonts();

  testWidgets(
    'should be able to create a mouse header selection spanning through '
    'multiple columns with shift click',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TestSwayzeVictim(
          tables: [
            TestTableWrapper(
              swayzeController: createSwayzeController(
                tableDataController: createTableController(
                  tableColumnCount: 5,
                  tableRowCount: 5,
                  frozenColumns: 1,
                  frozenRows: 1,
                ),
              ),
            ),
          ],
        ),
      );
      final columnHeaders = find.descendant(
        of: find.byType(Header).first,
        matching: find.byType(HeaderItem),
      );

      // Click column B
      await tester.tapAt(tester.getCenter(columnHeaders.at(1)));
      await tester.pumpAndSettle();

      // Press shift and click column D
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.tapAt(tester.getCenter(columnHeaders.at(3)));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/selection-header.png'),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    },
  );

  testWidgets(
    'should be able to create a mouse header selection spanning through '
    'multiple columns with mouse drag',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TestSwayzeVictim(
          tables: [
            TestTableWrapper(
              swayzeController: createSwayzeController(
                tableDataController: createTableController(
                  tableColumnCount: 5,
                  tableRowCount: 10,
                  frozenColumns: 1,
                  frozenRows: 1,
                ),
              ),
            ),
          ],
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
      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/drag-selection-header.png'),
      );
    },
  );

  testWidgets(
    'should expand selection with keyboard in the same axis of current '
    'header selection',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TestSwayzeVictim(
          tables: [
            TestTableWrapper(
              swayzeController: createSwayzeController(
                tableDataController: createTableController(
                  tableColumnCount: 10,
                  tableRowCount: 5,
                  frozenColumns: 1,
                  frozenRows: 1,
                ),
              ),
            ),
          ],
        ),
      );
      final columnHeaders = find.descendant(
        of: find.byType(Header).first,
        matching: find.byType(HeaderItem),
      );

      expect(find.byType(PrimarySelection), findsNothing);
      expect(find.byType(SecondarySelections), findsNothing);

      await tester.tapAt(tester.getCenter(columnHeaders.at(2)));
      await tester.pumpAndSettle();

      var selection = find.descendant(
        of: find.byType(PrimarySelection).first,
        matching: find.byType(PrimarySelectionPainter),
      );

      var primarySelectionPainter =
          selection.evaluate().first.widget as PrimarySelectionPainter;

      expect(primarySelectionPainter.size.width, 120);
      expect(
        tester.getTopLeft(selection).dx + primarySelectionPainter.offset.dx,
        tester.getTopLeft(columnHeaders.at(2)).dx,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      selection = find.descendant(
        of: find.byType(PrimarySelection).first,
        matching: find.byType(PrimarySelectionPainter),
      );
      primarySelectionPainter =
          selection.evaluate().first.widget as PrimarySelectionPainter;

      expect(primarySelectionPainter.size.width, 240);
      expect(
        tester.getTopLeft(selection).dx + primarySelectionPainter.offset.dx,
        tester.getTopLeft(columnHeaders.at(2)).dx,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      selection = find.descendant(
        of: find.byType(PrimarySelection).first,
        matching: find.byType(PrimarySelectionPainter),
      );
      primarySelectionPainter =
          selection.evaluate().first.widget as PrimarySelectionPainter;

      expect(tester.getSize(selection).width, 240);
      expect(
        tester.getTopLeft(selection).dx + primarySelectionPainter.offset.dx,
        tester.getTopLeft(columnHeaders.at(1)).dx,
      );
    },
  );

  testWidgets(
    'should ignore selection expansion with keyboard if keys direction do '
    "not match the selection's axis",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        TestSwayzeVictim(
          tables: [
            TestTableWrapper(
              swayzeController: createSwayzeController(
                tableDataController: createTableController(
                  tableColumnCount: 10,
                  tableRowCount: 5,
                  frozenColumns: 1,
                  frozenRows: 1,
                ),
              ),
            ),
          ],
        ),
      );
      final columnHeaders = find.descendant(
        of: find.byType(Header).first,
        matching: find.byType(HeaderItem),
      );

      await tester.tapAt(tester.getCenter(columnHeaders.at(2)));
      await tester.pumpAndSettle();

      var selection = find.descendant(
        of: find.byType(PrimarySelection).first,
        matching: find.byType(PrimarySelectionPainter),
      );
      var primarySelectionPainter =
          selection.evaluate().first.widget as PrimarySelectionPainter;

      final initialSize = primarySelectionPainter.size;

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      selection = find.descendant(
        of: find.byType(PrimarySelection).first,
        matching: find.byType(PrimarySelectionPainter),
      );
      primarySelectionPainter =
          selection.evaluate().first.widget as PrimarySelectionPainter;

      final finalSize = primarySelectionPainter.size;

      expect(initialSize, equals(finalSize));
    },
  );

  group('Frozen columns/rows', () {
    testWidgets(
        'should be able to create a mouse header selection spanning through '
        'multiple columns with mouse drag', (WidgetTester tester) async {
      final verticalScrollController = ScrollController();
      final SwayzeController controller;
      await tester.pumpWidget(
        TestSwayzeVictim(
          verticalScrollController: verticalScrollController,
          tables: [
            TestTableWrapper(
              verticalScrollController: verticalScrollController,
              swayzeController: controller = createSwayzeController(
                tableDataController: createTableController(
                  tableColumnCount: 6,
                  tableRowCount: 50,
                  frozenColumns: 2,
                  frozenRows: 2,
                ),
              ),
            ),
          ],
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

      controller.scroll.jumpToCoordinate(
        const IntVector2(0, 30),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/drag-selection-header-frozen.png'),
      );
    });
  });
}
