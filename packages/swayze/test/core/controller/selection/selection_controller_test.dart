import 'package:flutter/rendering.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

import '../../../test_utils/create_swayze_controller.dart';

SwayzeSelectionController getSelectionController() =>
    createSwayzeController().selection;

void main() {
  group('User selections', () {
    test('initial state', () {
      final selectionController = getSelectionController();

      final initialState = selectionController.userSelectionState;

      expect(initialState.selections.length, 1);
      expect(initialState.activeCellCoordinate, const IntVector2.symmetric(0));
      expect(
        initialState.primarySelection,
        const TypeMatcher<CellUserSelectionModel>(),
      );
      expect(
        (initialState.primarySelection as CellUserSelectionModel).anchor,
        const IntVector2(0, 0),
      );

      expect(
        (initialState.primarySelection as CellUserSelectionModel).focus,
        const IntVector2(0, 0),
      );

      selectionController.dispose();
    });

    test('reset to initial state', () {
      final selectionController = getSelectionController();

      final newSelection = CellUserSelectionModel.fromAnchorFocus(
        anchor: const IntVector2.symmetric(2),
        focus: const IntVector2.symmetric(3),
      );

      // Add a selection
      selectionController.updateUserSelections(
        (previousState) => previousState.addSelection(newSelection),
      );

      expect(selectionController.userSelectionState.selections.length, 2);

      // Reset selections
      selectionController.updateUserSelections(
        (previousState) => previousState.reset(),
      );

      final primarySelection = selectionController
          .userSelectionState.primarySelection as CellUserSelectionModel;
      expect(selectionController.userSelectionState.selections.length, 1);
      expect(
        selectionController.userSelectionState.activeCellCoordinate,
        const IntVector2.symmetric(0),
      );
      expect(primarySelection, const TypeMatcher<CellUserSelectionModel>());
      expect(primarySelection.anchor, const IntVector2(0, 0));
      expect(primarySelection.focus, const IntVector2(0, 0));

      selectionController.dispose();
    });

    group('add a selection', () {
      test('add cell state', () {
        final selectionController = getSelectionController();

        final newSelection = CellUserSelectionModel.fromAnchorFocus(
          anchor: const IntVector2.symmetric(2),
          focus: const IntVector2.symmetric(3),
        );
        selectionController.updateUserSelections(
          (previousState) => previousState.addSelection(newSelection),
        );

        final selectionState = selectionController.userSelectionState;

        expect(selectionState.selections.length, 2);
        expect(
          selectionState.activeCellCoordinate,
          const IntVector2.symmetric(2),
        );
        expect(
          selectionState.primarySelection,
          newSelection,
        );

        selectionController.dispose();
      });

      test('add header cell state', () {
        final selectionController = getSelectionController();

        final newSelection = HeaderUserSelectionModel.fromAnchorFocus(
          anchor: 4,
          focus: 12,
          axis: Axis.horizontal,
        );
        selectionController.updateUserSelections(
          (previousState) => previousState.addSelection(newSelection),
        );

        final selectionState = selectionController.userSelectionState;
        expect(selectionState.selections.length, 2);
        expect(selectionState.activeCellCoordinate, const IntVector2(4, 0));
        expect(
          selectionState.primarySelection,
          newSelection,
        );

        selectionController.dispose();
      });
    });

    test('reset to a cell selection', () {
      final selectionController = getSelectionController();

      final aCellSelection = CellUserSelectionModel.fromAnchorFocus(
        anchor: const IntVector2.symmetric(2),
        focus: const IntVector2.symmetric(3),
      );
      selectionController.updateUserSelections(
        (previousState) => previousState.addSelection(aCellSelection),
      );

      selectionController.updateUserSelections(
        (previousState) => previousState.resetSelectionsToACellSelection(
          anchor: const IntVector2.symmetric(18),
          focus: const IntVector2.symmetric(2),
        ),
      );

      final selectionState = selectionController.userSelectionState;
      expect(selectionState.selections.length, 1);
      expect(
        selectionState.activeCellCoordinate,
        const IntVector2.symmetric(18),
      );

      final primarySelection = selectionState.primarySelection;
      expect(primarySelection, const TypeMatcher<CellUserSelectionModel>());
      final primarySelectionCast = primarySelection as CellUserSelectionModel;
      expect(primarySelectionCast.anchor, const IntVector2.symmetric(18));
      expect(primarySelectionCast.focus, const IntVector2.symmetric(2));

      selectionController.dispose();
    });

    test('reset to a header selection', () {
      final selectionController = getSelectionController();

      final aCellSelection = CellUserSelectionModel.fromAnchorFocus(
        anchor: const IntVector2.symmetric(2),
        focus: const IntVector2.symmetric(3),
      );
      selectionController.updateUserSelections(
        (previousState) => previousState.addSelection(aCellSelection),
      );

      selectionController.updateUserSelections(
        (previousState) => previousState.resetSelectionsToHeaderSelection(
          axis: Axis.horizontal,
          anchor: 8,
          focus: 2,
        ),
      );

      final selectionState = selectionController.userSelectionState;
      expect(selectionState.selections.length, 1);
      expect(selectionState.activeCellCoordinate, const IntVector2(8, 0));

      final primarySelection = selectionState.primarySelection;
      expect(primarySelection, const TypeMatcher<HeaderUserSelectionModel>());
      final primarySelectionCast = primarySelection as HeaderUserSelectionModel;
      expect(primarySelectionCast.anchor, 8);
      expect(primarySelectionCast.focus, 2);

      selectionController.dispose();
    });

    group('update last selection', () {
      group('from a cell selection', () {
        test('to a cell selection', () {
          final selectionController = getSelectionController();

          final aCellSelection = CellUserSelectionModel.fromAnchorFocus(
            anchor: const IntVector2.symmetric(22),
            focus: const IntVector2.symmetric(3),
          );
          selectionController.updateUserSelections(
            (previousState) => previousState.addSelection(aCellSelection),
          );

          selectionController.updateUserSelections(
            (previousState) => previousState.updateLastSelectionToCellSelection(
              focus: const IntVector2(12, 0),
            ),
          );

          final selectionState = selectionController.userSelectionState;
          expect(selectionState.selections.length, 2);
          expect(selectionState.activeCellCoordinate, const IntVector2(22, 22));

          final primarySelection = selectionState.primarySelection;
          expect(primarySelection, const TypeMatcher<CellUserSelectionModel>());
          final primarySelectionCast =
              primarySelection as CellUserSelectionModel;
          expect(primarySelectionCast.anchor, const IntVector2.symmetric(22));
          expect(primarySelectionCast.focus, const IntVector2(12, 0));

          selectionController.dispose();
        });

        test('to a header selection', () {
          final selectionController = getSelectionController();

          final aCellSelection = CellUserSelectionModel.fromAnchorFocus(
            anchor: const IntVector2.symmetric(2),
            focus: const IntVector2.symmetric(3),
          );
          selectionController.updateUserSelections(
            (previousState) => previousState.addSelection(aCellSelection),
          );

          selectionController.updateUserSelections(
            (previousState) =>
                previousState.updateLastSelectionToHeaderSelection(
              focus: 0,
              axis: Axis.vertical,
            ),
          );

          final selectionState = selectionController.userSelectionState;
          expect(selectionState.selections.length, 2);
          expect(selectionState.activeCellCoordinate, const IntVector2(0, 2));

          final primarySelection = selectionState.primarySelection;
          expect(
            primarySelection,
            const TypeMatcher<HeaderUserSelectionModel>(),
          );
          final primarySelectionCast =
              primarySelection as HeaderUserSelectionModel;
          expect(primarySelectionCast.anchor, 2);
          expect(primarySelectionCast.focus, 0);

          selectionController.dispose();
        });
      });

      group('from a header selection', () {
        test('to a cell selection', () {
          final selectionController = getSelectionController();

          final aHeaderSelection = HeaderUserSelectionModel.fromAnchorFocus(
            anchor: 2,
            focus: 3,
            axis: Axis.horizontal,
          );
          selectionController.updateUserSelections(
            (previousState) => previousState.addSelection(aHeaderSelection),
          );

          selectionController.updateUserSelections(
            (previousState) => previousState.updateLastSelectionToCellSelection(
              focus: const IntVector2(12, 2),
            ),
          );

          final selectionState = selectionController.userSelectionState;
          expect(selectionState.selections.length, 2);
          expect(selectionState.activeCellCoordinate, const IntVector2(2, 0));

          final primarySelection = selectionState.primarySelection;
          expect(primarySelection, const TypeMatcher<CellUserSelectionModel>());
          final primarySelectionCast =
              primarySelection as CellUserSelectionModel;
          expect(primarySelectionCast.anchor, const IntVector2(2, 0));
          expect(primarySelectionCast.focus, const IntVector2(12, 2));

          selectionController.dispose();
        });

        test('to a header selection in the same axis', () {
          final selectionController = getSelectionController();

          final aHeaderSelection = HeaderUserSelectionModel.fromAnchorFocus(
            anchor: 2,
            focus: 3,
            axis: Axis.horizontal,
          );
          selectionController.updateUserSelections(
            (previousState) => previousState.addSelection(aHeaderSelection),
          );

          selectionController.updateUserSelections(
            (previousState) =>
                previousState.updateLastSelectionToHeaderSelection(
              focus: 10,
              axis: Axis.horizontal,
            ),
          );

          final selectionState = selectionController.userSelectionState;
          expect(selectionState.selections.length, 2);
          expect(selectionState.activeCellCoordinate, const IntVector2(2, 0));

          final primarySelection = selectionState.primarySelection;
          expect(
            primarySelection,
            const TypeMatcher<HeaderUserSelectionModel>(),
          );
          final primarySelectionCast =
              primarySelection as HeaderUserSelectionModel;
          expect(primarySelectionCast.anchor, 2);
          expect(primarySelectionCast.focus, 10);

          selectionController.dispose();
        });

        test('to a header selection in a different axis', () {
          final selectionController = getSelectionController();
          final aHeaderSelection = HeaderUserSelectionModel.fromAnchorFocus(
            anchor: 2,
            focus: 3,
            axis: Axis.horizontal,
          );
          selectionController.updateUserSelections(
            (previousState) => previousState.addSelection(aHeaderSelection),
          );

          selectionController.updateUserSelections(
            (previousState) =>
                previousState.updateLastSelectionToHeaderSelection(
              focus: 4,
              axis: Axis.vertical,
            ),
          );

          final selectionState = selectionController.userSelectionState;
          expect(selectionState.selections.length, 2);
          expect(selectionState.activeCellCoordinate, const IntVector2(0, 0));

          final primarySelection = selectionState.primarySelection;
          expect(
            primarySelection,
            const TypeMatcher<HeaderUserSelectionModel>(),
          );
          final primarySelectionCast =
              primarySelection as HeaderUserSelectionModel;
          expect(primarySelectionCast.anchor, 0);
          expect(primarySelectionCast.focus, 4);

          selectionController.dispose();
        });
      });
    });

    test('Changing state notifies listeners', () {
      final selectionController = getSelectionController();

      var calledTimes = 0;

      // ignore: prefer_function_declarations_over_variables
      final listener = () => calledTimes++;

      selectionController.addListener(listener);

      // no changes should not call listeners
      selectionController
          .updateUserSelections((previousState) => previousState);
      expect(calledTimes, 0);

      selectionController.updateUserSelections(
        (previousState) => previousState.updateLastSelectionToCellSelection(
          focus: const IntVector2.symmetric(1),
        ),
      );
      expect(calledTimes, 1);

      selectionController.dispose();
    });
  });
}
