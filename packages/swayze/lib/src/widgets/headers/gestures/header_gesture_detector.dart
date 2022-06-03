import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../controller.dart';
import '../../../../intents.dart';
import '../../../core/viewport_context/viewport_context.dart';
import '../../../core/viewport_context/viewport_context_provider.dart';
import '../../../helpers/scroll/auto_scroll.dart';
import '../../internal_scope.dart';
import 'resize_header/resize_header_details_notifier.dart';

/// A transport class for auxiliary data about a header gesture and it's
/// position.
@immutable
class _HeaderGestureDetails {
  final Offset localPosition;
  final int headerPosition;

  const _HeaderGestureDetails({
    required this.localPosition,
    required this.headerPosition,
  });
}

/// Return the [Range] edge to expand according to the given [ScrollDirection].
int _getRangeEdgeOnAutoScroll(Range range, ScrollDirection scrollDirection) {
  if (scrollDirection == ScrollDirection.forward) {
    return range.start;
  }

  return range.end - 1;
}

/// Given a globalPosition [Offset] and the [Axis] it creates a
/// [_HeaderGestureDetails] with the converted localPosition [Offset] and the
/// corresponding header position.
///
/// It considers the offscreen details to ensure that we can properly expand
/// the table with the "elastic" table feature.
_HeaderGestureDetails _getHeaderGestureDetails({
  required BuildContext context,
  required Axis axis,
  required Offset globalPosition,
}) {
  final box = context.findRenderObject()! as RenderBox;
  final localPosition = box.globalToLocal(globalPosition);
  return _getHeaderLocalPositionGestureDetails(
    context: context,
    axis: axis,
    localPosition: localPosition,
  );
}

_HeaderGestureDetails _getHeaderLocalPositionGestureDetails({
  required BuildContext context,
  required Axis axis,
  required Offset localPosition,
}) {
  final viewportContext = ViewportContextProvider.of(context);
  final tableDataController =
      InternalScope.of(context).controller.tableDataController;
  final offset = axis == Axis.horizontal ? localPosition.dx : localPosition.dy;
  final headerPositionResult = viewportContext.pixelToPosition(offset, axis);

  var result = headerPositionResult.position;
  if (headerPositionResult.overflow == OffscreenDetails.trailing) {
    final diff =
        offset - viewportContext.getAxisContextFor(axis: axis).value.extent;
    final defaultExtent = tableDataController
        .getHeaderControllerFor(axis: axis)
        .value
        .defaultHeaderExtent;

    final additionalAmount = (diff / defaultExtent).ceil();
    result += additionalAmount;
  }

  return _HeaderGestureDetails(
    localPosition: localPosition,
    headerPosition: result,
  );
}

class HeaderGestureDetector extends StatefulWidget {
  final Axis axis;
  final double displacement;

  const HeaderGestureDetector({
    Key? key,
    required this.axis,
    required this.displacement,
  }) : super(key: key);

  @override
  _HeaderGestureDetectorState createState() => _HeaderGestureDetectorState();
}

class _HeaderGestureDetectorState extends State<HeaderGestureDetector> {
  late final internalScope = InternalScope.of(context);
  late final viewportContext = ViewportContextProvider.of(context);
  late final resizeNotifier =
      ResizeHeaderDetailsNotifierProvider.maybeOf(context);

  /// Cache to make the position of the start of a drag gesture acessible in
  /// the drag updates.
  Offset? dragOriginOffsetCache;

  /// Current mouse cursor.
  ///
  /// A grab cursor is displayed when a header is selected and it can be
  /// dragged.
  MouseCursor cursor = MouseCursor.defer;

  @override
  void initState() {
    super.initState();

    viewportContext
        .getAxisContextFor(axis: widget.axis)
        .addListener(onRangesChanged);
  }

  @override
  void dispose() {
    viewportContext
        .getAxisContextFor(axis: widget.axis)
        .removeListener(onRangesChanged);

    super.dispose();
  }

  /// Listen for [ViewportContext] range changes to update selections in case
  /// a [AutoScrollActivity] is in progress.
  void onRangesChanged() {
    if (isDraggingHeader()) {
      return;
    }

    final scrollController = internalScope.controller.scroll;
    final selectionController = internalScope.controller.selection;

    final primarySelection =
        selectionController.userSelectionState.primarySelection;
    if (primarySelection is! HeaderUserSelectionModel ||
        !scrollController.isAutoScrollOn) {
      return;
    }

    final headerNotifier = viewportContext.getAxisContextFor(
      axis: widget.axis,
    );

    final scrollPosition =
        scrollController.getScrollControllerFor(axis: widget.axis)!.position;

    selectionController.updateUserSelections(
      (state) => state.updateLastSelectionToHeaderSelection(
        axis: widget.axis,
        focus: scrollPosition.userScrollDirection != ScrollDirection.idle
            ? _getRangeEdgeOnAutoScroll(
                headerNotifier.value.scrollableRange,
                scrollPosition.userScrollDirection,
              )
            : primarySelection.focus,
      ),
    );
  }

  /// Given the current [localOffset] and [globalOffset] check if a
  /// [AutoScrollActivity] should be triggered and which direction.
  ///
  /// When moving to the trailing edge of each axis (up or left) the scroll
  /// activity kicks in when the mouse is before the displacement, ie. in
  /// practical terms, the scroll starts when we hover one of the headers.
  ///
  /// When moving to the leading edge (right or down) theres a
  /// scrollThreshold where the scroll kicks in before we reach the edge of
  /// the table.
  ///
  /// When moving down it checks if the [globalOffset] is within the
  /// scrollThreshold gap at the screen's height edge.
  ///
  /// When moving right, since there might other elements to the right, it
  /// cannot follow the same approach as when moving down. It checks if the
  /// [localOffset] is within the [kRowHeaderWidth] + scrollThreshold gap
  /// at the [ViewportContext] extend.
  ///
  /// See also:
  /// - TableBodyGestureDetector's updateAutoScroll, which is similar to this
  /// method but its related to cells and can create scroll activities in
  /// both axis at the same time.
  void updateDragScroll({
    required Offset localOffset,
    required Offset globalOffset,
    required Offset originOffset,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final scrollController = internalScope.controller.scroll;
    final DragScrollData scrollData;

    if (widget.axis == Axis.horizontal) {
      scrollData = getHorizontalDragScrollData(
        displacement: widget.displacement,
        globalOffset: globalOffset.dx,
        localOffset: localOffset.dx,
        gestureOriginOffset: originOffset.dx,
        screenWidth: screenSize.width,
        viewportExtent: viewportContext.columns.value.extent,
        frozenExtent: viewportContext.columns.value.frozenExtent,
      );
    } else {
      scrollData = getVerticalDragScrollData(
        displacement: widget.displacement,
        globalOffset: globalOffset.dy,
        localOffset: localOffset.dy,
        gestureOriginOffset: originOffset.dy,
        positionPixel:
            scrollController.verticalScrollController!.position.pixels,
        screenHeight: screenSize.height,
        scrollingData: viewportContext.rows.virtualizationState.scrollingData,
        viewportExtent: viewportContext.rows.value.extent,
        frozenExtent: viewportContext.rows.value.frozenExtent,
      );
    }

    if (scrollData is AutoScrollDragScrollData) {
      // auto scroll
      scrollController.startOrUpdateAutoScroll(
        direction: scrollData.direction,
        maxToScroll: scrollData.maxToScroll,
        pointerDistance: scrollData.pointerDistance,
      );
    } else if (scrollData is ResetScrollDragScrollData) {
      // reset scroll

      scrollController.jumpToHeader(
        viewportContext
            .getAxisContextFor(axis: widget.axis)
            .value
            .frozenRange
            .end,
        widget.axis,
      );
    } else {
      // do not scroll
      scrollController.stopAutoScroll(widget.axis);
    }
  }

  /// Handles taps/drag starts that should start a selection.
  /// Given a [_HeaderGestureDetails] it creates or updates a selection
  /// based on the modifiers that the user is pressing.
  void handleStartSelection(_HeaderGestureDetails details) {
    Actions.invoke(
      context,
      HeaderSelectionStartIntent(
        header: details.headerPosition,
        axis: widget.axis,
      ),
    );
  }

  /// Handles updates to a ongoing drag operation. It updates the last selection
  /// to a header selection.
  void handleUpdateSelection(_HeaderGestureDetails details) {
    Actions.invoke(
      context,
      HeaderSelectionUpdateIntent(
        header: details.headerPosition,
        axis: widget.axis,
      ),
    );
  }

  /// Handles drag starts that should start dragging a header around.
  void handleStartDraggingHeader(
    DragStartDetails details,
    Range selectionRange,
  ) {
    // Sets the dragging cursor to be basic.
    // Instead of using [SystemMouseCursors.grabbing], we set the basic cursors
    // because currently there is no mechanism to globally change the cursor on
    // desktop, this means that the cursor would be a closed hand only when
    // hovering the header, which would cause a weird change of cursors during
    // a drag action, making the user think that something went wrong with the
    // action.
    setCursorState(SystemMouseCursors.basic);
    Actions.invoke(
      context,
      HeaderDragStartIntent(
        draggingPosition: details.localPosition,
        headers: selectionRange,
        axis: widget.axis,
      ),
    );
  }

  /// Handles header dragging updates.
  void handleUpdateDraggingHeader(
    DragUpdateDetails gestureDetails,
    _HeaderGestureDetails details,
  ) {
    Actions.invoke(
      context,
      HeaderDragUpdateIntent(
        draggingPosition: gestureDetails.localPosition,
        header: details.headerPosition,
        axis: widget.axis,
      ),
    );
  }

  void handleDragEnd(SwayzeHeaderDragState state) {
    if (state.isDropAllowed) {
      Actions.invoke(
        context,
        HeaderDragEndIntent(
          header: state.dropAtIndex,
          axis: widget.axis,
        ),
      );
    } else {
      handleDragCancel();
    }
  }

  void handleDragCancel() {
    Actions.invoke(
      context,
      HeaderDragCancelIntent(widget.axis),
    );
  }

  /// Sets a new cursor state.
  void setCursorState(MouseCursor newCursor) {
    if (newCursor != cursor) {
      setState(() => cursor = newCursor);
    }
  }

  /// Checks if a header is selected.
  bool isHeaderSelected(int position, Axis axis) =>
      internalScope.controller.selection.isHeaderSelected(position, axis);

  /// Finds the selection that is under position.
  ///
  /// Returns null if position header is not selected.
  HeaderUserSelectionModel? hoverSelection(int position, Axis axis) {
    final selectionController = internalScope.controller.selection;
    final selections = selectionController.userSelectionState.selections
        .whereType<HeaderUserSelectionModel>();

    for (final selection in selections) {
      if (selection.axis == axis) {
        final range = Range(selection.start, selection.end);
        if (range.contains(position)) {
          return selection;
        }
      }
    }
    return null;
  }

  /// Finds the range of the current reference selection and all adjacent
  /// selections.
  ///
  /// Returns a range containing all adjacent selections from the reference
  /// selection, so it can be dragged as a single group.
  Range headerSelectionRange(HeaderUserSelectionModel referenceSelection) {
    final selectionController = internalScope.controller.selection;
    final selections = selectionController.userSelectionState.selections
        .whereType<HeaderUserSelectionModel>();

    var selectionRange =
        Range(referenceSelection.start, referenceSelection.end);

    final sortedSelections = selections
        .where((selection) => selection.axis == referenceSelection.axis)
        .sorted((lhs, rhs) => lhs.start.compareTo(rhs.start));

    final selectionIndex = sortedSelections.indexOf(referenceSelection);

    void updateAdjacentSelection(HeaderUserSelectionModel selection) {
      if (selection.end == selectionRange.start ||
          selection.start == selectionRange.end ||
          (selection & selectionRange).isNotNil) {
        selectionRange = Range(
          min(selectionRange.start, selection.start),
          max(selectionRange.end, selection.end),
        );
      }
    }

    for (var i = selectionIndex; i >= 0; i--) {
      updateAdjacentSelection(sortedSelections.elementAt(i));
    }
    for (var i = selectionIndex; i < sortedSelections.length; i++) {
      updateAdjacentSelection(sortedSelections.elementAt(i));
    }
    return selectionRange;
  }

  /// Checks if a header is being dragged.
  bool isDraggingHeader() {
    final tableDataController = internalScope.controller.tableDataController;
    final header =
        tableDataController.getHeaderControllerFor(axis: widget.axis);
    return header.value.dragState != null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      onHover: (event) {
        if (!internalScope.config.isHeaderDragAndDropEnabled) {
          return;
        }

        final headerGestureDetails = _getHeaderLocalPositionGestureDetails(
          axis: widget.axis,
          context: context,
          localPosition: event.localPosition,
        );
        final isSelected = isHeaderSelected(
          headerGestureDetails.headerPosition,
          widget.axis,
        );
        setCursorState(
          isSelected ? SystemMouseCursors.grab : MouseCursor.defer,
        );
      },
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(debugOwner: this),
            (PanGestureRecognizer instance) {
              instance.onStart = (DragStartDetails details) {
                if (resizeNotifier?.isHoveringHeaderEdge ?? false) {
                  return;
                }

                final headerGestureDetails = _getHeaderGestureDetails(
                  axis: widget.axis,
                  context: context,
                  globalPosition: details.globalPosition,
                );

                final selection = hoverSelection(
                  headerGestureDetails.headerPosition,
                  widget.axis,
                );

                if (selection != null &&
                    internalScope.config.isHeaderDragAndDropEnabled) {
                  final range = headerSelectionRange(selection);
                  handleStartDraggingHeader(details, range);
                } else {
                  handleStartSelection(headerGestureDetails);
                }

                dragOriginOffsetCache = headerGestureDetails.localPosition;
              };
              instance.onUpdate = (DragUpdateDetails details) {
                if (resizeNotifier?.isResizingHeader ?? false) {
                  return;
                }

                final headerGestureDetails = _getHeaderGestureDetails(
                  axis: widget.axis,
                  context: context,
                  globalPosition: details.globalPosition,
                );

                updateDragScroll(
                  localOffset: headerGestureDetails.localPosition,
                  globalOffset: details.globalPosition,
                  originOffset: dragOriginOffsetCache!,
                );

                if (isDraggingHeader()) {
                  handleUpdateDraggingHeader(details, headerGestureDetails);
                  return;
                }
                handleUpdateSelection(headerGestureDetails);
              };
              instance.onEnd = (DragEndDetails details) {
                if (resizeNotifier?.isResizingHeader ?? false) {
                  return;
                }

                dragOriginOffsetCache = null;
                internalScope.controller.scroll.stopAutoScroll(widget.axis);

                final tableDataController =
                    internalScope.controller.tableDataController;
                final header = tableDataController
                    .getHeaderControllerFor(
                      axis: widget.axis,
                    )
                    .value;
                if (header.dragState != null) {
                  handleDragEnd(header.dragState!);
                }
              };
              instance.onCancel = () {
                if (resizeNotifier?.isResizingHeader ?? false) {
                  return;
                }

                dragOriginOffsetCache = null;
                internalScope.controller.scroll.stopAutoScroll(widget.axis);

                if (isDraggingHeader()) {
                  handleDragCancel();
                }
              };
            },
          ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (TapGestureRecognizer instance) {
              instance.onTapUp = (TapUpDetails details) {
                if (resizeNotifier?.isHoveringHeaderEdge ?? false) {
                  return;
                }

                final headerGestureDetails = _getHeaderGestureDetails(
                  axis: widget.axis,
                  context: context,
                  globalPosition: details.globalPosition,
                );
                handleStartSelection(headerGestureDetails);
              };
            },
          ),
        },
        behavior: HitTestBehavior.translucent,
      ),
    );
  }
}
