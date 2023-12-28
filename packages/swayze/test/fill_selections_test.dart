import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/src/core/config/config.dart';
import 'package:swayze/src/core/intents/intents.dart';
import 'package:swayze/src/widgets/table_body/selections/fill_selections/fill_selection.dart';
import 'package:swayze_math/swayze_math.dart';

import 'test_utils/create_cells_controller.dart';
import 'test_utils/create_swayze_controller.dart';
import 'test_utils/create_table_data.dart';
import 'test_utils/create_test_victim.dart';
import 'test_utils/fonts.dart';
import 'test_utils/get_cell_offset.dart';
import 'test_utils/widget_tester_extension.dart';

void main() async {
  await loadFonts();

  _testFillUnknown();

  group(
    'Fill Target Selection',
    () {
      _testFillTarget(
        'Vertical Positive',
        startCell: const IntVector2(1, 1),
        endCell: const IntVector2(4, 4),
        targetRange: Range2D.fromPoints(
          const IntVector2(1, 1),
          const IntVector2(2, 5),
        ),
        goldenNameStart: 'fill_selection_single_cell_handle',
        goldenNameOngoing: 'fill_selection_vertical_positive_ongoing',
        goldenNameEnd: 'fill_selection_vertical_positive_end',
      );

      _testFillTarget(
        'Vertical Negative',
        startCell: const IntVector2(1, 2),
        endCell: const IntVector2(3, 0),
        targetRange: Range2D.fromPoints(
          const IntVector2(1, 0),
          const IntVector2(2, 3),
        ),
      );

      _testFillTarget(
        'Horizontal Positive',
        startCell: const IntVector2(1, 1),
        endCell: const IntVector2(4, 3),
        targetRange: Range2D.fromPoints(
          const IntVector2(1, 1),
          const IntVector2(5, 2),
        ),
      );

      _testFillTarget(
        'Horizontal Negative',
        startCell: const IntVector2(2, 2),
        endCell: const IntVector2(0, 3),
        targetRange: Range2D.fromPoints(
          const IntVector2(0, 2),
          const IntVector2(3, 3),
        ),
      );
    },
  );
}

Future<void> _createTable(
  WidgetTester tester, {
  Map<Type, Action<Intent>> actions = const {},
}) {
  tester.binding.window.physicalSizeTestValue = const Size(1024, 1024);
  tester.binding.window.devicePixelRatioTestValue = 1.0;

  // resets the screen to its original size after the test end
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

  final verticalScrollController = ScrollController();

  return tester.pumpWidget(
    Actions(
      actions: actions,
      child: TestSwayzeVictim(
        verticalScrollController: verticalScrollController,
        tables: [
          TestTableWrapper(
            config: const SwayzeConfig(
              isDragFillEnabled: true,
            ),
            autofocus: true,
            verticalScrollController: verticalScrollController,
            swayzeController: createSwayzeController(
              tableDataController: createTableController(
                tableColumnCount: 5,
                tableRowCount: 5,
              ),
              cellsController: createCellsController(
                cells: List.generate(
                  16,
                  (index) {
                    final column = (index / 4).floor();
                    final row = (index % 4).floor();

                    return TestCellData(
                      position: IntVector2(column, row),
                      value: 'Table1 Cell $column,$row',
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _testFillTarget(
  String description, {
  required IntVector2 startCell,
  required IntVector2 endCell,
  required Range2D targetRange,
  String? goldenNameStart,
  String? goldenNameOngoing,
  String? goldenNameEnd,
}) {
  testWidgets(
    description,
    (WidgetTester tester) async {
      Range2D? fillSource;
      Range2D? fillTarget;

      await _createTable(
        tester,
        actions: {
          FillIntoTargetIntent: CallbackAction<FillIntoTargetIntent>(
            onInvoke: (intent) {
              fillSource = Range2D.fromPoints(
                intent.source.leftTop,
                intent.source.rightBottom,
              );
              fillTarget = Range2D.fromPoints(
                intent.target.leftTop,
                intent.target.rightBottom,
              );

              return null;
            },
          ),
        },
      );

      final startRange = Range2D.fromLTWH(startCell, const IntVector2(1, 1));
      final endRange = Range2D.fromLTWH(endCell, const IntVector2(1, 1));

      final startOffset = startRange.startOffset(tester);
      final handlerOffset = startOffset.toHandlerOffset(
        tester,
        endOffset: startRange.endOffset(tester),
      );

      await tester.tapAt(startOffset);

      // Pump and wait a bit so that the double tap isn't triggered.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.byType(FillSelection),
        findsNothing,
        reason: 'Should not show a fill selection before drag',
      );

      if (goldenNameStart != null) {
        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/$goldenNameStart.png'),
        );
      }

      final gesture = await tester.startGesture(
        handlerOffset,
        kind: PointerDeviceKind.mouse,
      );

      // Move far away and then move back so that the drag registers on the test
      await gesture.moveTo(
        const Offset(1000.0, 1000.0),
        timeStamp: const Duration(seconds: 2),
      );

      await gesture.moveTo(
        endRange.startOffset(tester),
        timeStamp: const Duration(seconds: 4),
      );

      await tester.pumpAndSettle(
        const Duration(seconds: 6),
      );

      expect(
        find.byType(FillSelection),
        findsOneWidget,
        reason: 'Should show a fill selection during drag',
      );

      if (goldenNameOngoing != null) {
        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/$goldenNameOngoing.png'),
        );
      }

      await gesture.up(
        timeStamp: const Duration(seconds: 8),
      );
      await gesture.removePointer();

      await tester.pumpAndSettle(
        const Duration(seconds: 10),
      );

      if (goldenNameEnd != null) {
        await expectLater(
          find.byType(TestSwayzeVictim),
          matchesGoldenFile('goldens/$goldenNameEnd.png'),
        );
      }

      expect(
        fillSource,
        startRange,
        reason: 'Should call FillIntoTargetIntent with correct source range.',
      );

      expect(
        fillTarget,
        targetRange,
        reason: 'Should call FillIntoTargetIntent with correct target range.',
      );
    },
  );
}

void _testFillUnknown() {
  testWidgets(
    'Fill Unknown Selection',
    (WidgetTester tester) async {
      Range2D? fillSource;

      await _createTable(
        tester,
        actions: {
          FillIntoUnknownIntent: CallbackAction<FillIntoUnknownIntent>(
            onInvoke: (intent) {
              fillSource = Range2D.fromPoints(
                intent.source.leftTop,
                intent.source.rightBottom,
              );

              return null;
            },
          ),
        },
      );

      const rangeStart = IntVector2(1, 1);
      const rangeEnd = IntVector2(1, 3);

      final startOffset = getCellOffset(
        tester,
        column: rangeStart.dx,
        row: rangeStart.dy,
      );
      final endOffset = getCellOffset(
        tester,
        column: rangeEnd.dx,
        row: rangeEnd.dy,
      );

      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        startOffset,
        kind: PointerDeviceKind.mouse,
      );

      // Move far away and then move back so that the drag registers on the test
      await gesture.moveTo(
        const Offset(1000.0, 1000.0),
        timeStamp: const Duration(seconds: 2),
      );

      await gesture.moveTo(
        endOffset,
        timeStamp: const Duration(seconds: 4),
      );

      await tester.pumpAndSettle(
        const Duration(seconds: 6),
      );

      await gesture.up(
        timeStamp: const Duration(seconds: 8),
      );

      await gesture.removePointer();

      await tester.pumpAndSettle(
        const Duration(seconds: 10),
      );

      await expectLater(
        find.byType(TestSwayzeVictim),
        matchesGoldenFile('goldens/fill_selection_multiple_cells_handle.png'),
      );

      final handlerOffset = endOffset.toHandlerOffset(
        tester,
        endOffset: getCellOffset(
          tester,
          column: rangeEnd.dx + 1,
          row: rangeEnd.dy + 1,
        ),
      );

      await tester.doubleTapAt(handlerOffset);

      expect(
        fillSource,
        Range2D.fromPoints(
          rangeStart,
          rangeEnd + const IntVector2.symmetric(1),
        ),
        reason: 'Should call FillIntoUnknownIntent with correct source range.',
      );
    },
  );
}

extension on Range2D {
  Offset startOffset(WidgetTester tester) => getCellOffset(
        tester,
        column: leftTop.dx,
        row: leftTop.dy,
      );

  Offset endOffset(WidgetTester tester) => getCellOffset(
        tester,
        column: rightBottom.dx,
        row: rightBottom.dy,
      );
}

extension on Offset {
  Offset toHandlerOffset(
    WidgetTester tester, {
    required Offset endOffset,
  }) =>
      translate(
        (endOffset.dx - dx) / 2 - 1.0,
        (endOffset.dy - dy) / 2 - 1.0,
      );
}
