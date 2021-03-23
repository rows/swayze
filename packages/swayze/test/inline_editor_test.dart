import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import 'test_utils/create_cells_controller.dart';
import 'test_utils/create_swayze_controller.dart';
import 'test_utils/create_table_data.dart';
import 'test_utils/create_test_victim.dart';
import 'test_utils/fonts.dart';
import 'test_utils/get_cell_offset.dart';

Widget _testCellEditorBuilder(
  BuildContext context,
  IntVector2 coordinate,
  VoidCallback close, {
  required bool overlapCell,
  required bool overlapTable,
  String? initialText,
}) {
  return _TestInlineEditor(
    coordinate: coordinate,
    close: close,
    overlapCell: overlapCell,
    overlapTable: overlapTable,
    initialText: initialText,
  );
}

class _TestInlineEditor extends StatelessWidget {
  final IntVector2 coordinate;
  final VoidCallback close;
  final bool overlapCell;
  final bool overlapTable;
  final String? initialText;

  const _TestInlineEditor({
    Key? key,
    required this.coordinate,
    required this.close,
    required this.overlapCell,
    required this.overlapTable,
    this.initialText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF000000),
        fontFamily: 'normal',
      ),
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text('$overlapCell - $overlapTable - $coordinate - $initialText'),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _createInlineEditorVictim([
  InlineEditorBuilder? editorBuilder = _testCellEditorBuilder,
]) {
  final verticalScrollController = ScrollController();
  return TestSwayzeVictim(
    verticalScrollController: verticalScrollController,
    tables: [
      TestTableWrapper(
        verticalScrollController: verticalScrollController,
        editorBuilder: editorBuilder,
        swayzeController: createSwayzeController(
          tableDataController: createTableController(
            tableColumnCount: 25,
            tableRowCount: 25,
            customColumnSizes: {3: 250},
            customRowSizes: {3: 100},
          ),
          cellsController: createCellsController(
            cells: [
              TestCellData(
                position: const IntVector2(2, 2),
                value: 'I am a cell to the left',
              ),
              TestCellData(
                position: const IntVector2(2, 3),
                value: 'I am a cell to the center',
                contentAlignment: Alignment.center,
              ),
              TestCellData(
                position: const IntVector2(2, 4),
                value: 'I am a cell to the right',
                contentAlignment: Alignment.centerRight,
              ),
              TestCellData(
                position: const IntVector2(3, 3),
                value: 'I am another cell',
              ),
            ],
          ),
        ),
      ),
      TestTableWrapper(
        verticalScrollController: verticalScrollController,
        swayzeController: createSwayzeController(
          tableDataController: createTableController(
            tableColumnCount: 25,
            tableRowCount: 25,
          ),
        ),
      ),
    ],
  );
}

Future<void> doubleTapOnCell(
  WidgetTester tester, {
  required int column,
  required int row,
}) async {
  final cellOffset = getCellOffset(tester, column: column, row: row);
  // double tap
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pumpAndSettle();
  await gesture.down(cellOffset);
  await gesture.up();
  await tester.pump(kDoubleTapMinTime);
  await gesture.down(cellOffset);
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> scrollBy(
  WidgetTester tester, {
  required Offset offset,
}) async {
  // scroll
  final testPointer = TestPointer(1, PointerDeviceKind.mouse);
  testPointer.hover(tester.getCenter(find.byType(TestSwayzeVictim)));
  await tester.sendEventToBinding(
    testPointer.scroll(offset),
  );
  await tester.pumpAndSettle();
}

void main() async {
  await loadFonts();

  testWidgets('should open for a cell', (tester) async {
    await tester.pumpWidget(_createInlineEditorVictim());

    await doubleTapOnCell(tester, column: 2, row: 2);

    final findsEditor = find.byType(_TestInlineEditor);

    expect(findsEditor, findsNWidgets(1));
  });

  testWidgets('should expect min size', (tester) async {
    await tester.pumpWidget(_createInlineEditorVictim());

    await doubleTapOnCell(tester, column: 3, row: 3);

    final findsEditor = find.byType(_TestInlineEditor);

    expect(findsEditor, findsNWidgets(1));

    await expectLater(
      find.byType(TestSwayzeVictim),
      matchesGoldenFile('goldens/inline-editor-min-size.png'),
    );
  });

  testWidgets(
    'should grow too the right in left aligned cells',
    (tester) async {
      await tester.pumpWidget(_createInlineEditorVictim());

      await doubleTapOnCell(tester, column: 2, row: 2);

      final findsEditor = find.byType(_TestInlineEditor);

      expect(findsEditor, findsNWidgets(1));

      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/inline-editor-left-aligned.png'),
      );
    },
  );

  testWidgets(
    'should grow too the right in center aligned cells',
    (tester) async {
      await tester.pumpWidget(_createInlineEditorVictim());

      await doubleTapOnCell(tester, column: 2, row: 3);

      final findsEditor = find.byType(_TestInlineEditor);

      expect(findsEditor, findsNWidgets(1));

      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/inline-editor-center-aligned.png'),
      );
    },
  );

  testWidgets(
    'should grow too the left in right aligned cells',
    (tester) async {
      await tester.pumpWidget(_createInlineEditorVictim());

      await doubleTapOnCell(tester, column: 2, row: 4);

      final findsEditor = find.byType(_TestInlineEditor);

      expect(findsEditor, findsNWidgets(1));

      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/inline-editor-right-aligned.png'),
      );
    },
  );

  testWidgets('should indicate non overlapping cells', (tester) async {
    await tester.pumpWidget(_createInlineEditorVictim());

    await doubleTapOnCell(tester, column: 2, row: 2);

    await scrollBy(tester, offset: const Offset(0.0, 100.0));

    await expectLater(
      find.byType(TestSwayzeVictim),
      matchesGoldenFile('goldens/inline-editor-overlap-cell.png'),
    );
  });

  testWidgets(
    'should indicate non overlapping table',
    (tester) async {
      await tester.pumpWidget(_createInlineEditorVictim());

      await doubleTapOnCell(tester, column: 2, row: 2);

      await scrollBy(tester, offset: const Offset(0.0, 880.0));

      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/inline-editor-overlap-table.png'),
      );
    },
  );
}
