import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../controller.dart';
import '../../config.dart';
import '../../core/intents/intents.dart';
import '../../core/internal_state/table_focus/table_focus_provider.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../../core/viewport_context/viewport_context_provider.dart';
import '../headers/gestures/header_gesture_detector.dart';
import '../internal_scope.dart';
import '../shortcuts/shortcuts.dart';
import '../table_body/gestures/table_body_gesture_detector.dart';
import 'default_swayze_action.dart';
import 'default_table_actions.dart';

const _kDebounceDuration = kDefaultScrollAnimationDuration;

Timer? _scrollFromCoordinateToCoordinateDebounce;

/// Given a [fromCoordinate] scrolls into a [toCoordinate].
///
/// If [fromCoordinate] is offscreen then it jumps abruptly into viewport,
/// otherwise we animate into it's offset.
void _scrollFromCoordinateToCoordinate({
  required BuildContext context,
  required IntVector2 fromCoordinate,
  required IntVector2 toCoordinate,
}) {
  scheduleMicrotask(() {
    final internalScope = InternalScope.of(context);
    final viewportContext = ViewportContextProvider.of(context);
    final scrollController = internalScope.controller.scroll;

    void restartDebounce() {
      _scrollFromCoordinateToCoordinateDebounce?.cancel();
      _scrollFromCoordinateToCoordinateDebounce = Timer(
        _kDebounceDuration,
        () => _scrollFromCoordinateToCoordinateDebounce = null,
      );
    }

    // Avoid starting animations in a high frequency to avoid a jumpy UI
    if (_scrollFromCoordinateToCoordinateDebounce?.isActive ?? false) {
      scrollController.jumpToCoordinate(toCoordinate);
      restartDebounce();
      return;
    }
    restartDebounce();

    final fromCoordinateIsOffScreen =
        viewportContext.getCellPosition(fromCoordinate).isOffscreen;

    if (fromCoordinateIsOffScreen) {
      scrollController.jumpToCoordinate(toCoordinate);
    } else {
      scrollController.animateToCoordinate(toCoordinate);
    }
  });
}

Timer? _scrollFromCoordinateToHeaderDebounce;

/// Given a [fromCoordinate] scrolls into a [toHeader] in a given [Axis].
///
/// If [fromCoordinate] is offscreen then it jumps abruptly into viewport,
/// otherwise we animate into it's offset.
void _scrollFromCoordinateToHeader({
  required BuildContext context,
  required Axis axis,
  required IntVector2 fromCoordinate,
  required int toHeader,
}) {
  scheduleMicrotask(() {
    final internalScope = InternalScope.of(context);
    final viewportContext = ViewportContextProvider.of(context);
    final scrollController = internalScope.controller.scroll;
    final from =
        axis == Axis.horizontal ? fromCoordinate.dx : fromCoordinate.dy;

    void restartDebounce() {
      _scrollFromCoordinateToHeaderDebounce = Timer(
        _kDebounceDuration,
        () => _scrollFromCoordinateToHeaderDebounce = null,
      );
    }

    // Avoid starting animations in a high frequency to avoid a jumpy UI
    if (_scrollFromCoordinateToHeaderDebounce?.isActive ?? false) {
      scrollController.jumpToHeader(toHeader, axis);

      restartDebounce();
      return;
    }

    restartDebounce();

    final fromCoordinateIsOffScreen = !viewportContext
        .getAxisContextFor(axis: axis)
        .value
        .scrollableRange
        .contains(from);

    if (fromCoordinateIsOffScreen) {
      scrollController.jumpToHeader(toHeader, axis);
    } else {
      scrollController.animateToHeader(toHeader, axis);
    }
  });
}

/// Default [Action] for [SelectTableIntent].
///
/// See also:
/// * [TableShortcuts] for the mapping between [Shortcut] and [Intent].
/// * [UserSelectionState] for the implementation of the select table.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class SelectTableAction extends DefaultSwayzeAction<SelectTableIntent> {
  SelectTableAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(
          internalScope,
          viewportContext,
        );

  @override
  void invokeAction(SelectTableIntent intent, BuildContext context) {
    final selectionController = internalScope.controller.selection;
    selectionController.updateUserSelections(
      (state) => state.resetSelectionsToTableSelection(),
    );
  }
}

/// Default [Action] for [MoveActiveCellIntent].
///
/// See also:
/// * [TableShortcuts] for the mapping between [Shortcut] and [Intent].
/// * [UserSelectionState] for the implementation of the move active cell.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class MoveActiveCellAction extends DefaultSwayzeAction<MoveActiveCellIntent> {
  MoveActiveCellAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(MoveActiveCellIntent intent, BuildContext context) {
    final selectionController = internalScope.controller.selection;
    final cellsController = internalScope.controller.cellsController;
    final fromCoordinate =
        selectionController.userSelectionState.activeCellCoordinate;

    selectionController.updateUserSelections(
      (state) => state.moveActiveCell(
        (IntVector2 coordinate) {
          return cellsController.getNextCoordinate(
            originalCoordinate: coordinate,
            direction: intent.direction,
          );
        },
      ),
    );

    final cellSelection = selectionController.userSelectionState.selections.last
        as CellUserSelectionModel;
    _scrollFromCoordinateToCoordinate(
      context: context,
      fromCoordinate: fromCoordinate,
      toCoordinate: cellSelection.focus,
    );
  }
}

/// Default [Action] for [MoveActiveCellByBlockIntent]
///
/// See also:
/// * [TableShortcuts] for the mapping between [Shortcut] and [Intent].
/// * [UserSelectionState] for the implementation of the move active cell.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class MoveActiveCellByBlockAction
    extends DefaultSwayzeAction<MoveActiveCellByBlockIntent> {
  MoveActiveCellByBlockAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(MoveActiveCellByBlockIntent intent, BuildContext context) {
    final selectionController = internalScope.controller.selection;
    final cellsController = internalScope.controller.cellsController;
    final fromCoordinate =
        selectionController.userSelectionState.activeCellCoordinate;

    selectionController.updateUserSelections(
      (state) => state.moveActiveCellByBlock(
        (IntVector2 coordinate) {
          return cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: coordinate,
            direction: intent.direction,
          );
        },
      ),
    );

    final cellSelection = selectionController.userSelectionState.selections.last
        as CellUserSelectionModel;
    _scrollFromCoordinateToCoordinate(
      context: context,
      fromCoordinate: fromCoordinate,
      toCoordinate: cellSelection.focus,
    );
  }
}

/// Default [Action] for [ExpandSelectionIntent].
///
/// See also:
/// * [TableShortcuts] for the mapping between [Shortcut] and [Intent].
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class ExpandSelectionAction extends DefaultSwayzeAction<ExpandSelectionIntent> {
  ExpandSelectionAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(ExpandSelectionIntent intent, BuildContext context) {
    final selectionController = internalScope.controller.selection;
    final cellsController = internalScope.controller.cellsController;

    final fromCoordinate =
        selectionController.userSelectionState.selections.last.focusCoordinate;

    selectionController.updateUserSelections(
      (state) => state.expandLastSelection(
        intent.direction,
        getNextCoordinate: (IntVector2 coordinate) {
          return cellsController.getNextCoordinate(
            originalCoordinate: coordinate,
            direction: intent.direction,
          );
        },
      ),
    );

    final toSelection = selectionController.userSelectionState.selections.last;
    if (toSelection is HeaderUserSelectionModel) {
      _scrollFromCoordinateToHeader(
        context: context,
        axis: axisDirectionToAxis(intent.direction),
        fromCoordinate: fromCoordinate,
        toHeader: toSelection.focus,
      );
    } else {
      _scrollFromCoordinateToCoordinate(
        context: context,
        fromCoordinate: fromCoordinate,
        toCoordinate: toSelection.focusCoordinate,
      );
    }
  }
}

/// Default [Action] for [ExpandSelectionByBlockIntent].
///
/// See also:
/// * [TableShortcuts] for the mapping between [Shortcut] and [Intent].
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class ExpandSelectionByBlockAction
    extends DefaultSwayzeAction<ExpandSelectionByBlockIntent> {
  ExpandSelectionByBlockAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(ExpandSelectionByBlockIntent intent, BuildContext context) {
    final selectionController = internalScope.controller.selection;
    final cellsController = internalScope.controller.cellsController;
    final headerController =
        internalScope.controller.tableDataController.getHeaderControllerFor(
      axis: axisDirectionToAxis(intent.direction),
    );

    final limit = headerController.value.totalCount - 1;
    final fromCoordinate =
        selectionController.userSelectionState.selections.last.focusCoordinate;

    selectionController.updateUserSelections(
      (state) => state.expandLastSelectionByBlock(
        intent.direction,
        limit: limit,
        getNextCoordinateInCellsBlock: (IntVector2 coordinate) {
          return cellsController.getNextCoordinateInCellsBlock(
            originalCoordinate: coordinate,
            direction: intent.direction,
          );
        },
      ),
    );

    final toSelection = selectionController.userSelectionState.selections.last;
    if (toSelection is HeaderUserSelectionModel) {
      _scrollFromCoordinateToHeader(
        context: context,
        axis: axisDirectionToAxis(intent.direction),
        fromCoordinate: fromCoordinate,
        toHeader: toSelection.focus,
      );
    } else {
      _scrollFromCoordinateToCoordinate(
        context: context,
        fromCoordinate: fromCoordinate,
        toCoordinate: toSelection.focusCoordinate,
      );
    }
  }
}

/// Default [Action] for [TableBodySelectionStartIntent]
///
/// See also:
/// * [TableBodyGestureDetector] that triggers the intent
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class CellSelectionStartAction
    extends DefaultSwayzeAction<TableBodySelectionStartIntent> {
  CellSelectionStartAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    TableBodySelectionStartIntent intent,
    BuildContext context,
  ) {
    final selectionController = internalScope.controller.selection;

    TableFocus.of(context).requestFocus();

    // Drag and fill creates a new selection of the fill type.
    if (intent.fill) {
      final primary = internalScope
          .controller.selection.userSelectionState.primarySelection;

      selectionController.updateFillSelections(
        (state) => state.addIfNoneExists(
          FillSelectionModel.fromAnchorFocus(
            anchor: primary.anchorCoordinate,
            focus: primary.focusCoordinate,
          ),
        ),
      );

      return;
    }

    final keysPressed = LogicalKeyboardKey.collapseSynonyms(
      RawKeyboard.instance.keysPressed,
    );

    if (keysPressed.contains(LogicalKeyboardKey.shift)) {
      selectionController.updateUserSelections(
        (state) => state.updateLastSelectionToCellSelection(
          focus: intent.cellCoordinate,
        ),
      );

      return;
    }

    if (keysPressed.containsModifier) {
      final selection = CellUserSelectionModel.fromAnchorFocus(
        anchor: intent.cellCoordinate,
        focus: intent.cellCoordinate,
      );

      selectionController.updateUserSelections(
        (state) => state.addSelection(selection),
      );

      return;
    }

    selectionController.updateUserSelections(
      (state) => state.resetSelectionsToACellSelection(
        anchor: intent.cellCoordinate,
        focus: intent.cellCoordinate,
      ),
    );
  }
}

/// Default [Action] for [HeaderSelectionStartIntent]
///
/// See also:
/// * [HeaderGestureDetector] that triggers the intent
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class HeaderSelectionStartAction
    extends DefaultSwayzeAction<HeaderSelectionStartIntent> {
  HeaderSelectionStartAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    HeaderSelectionStartIntent intent,
    BuildContext context,
  ) {
    final tableFocus = TableFocus.of(context);
    final selectionController = internalScope.controller.selection;

    final keysPressed = LogicalKeyboardKey.collapseSynonyms(
      RawKeyboard.instance.keysPressed,
    );
    tableFocus.requestFocus();

    if (keysPressed.contains(LogicalKeyboardKey.shift)) {
      selectionController.updateUserSelections((state) {
        return state.updateLastSelectionToHeaderSelection(
          focus: intent.header,
          axis: intent.axis,
        );
      });
    } else if (keysPressed.containsModifier) {
      final selection = HeaderUserSelectionModel.fromAnchorFocus(
        anchor: intent.header,
        focus: intent.header,
        axis: intent.axis,
      );
      selectionController.updateUserSelections(
        (state) => state.addSelection(selection),
      );
    } else {
      selectionController.updateUserSelections((state) {
        return state.resetSelectionsToHeaderSelection(
          anchor: intent.header,
          focus: intent.header,
          axis: intent.axis,
        );
      });
    }
  }
}

/// Default [Action] for [TableBodySelectionUpdateIntent]
///
/// This will restrict the axis of the selection if the selection is a drag
/// and fill type.
///
/// See also:
/// * [TableBodyGestureDetector] that triggers the intent
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class CellSelectionUpdateAction
    extends DefaultSwayzeAction<TableBodySelectionUpdateIntent> {
  CellSelectionUpdateAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    TableBodySelectionUpdateIntent intent,
    BuildContext context,
  ) {
    final selectionController = internalScope.controller.selection;
    final fillSelection = selectionController.fillSelectionState.selection;

    if (fillSelection != null) {
      _updateFillSelection(intent.cellCoordinate);

      return;
    }

    selectionController.updateUserSelections(
      (state) => state.updateLastSelectionToCellSelection(
        focus: intent.cellCoordinate,
      ),
    );
  }

  void _updateFillSelection(IntVector2 coordinate) {
    final selectionController = internalScope.controller.selection;

    final primary = selectionController.userSelectionState.primarySelection;

    final anchor = primary.anchorCoordinate;
    final focus = primary.focusCoordinate;

    final currentRange = Range2D.fromPoints(
      IntVector2(
        min(anchor.dx, focus.dx),
        min(anchor.dy, focus.dy),
      ),
      IntVector2(
        max(anchor.dx, focus.dx),
        max(anchor.dy, focus.dy),
      ),
    );

    final newRange = Range2D.fromPoints(
      IntVector2(
        min(coordinate.dx, currentRange.leftTop.dx),
        min(coordinate.dy, currentRange.leftTop.dy),
      ),
      IntVector2(
        max(coordinate.dx, currentRange.rightBottom.dx),
        max(coordinate.dy, currentRange.rightBottom.dy),
      ),
    );

    // We can only grow the selection vertically or horizontally, and vertical
    // selections have the preference.
    final restrictVertical = newRange.size.dy - currentRange.size.dy >=
        newRange.size.dx - currentRange.size.dx;

    selectionController.updateFillSelections(
      (state) => state.update(
        anchor: currentRange.leftTop.copyWith(
          x: restrictVertical ? null : newRange.leftTop.dx,
          y: restrictVertical ? newRange.leftTop.dy : null,
        ),
        focus: currentRange.rightBottom.copyWith(
          x: restrictVertical ? null : newRange.rightBottom.dx,
          y: restrictVertical ? newRange.rightBottom.dy : null,
        ),
      ),
    );
  }
}

/// Default [Action] for [TableBodySelectionEndIntent]
///
/// See also:
/// * [TableBodyGestureDetector] that triggers the intent
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class CellSelectionEndAction
    extends DefaultSwayzeAction<TableBodySelectionEndIntent> {
  CellSelectionEndAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    TableBodySelectionEndIntent intent,
    BuildContext context,
  ) {
    final selectionController = internalScope.controller.selection;

    final primary = selectionController.userSelectionState.primarySelection;
    final fill = selectionController.fillSelectionState.selection;

    if (primary is! CellUserSelectionModel || fill == null) {
      return;
    }

    // Transform the fill selection into a regular selection
    selectionController.updateUserSelections(
      (state) => state.resetSelectionsToACellSelection(
        anchor: fill.anchor,
        focus: fill.focus,
      ),
    );

    // Clear the fill selection
    selectionController.updateFillSelections(
      (state) => state.clear(),
    );

    Actions.invoke(
      context,
      FillIntoTargetIntent(
        source: primary,
        target: fill,
      ),
    );
  }
}

/// Default [Action] for [TableBodySelectionCancelIntent]
///
/// See also:
/// * [TableBodyGestureDetector] that triggers the intent
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class CellSelectionCancelAction
    extends DefaultSwayzeAction<TableBodySelectionCancelIntent> {
  CellSelectionCancelAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    TableBodySelectionCancelIntent intent,
    BuildContext context,
  ) {
    final selectionController = internalScope.controller.selection;

    final fill = selectionController.fillSelectionState.selection;

    if (fill != null) {
      selectionController.updateFillSelections(
        (state) => state.clear(),
      );
    }
  }
}

/// Default [Action] for [HeaderSelectionUpdateIntent]
///
/// See also:
/// * [HeaderGestureDetector] that triggers the intent
/// * [UserSelectionState] for the implementation of the expand selection.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
class HeaderSelectionUpdateAction
    extends DefaultSwayzeAction<HeaderSelectionUpdateIntent> {
  HeaderSelectionUpdateAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(HeaderSelectionUpdateIntent intent, BuildContext context) {
    final selectionController = internalScope.controller.selection;
    selectionController.updateUserSelections(
      (state) => state.updateLastSelectionToHeaderSelection(
        axis: intent.axis,
        focus: intent.header,
      ),
    );
  }
}

extension on Set<LogicalKeyboardKey> {
  bool get containsModifier {
    final isDarwin = Platform.isMacOS || Platform.isIOS;
    return isDarwin
        ? contains(LogicalKeyboardKey.meta)
        : contains(LogicalKeyboardKey.control);
  }
}
