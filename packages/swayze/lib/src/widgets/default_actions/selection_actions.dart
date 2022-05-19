import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../controller.dart';
import '../../config.dart';
import '../../core/intents/intents.dart';
import '../../core/internal_state/table_focus/table_focus_provider.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../../core/viewport_context/viewport_context_provider.dart';
import '../../helpers/wrapped.dart';
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
    final tableFocus = TableFocus.of(context);
    final selectionController = internalScope.controller.selection;

    final keysPressed = LogicalKeyboardKey.collapseSynonyms(
      RawKeyboard.instance.keysPressed,
    );

    if (keysPressed.contains(LogicalKeyboardKey.shift)) {
      tableFocus.requestFocus();
      selectionController.updateUserSelections(
        (state) => state.updateLastSelectionToCellSelection(
          focus: intent.cellCoordinate,
        ),
      );
    } else if (keysPressed.containsModifier) {
      final selection = CellUserSelectionModel.fromAnchorFocus(
        anchor: intent.cellCoordinate,
        focus: intent.cellCoordinate,
      );
      tableFocus.requestFocus();
      selectionController.updateUserSelections(
        (state) => state.addSelection(selection),
      );
    } else {
      tableFocus.requestFocus();
      selectionController.updateUserSelections(
        (state) => state.resetSelectionsToACellSelection(
          anchor: intent.cellCoordinate,
          focus: intent.cellCoordinate,
        ),
      );
    }
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
    selectionController.updateUserSelections(
      (state) => state.updateLastSelectionToCellSelection(
        focus: intent.cellCoordinate,
      ),
    );
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

// TODO: [victor] probably we want to move this to another file.
class HeaderDragStartAction extends DefaultSwayzeAction<HeaderDragStartIntent> {
  HeaderDragStartAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    HeaderDragStartIntent intent,
    BuildContext context,
  ) {
    final controller = internalScope.controller.tableDataController
        .getHeaderControllerFor(axis: intent.axis);
    controller.updateState(
      (state) => state.copyWith(
        dragState: Wrapped.value(
          SwayzeHeaderDragState(
            headers: intent.headers,
            dropAtIndex: intent.headers.start,
            position: intent.draggingPosition,
          ),
        ),
      ),
    );
  }
}

class HeaderDragUpdateAction
    extends DefaultSwayzeAction<HeaderDragUpdateIntent> {
  HeaderDragUpdateAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    HeaderDragUpdateIntent intent,
    BuildContext context,
  ) {
    final controller = internalScope.controller.tableDataController
        .getHeaderControllerFor(axis: intent.axis);

    controller.updateState(
      (state) => state.copyWith(
        dragState: Wrapped.value(
          state.dragState?.copyWith(
            dropAtIndex: intent.header,
            position: intent.draggingPosition,
          ),
        ),
      ),
    );
  }
}

class HeaderDragEndAction extends DefaultSwayzeAction<HeaderDragEndIntent> {
  HeaderDragEndAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    HeaderDragEndIntent intent,
    BuildContext context,
  ) {
    final controller =
        internalScope.controller.tableDataController.getHeaderControllerFor(
      axis: intent.axis,
    );

    final dragState = controller.value.dragState;
    if (dragState == null) {
      return;
    }

    final insertAfter = dragState.dropAtIndex >= dragState.headers.start;

    final size = dragState.headers.end - dragState.headers.start - 1;

    controller.updateState(
      (state) => state.copyWith(dragState: const Wrapped.value(null)),
    );
    internalScope.controller.selection.updateUserSelections((state) {
      return state.resetSelectionsToHeaderSelection(
        anchor: intent.header,
        focus: insertAfter ? intent.header - size : intent.header + size,
        axis: intent.axis,
      );
    });
  }
}

class HeaderDragCancelAction
    extends DefaultSwayzeAction<HeaderDragCancelIntent> {
  HeaderDragCancelAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(
    HeaderDragCancelIntent intent,
    BuildContext context,
  ) {
    final controller =
        internalScope.controller.tableDataController.getHeaderControllerFor(
      axis: intent.axis,
    );
    controller.updateState(
      (state) => state.copyWith(dragState: const Wrapped.value(null)),
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
