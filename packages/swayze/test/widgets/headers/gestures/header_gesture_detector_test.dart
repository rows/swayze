import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/intents.dart';
import 'package:swayze/src/core/config/config.dart';
import 'package:swayze/src/widgets/default_actions/default_swayze_action.dart';
import 'package:swayze/src/widgets/headers/header.dart';
import 'package:swayze/src/widgets/headers/header_item.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../test_utils/create_swayze_controller.dart';
import '../../../test_utils/create_table_data.dart';
import '../../../test_utils/create_test_victim.dart';

class _MockAction<T extends SwayzeIntent> extends Mock
    implements DefaultSwayzeAction<T> {
  @override
  bool isEnabled(T intent) => true;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return super.toString();
  }
}

void main() {
  late _MockAction<HeaderDragEndIntent> dragEndAction;
  late _MockAction<HeaderDragCancelIntent> dragCancelAction;
  late TestSwayzeController swayzeController;

  setUp(() {
    dragEndAction = _MockAction<HeaderDragEndIntent>();
    dragCancelAction = _MockAction<HeaderDragCancelIntent>();
    swayzeController = createSwayzeController(
      tableDataController: createTableController(
        tableColumnCount: 10,
        tableRowCount: 10,
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(
      const HeaderDragEndIntent(
        header: 0,
        axis: Axis.horizontal,
      ),
    );
    registerFallbackValue(const HeaderDragCancelIntent(Axis.horizontal));
  });

  Future pumpTestWidget(WidgetTester tester) {
    final verticalScrollController = ScrollController();
    return tester.pumpWidget(
      Actions(
        actions: {
          HeaderDragEndIntent: dragEndAction,
          HeaderDragCancelIntent: dragCancelAction,
        },
        child: TestSwayzeVictim(
          verticalScrollController: verticalScrollController,
          tables: [
            TestTableWrapper(
              config: const SwayzeConfig(
                isHeaderDragAndDropEnabled: true,
              ),
              verticalScrollController: verticalScrollController,
              swayzeController: swayzeController,
            ),
          ],
        ),
      ),
    );
  }

  group('Header gesture detector', () {
    group('Drag and drop', () {
      testWidgets('Invokes HeaderDragEndIntent when a drag is completed',
          (tester) async {
        await pumpTestWidget(tester);

        final columnHeaders = tester.findColumnHeaders();

        await tester.shiftSelectHeaders(
          from: columnHeaders.at(1),
          to: columnHeaders.at(3),
        );

        final firstLocation = tester.getCenter(columnHeaders.at(2));
        final gesture = await tester.startGesture(
          firstLocation,
          pointer: 1,
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await tester.pump();

        final secondLocation = tester.getCenter(columnHeaders.at(3));
        await gesture.moveTo(secondLocation);
        await tester.pump();

        var dragState =
            swayzeController.tableDataController.columns.value.dragState;
        expect(dragState, isNotNull);
        expect(dragState!.headers, const Range(1, 4));
        expect(dragState.dropAtIndex, 1);
        expect(dragState.isDropAllowed, isFalse);

        final thirdLocation = tester.getCenter(columnHeaders.at(5));
        await gesture.moveTo(thirdLocation);
        await tester.pump();

        dragState =
            swayzeController.tableDataController.columns.value.dragState;
        expect(dragState, isNotNull);
        expect(dragState!.headers, const Range(1, 4));
        expect(dragState.dropAtIndex, 5);
        expect(dragState.isDropAllowed, isTrue);

        await gesture.up();
        await tester.pumpAndSettle();

        verifyNever(
          () => dragCancelAction.invoke(captureAny(), any()),
        );
        final captured = verify(
          () => dragEndAction.invoke(captureAny(), any()),
        ).captured;

        expect(captured, hasLength(1));

        final dragEndIntent = captured.first as HeaderDragEndIntent;
        expect(dragEndIntent.header, 5);
        expect(dragEndIntent.axis, Axis.horizontal);
      });

      testWidgets(
          'Invokes HeaderDragCancelIntent when dropping inside the '
          'dragging headers Range', (tester) async {
        await pumpTestWidget(tester);

        final columnHeaders = tester.findColumnHeaders();

        await tester.shiftSelectHeaders(
          from: columnHeaders.at(1),
          to: columnHeaders.at(3),
        );

        final firstLocation = tester.getCenter(columnHeaders.at(2));
        final gesture = await tester.startGesture(
          firstLocation,
          pointer: 1,
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await tester.pump();

        final secondLocation = tester.getCenter(columnHeaders.at(3));
        await gesture.moveTo(secondLocation);
        await tester.pump();

        var dragState =
            swayzeController.tableDataController.columns.value.dragState;
        expect(dragState, isNotNull);
        expect(dragState!.headers, const Range(1, 4));
        expect(dragState.dropAtIndex, 1);
        expect(dragState.isDropAllowed, isFalse);

        final thirdLocation = tester.getCenter(columnHeaders.at(1));
        await gesture.moveTo(thirdLocation);
        await tester.pump();

        dragState =
            swayzeController.tableDataController.columns.value.dragState;
        expect(dragState, isNotNull);
        expect(dragState!.headers, const Range(1, 4));
        expect(dragState.dropAtIndex, 1);
        expect(dragState.isDropAllowed, isFalse);

        await gesture.up();
        await tester.pumpAndSettle();

        verifyNever(
          () => dragEndAction.invoke(captureAny(), any()),
        );
        verify(
          () => dragCancelAction.invoke(captureAny(), any()),
        );
      });
    });

    group('Drag moves all adjacent selected headers', () {
      /// Test method that does the required steps to assert that all adjacent
      /// selections from the dragged selection are dragged as well.
      @isTest
      Future<void> testAdjacentSelections(
        String description, {
        required Range expectedSelectedRange,
        required List<Range> shiftSelectedHeaders,
        required List<int> modifierSelectedHeaders,
        int startDragAtHeader = 1,
      }) async {
        return testWidgets(description, (tester) async {
          await pumpTestWidget(tester);

          final columnHeaders = tester.findColumnHeaders();
          await tester.controlShiftSelectHeaders(shiftSelectedHeaders);
          await tester.controlSelectHeaders(
            modifierSelectedHeaders.map(columnHeaders.at),
          );

          final selections = swayzeController
              .selection.userSelectionState.selections
              .whereType<HeaderUserSelectionModel>();
          expect(
            selections,
            hasLength(
              modifierSelectedHeaders.length + shiftSelectedHeaders.length,
            ),
          );

          final firstLocation = tester.getCenter(
            columnHeaders.at(startDragAtHeader),
          );
          final gesture = await tester.startGesture(
            firstLocation,
            pointer: 1,
            kind: PointerDeviceKind.mouse,
          );
          addTearDown(gesture.removePointer);
          await tester.pump();

          final secondLocation = tester.getCenter(
            columnHeaders.at(startDragAtHeader + 1),
          );
          await gesture.moveTo(secondLocation);
          await tester.pump();
          final dragState =
              swayzeController.tableDataController.columns.value.dragState;
          expect(dragState, isNotNull);
          expect(dragState!.headers, expectedSelectedRange);
        });
      }

      testAdjacentSelections(
        'No adjacent selections',
        startDragAtHeader: 2,
        shiftSelectedHeaders: [const Range(2, 3)],
        modifierSelectedHeaders: [0, 5],
        expectedSelectedRange: const Range(2, 4),
      );

      testAdjacentSelections(
        'Adjacent before first selection',
        startDragAtHeader: 2,
        shiftSelectedHeaders: [const Range(2, 3)],
        modifierSelectedHeaders: [1, 0],
        expectedSelectedRange: const Range(0, 4),
      );

      testAdjacentSelections(
        'Adjacent after first selection',
        shiftSelectedHeaders: [const Range(1, 2)],
        modifierSelectedHeaders: [3, 4, 5],
        expectedSelectedRange: const Range(1, 6),
      );

      testAdjacentSelections(
        'Adjacent with random selection order',
        startDragAtHeader: 2,
        shiftSelectedHeaders: [const Range(2, 3)],
        modifierSelectedHeaders: [5, 1, 3, 2, 4],
        expectedSelectedRange: const Range(1, 6),
      );

      testAdjacentSelections(
        'Overlapping shift selections',
        startDragAtHeader: 2, // Use a header from the smaller range.
        shiftSelectedHeaders: [const Range(2, 3), const Range(0, 5)],
        modifierSelectedHeaders: [],
        expectedSelectedRange: const Range(0, 6),
      );
    });
  });
}

/// Extensions to help interacting with the headers.
extension _TesterGestureExtensions on WidgetTester {
  /// Selects a range of headers holding the shift key.
  Future shiftSelectHeaders({
    required Finder from,
    required Finder to,
  }) async {
    await tapAt(getCenter(from));
    await pumpAndSettle();
    await sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tapAt(getCenter(to));
    await pumpAndSettle();
    await sendKeyUpEvent(LogicalKeyboardKey.shift);
  }

  /// Selects multiple headers by holding a modifier key.
  Future controlSelectHeaders(Iterable<Finder> headers) async {
    final modifier =
        Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

    await sendKeyDownEvent(modifier);
    for (final finder in headers) {
      await tap(finder, warnIfMissed: false);
      await pumpAndSettle();
    }
    await sendKeyUpEvent(modifier);
  }

  /// Selects multiple headers by holding a modifier key and selecting a range
  /// by holding shift.
  Future controlShiftSelectHeaders(Iterable<Range> ranges) async {
    final modifier =
        Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
    final headers = findColumnHeaders();

    for (final range in ranges) {
      await sendKeyDownEvent(modifier);
      await shiftSelectHeaders(
        from: headers.at(range.start),
        to: headers.at(range.end),
      );
      await sendKeyUpEvent(modifier);
    }
  }

  /// Finds all column headers and returns all in a Finder object.
  Finder findColumnHeaders() => find.descendant(
        of: find.byType(Header).first,
        matching: find.byType(HeaderItem),
      );
}
