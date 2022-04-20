import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../intents.dart';
import '../../../core/viewport_context/viewport_context.dart';
import '../../../core/viewport_context/viewport_context_provider.dart';
import '../../../helpers/scroll/auto_scroll.dart';
import '../../internal_scope.dart';

/// A transport class for auxiliary data about a table body gesture and it's
/// position.
@immutable
class _TableGestureDetails {
  final Offset localPosition;
  final IntVector2 cellCoordinate;

  const _TableGestureDetails({
    required this.localPosition,
    required this.cellCoordinate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TableGestureDetails &&
          runtimeType == other.runtimeType &&
          localPosition == other.localPosition &&
          cellCoordinate == other.cellCoordinate;

  @override
  int get hashCode => localPosition.hashCode ^ cellCoordinate.hashCode;
}

/// Given a [globalPosition] it creates a [_TableGestureDetails] with the
/// converted [localPosition] and the corresponding [IntVector2] for the
/// cell coordinates.
///
/// It considers the offscreen details to ensure that we can properly expand
/// the table with the "elastic" table feature.
_TableGestureDetails _getTableGestureDetails(
  BuildContext context,
  Offset globalPosition,
) {
  final tableDataController =
      InternalScope.of(context).controller.tableDataController;
  final viewportContext = ViewportContextProvider.of(context);

  /// Local function to get cordinates with aditional ofscreen offset in a given
  /// [axis].
  int _getCoordinateWithAditionalOffset({
    required Axis axis,
    required PositionResult positionResult,
    required double localPosition,
  }) {
    var result = positionResult.position;
    if (positionResult.overflow == OffscreenDetails.trailing) {
      final diff = localPosition -
          viewportContext.getAxisContextFor(axis: axis).value.extent;
      final defaultExtent = tableDataController
          .getHeaderControllerFor(axis: axis)
          .value
          .defaultHeaderExtent;

      final additionalAmount = (diff / defaultExtent).ceil();
      result += additionalAmount;
    }

    return result;
  }

  final box = context.findRenderObject()! as RenderBox;
  final localPosition = box.globalToLocal(globalPosition);
  final positionResultX = viewportContext.pixelToPosition(
    localPosition.dx,
    Axis.horizontal,
  );

  final positionResultY = viewportContext.pixelToPosition(
    localPosition.dy,
    Axis.vertical,
  );

  return _TableGestureDetails(
    localPosition: localPosition,
    cellCoordinate: IntVector2(
      _getCoordinateWithAditionalOffset(
        axis: Axis.horizontal,
        positionResult: positionResultX,
        localPosition: localPosition.dx,
      ),
      _getCoordinateWithAditionalOffset(
        axis: Axis.vertical,
        positionResult: positionResultY,
        localPosition: localPosition.dy,
      ),
    ),
  );
}

/// Return the [Range] edge to expand according to the given [ScrollDirection].
int _getRangeEdgeOnAutoScroll(Range range, ScrollDirection scrolDirection) {
  if (scrolDirection == ScrollDirection.forward) {
    return range.start;
  }

  return range.end - 1;
}

class TableBodyGestureDetector extends StatefulWidget {
  final double horizontalDisplacement;
  final double verticalDisplacement;

  const TableBodyGestureDetector({
    Key? key,
    required this.horizontalDisplacement,
    required this.verticalDisplacement,
  }) : super(key: key);

  @override
  _TableBodyGestureDetectorState createState() =>
      _TableBodyGestureDetectorState();
}

class _TableBodyGestureDetectorState extends State<TableBodyGestureDetector> {
  late final InternalScope internalScope;
  late final ViewportContext viewportContext;

  late ViewportAxisContextState columnsState;
  late ViewportAxisContextState rowsState;

  /// Cache to make the position of the start of a drag gesture acessible in
  /// the drag updates.
  Offset? dragOriginOffsetCache;

  /// Tracks the latest cell to be hovered during a drag gesture, expected to be
  /// valued during a drag gesture and null otherwise.
  IntVector2? cachedDragCellCoordinate;

  /// Tracks cell to be tapped
  IntVector2? tapDownCoordinateCache;

  @override
  void initState() {
    super.initState();
    internalScope = InternalScope.of(context);
    viewportContext = ViewportContextProvider.of(context);
    viewportContext.columns.addListener(onRangesChanged);
    viewportContext.rows.addListener(onRangesChanged);
  }

  @override
  void dispose() {
    viewportContext.columns.removeListener(onRangesChanged);
    viewportContext.rows.removeListener(onRangesChanged);

    super.dispose();
  }

  /// Listen for [ViewportContext] range changes to update selections in case
  /// a [AutoScrollActivity] is in progress.
  void onRangesChanged() {
    final scrollController = internalScope.controller.scroll;

    final cachedDragCellCoordinate = this.cachedDragCellCoordinate;

    if (cachedDragCellCoordinate == null) {
      return;
    }

    final horizontalScrollPosition =
        scrollController.horizontalScrollController!.position;
    final verticalScrollPosition =
        scrollController.verticalScrollController!.position;

    handleDragUpdate(
      IntVector2(
        horizontalScrollPosition.userScrollDirection != ScrollDirection.idle
            ? _getRangeEdgeOnAutoScroll(
                viewportContext.columns.value.scrollableRange,
                horizontalScrollPosition.userScrollDirection,
              )
            : cachedDragCellCoordinate.dx,
        verticalScrollPosition.userScrollDirection != ScrollDirection.idle
            ? _getRangeEdgeOnAutoScroll(
                viewportContext.rows.value.scrollableRange,
                verticalScrollPosition.userScrollDirection,
              )
            : cachedDragCellCoordinate.dy,
      ),
    );
  }

  /// Given the current [localOffset] and [globalOffset] check if a
  /// [AutoScrollActivity] should be triggered and which directions.
  ///
  /// When moving to the negative side of each axis (up or left) the scroll
  /// activity kicks in when the mouse is before the displacement, ie. in
  /// practical terms, the scroll starts when we hover one of the headers.
  ///
  /// When moving to the positive side (right or down) theres a
  /// [_autoScrollTriggerThreshold] where the scroll kicks in before we reach
  /// the edge of the table.
  ///
  /// When moving down it checks if the [globalOffset] is within the
  /// scrollThreshold gap at the screen's height edge.
  ///
  /// When moving right, since there might be a sidepanel open on the right, it
  /// cannot follow the same approach as when moving down. It checks if the
  /// [localOffset] is within the [kRowHeaderWidth] +
  /// [_autoScrollTriggerThreshold] gap at the [ViewportContext] extend.
  ///
  /// See also:
  /// - HeaderGestureDetector's updateAutoScroll, which is similar to this
  /// method but its related with headers but can only scroll in it's widgets
  /// configured axis.
  void updateDragScroll({
    required Offset originOffset,
    required Offset localOffset,
    required Offset globalOffset,
    required Size screenSize,
  }) {
    final scrollController = internalScope.controller.scroll;

    final horizontalDragScrollData = getHorizontalDragScrollData(
      displacement: widget.horizontalDisplacement,
      globalOffset: globalOffset.dx,
      localOffset: localOffset.dx,
      gestureOriginOffset: originOffset.dx,
      screenWidth: screenSize.width,
      viewportExtent: viewportContext
          .columns.virtualizationState.scrollingData.viewportExtent,
      frozenExtent: viewportContext.columns.value.frozenExtent,
    );

    final verticalDragScrollData = getVerticalDragScrollData(
      displacement: widget.verticalDisplacement,
      globalOffset: globalOffset.dy,
      localOffset: localOffset.dy,
      gestureOriginOffset: originOffset.dy,
      positionPixel: scrollController.verticalScrollController!.position.pixels,
      screenHeight: MediaQuery.of(context).size.height,
      scrollingData: viewportContext.rows.virtualizationState.scrollingData,
      viewportExtent: viewportContext.rows.value.extent,
      frozenExtent: viewportContext.rows.value.frozenExtent,
    );

    if (horizontalDragScrollData is AutoScrollDragScrollData) {
      // auto scroll
      scrollController.startOrUpdateAutoScroll(
        direction: horizontalDragScrollData.direction,
        pointerDistance: horizontalDragScrollData.pointerDistance,
      );
    } else if (horizontalDragScrollData is ResetScrollDragScrollData) {
      // reset scroll

      scrollController.jumpToHeader(
        viewportContext.columns.value.frozenRange.end,
        Axis.horizontal,
      );
    } else {
      // do not scroll
      scrollController.stopAutoScroll(Axis.horizontal);
    }

    if (verticalDragScrollData is AutoScrollDragScrollData) {
      scrollController.startOrUpdateAutoScroll(
        direction: verticalDragScrollData.direction,
        maxToScroll: verticalDragScrollData.maxToScroll,
        pointerDistance: verticalDragScrollData.pointerDistance,
      );
    } else if (verticalDragScrollData is ResetScrollDragScrollData) {
      // reset scroll

      scrollController.jumpToHeader(
        viewportContext.rows.value.frozenRange.end,
        Axis.vertical,
      );
    } else {
      scrollController.stopAutoScroll(Axis.vertical);
    }
  }

  /// Handles taps/drag starts that should start a selection.
  /// Given a [_TableGestureDetails] it creates or updates a selection
  /// based on the modifiers that the user is pressing.
  void handleStartSelection(_TableGestureDetails details) {
    Actions.invoke(
      context,
      TableBodySelectionStartIntent(details.cellCoordinate),
    );
  }

  /// Handles updates to a ongoing drag operation. It updates the last selection
  /// to a cell selection.
  void handleDragUpdate(IntVector2 cellCoordinate) {
    if (cellCoordinate == cachedDragCellCoordinate) {
      return;
    }
    Actions.invoke(context, TableBodySelectionUpdateIntent(cellCoordinate));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final biggest = constraints.biggest;
        final screenSize = Size(
          biggest.width - widget.horizontalDisplacement,
          biggest.height - widget.verticalDisplacement,
        );
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (details) {
            final isMouse = details.kind == PointerDeviceKind.mouse;
            final isPrimaryMouseButton = details.buttons == kPrimaryMouseButton;

            final shouldReact = !isMouse || isPrimaryMouseButton;

            if (!shouldReact) {
              return;
            }

            final tableGestureDetails = _getTableGestureDetails(
              context,
              details.position,
            );

            tapDownCoordinateCache = tableGestureDetails.cellCoordinate;

            handleStartSelection(tableGestureDetails);
          },
          child: RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              PanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                () => PanGestureRecognizer(debugOwner: this),
                (PanGestureRecognizer instance) {
                  instance
                    ..onStart = (DragStartDetails details) {
                      final tableGestureDetails = _getTableGestureDetails(
                        context,
                        details.globalPosition,
                      );
                      cachedDragCellCoordinate =
                          tableGestureDetails.cellCoordinate;
                      handleStartSelection(tableGestureDetails);

                      dragOriginOffsetCache = tableGestureDetails.localPosition;
                    }
                    ..onUpdate = (DragUpdateDetails details) {
                      final tableGestureDetails = _getTableGestureDetails(
                        context,
                        details.globalPosition,
                      );

                      handleDragUpdate(tableGestureDetails.cellCoordinate);

                      cachedDragCellCoordinate =
                          tableGestureDetails.cellCoordinate;
                      updateDragScroll(
                        localOffset: tableGestureDetails.localPosition,
                        globalOffset: details.globalPosition,
                        originOffset: dragOriginOffsetCache!,
                        screenSize: screenSize,
                      );
                    }
                    ..onEnd = (DragEndDetails details) {
                      final scrollController = internalScope.controller.scroll;
                      scrollController.stopAutoScroll(Axis.vertical);
                      scrollController.stopAutoScroll(Axis.horizontal);
                      cachedDragCellCoordinate = null;
                      dragOriginOffsetCache = null;
                    }
                    ..onCancel = () {
                      final scrollController = internalScope.controller.scroll;
                      scrollController.stopAutoScroll(Axis.vertical);
                      scrollController.stopAutoScroll(Axis.horizontal);
                      cachedDragCellCoordinate = null;
                      dragOriginOffsetCache = null;
                    };
                },
              ),
              DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  DoubleTapGestureRecognizer>(
                () => DoubleTapGestureRecognizer(debugOwner: this),
                (DoubleTapGestureRecognizer instance) {
                  instance
                    ..onDoubleTapDown = (TapDownDetails details) {
                      // Get the coordinate in which the double tap gesture is
                      // effective to. Equals to the position of the first tap
                      final gestureCoordinate = _getTableGestureDetails(
                        context,
                        details.globalPosition,
                      ).cellCoordinate;

                      // If the fist and second tap were made over different
                      // cells, do nothing.
                      if (tapDownCoordinateCache != gestureCoordinate) {
                        return;
                      }

                      Actions.invoke(
                        context,
                        OpenInlineEditorIntent(cellPosition: gestureCoordinate),
                      );
                    };
                },
              ),
            },
            behavior: HitTestBehavior.translucent,
          ),
        );
      },
    );
  }
}
