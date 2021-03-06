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
int _getRangeEdgeOnAutoScroll(Range range, ScrollDirection scrolDirection) {
  if (scrolDirection == ScrollDirection.forward) {
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

  /// Cache to make the position of the start of a drag gesture acessible in
  /// the drag updates.
  Offset? dragOriginOffsetCache;

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

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(debugOwner: this),
          (PanGestureRecognizer instance) {
            instance.onStart = (DragStartDetails details) {
              final headerGestureDetails = _getHeaderGestureDetails(
                axis: widget.axis,
                context: context,
                globalPosition: details.globalPosition,
              );

              handleStartSelection(headerGestureDetails);

              dragOriginOffsetCache = headerGestureDetails.localPosition;
            };
            instance.onUpdate = (DragUpdateDetails details) {
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

              handleUpdateSelection(headerGestureDetails);
            };
            instance.onEnd = (DragEndDetails details) {
              dragOriginOffsetCache = null;
              internalScope.controller.scroll.stopAutoScroll(widget.axis);
            };
            instance.onCancel = () {
              dragOriginOffsetCache = null;
              internalScope.controller.scroll.stopAutoScroll(widget.axis);
            };
          },
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(debugOwner: this),
          (TapGestureRecognizer instance) {
            instance.onTapDown = (TapDownDetails details) {
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
    );
  }
}
