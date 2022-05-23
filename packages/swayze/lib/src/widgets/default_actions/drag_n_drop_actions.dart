import 'package:flutter/widgets.dart';

import '../../../controller.dart';
import '../../core/intents/drag_n_drop_intents.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../../helpers/wrapped.dart';
import '../internal_scope.dart';
import 'default_swayze_action.dart';

/// Default [Action] for [HeaderDragStartIntent].
///
/// See also:
/// * [HeaderGestureDetector] that triggers the intent.
/// * [SwayzeHeaderDragState] that holds the drag state.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
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

/// Default [Action] for [HeaderDragUpdateIntent].
///
/// See also:
/// * [HeaderGestureDetector] that triggers the intent.
/// * [SwayzeHeaderDragState] that holds the drag state.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
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

/// Default [Action] for [HeaderDragEndIntent].
///
/// See also:
/// * [HeaderGestureDetector] that triggers the intent.
/// * [SwayzeHeaderDragState] that holds the drag state.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
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

/// Default [Action] for [HeaderDragCancelIntent].
///
/// See also:
/// * [HeaderGestureDetector] that triggers the intent.
/// * [SwayzeHeaderDragState] that holds the drag state.
/// * [DefaultActions] for the widget that binds this action into the
/// widget tree.
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
