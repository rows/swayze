import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../intents.dart';
import '../../../core/controller/selection/selection_controller.dart';
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
  final bool dragAndFill;

  const _TableGestureDetails({
    required this.localPosition,
    required this.cellCoordinate,
    required this.dragAndFill,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TableGestureDetails &&
          runtimeType == other.runtimeType &&
          localPosition == other.localPosition &&
          cellCoordinate == other.cellCoordinate &&
          dragAndFill == other.dragAndFill;

  @override
  int get hashCode =>
      localPosition.hashCode ^ cellCoordinate.hashCode ^ dragAndFill.hashCode;

  @override
  String toString() => '_TableGestureDetails{'
      'localPosition: $localPosition'
      ', cellCoordinate: $cellCoordinate'
      ', dragAndFill: $dragAndFill'
      '}';
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
  final viewportContext = ViewportContextProvider.of(context);
  final internalScope = InternalScope.of(context);

  final tableDataController = internalScope.controller.tableDataController;

  /// Local function to get coordinates with additional offscreen offset in a
  /// given [axis].
  int _getCoordinateWithAdditionalOffset({
    required Axis axis,
    required int position,
    required OffscreenDetails overflow,
    required double localPosition,
  }) {
    var result = position;

    if (overflow == OffscreenDetails.trailing) {
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

  final hoverResult = viewportContext.evaluateHover(localPosition);

  return _TableGestureDetails(
    localPosition: localPosition,
    dragAndFill: hoverResult.canFillCell,
    cellCoordinate: IntVector2(
      _getCoordinateWithAdditionalOffset(
        axis: Axis.horizontal,
        position: hoverResult.cell.dx,
        overflow: hoverResult.overflowX,
        localPosition: localPosition.dx,
      ),
      _getCoordinateWithAdditionalOffset(
        axis: Axis.vertical,
        position: hoverResult.cell.dy,
        overflow: hoverResult.overflowY,
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

  /// Caches the drag gesture, as the tap down may be on a fill handle and
  /// we should know the correct cell to use as anchor to a fill and drag
  /// operation.
  _TableGestureDetails? _cachedDragGestureDetails;

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
      TableBodySelectionStartIntent(
        details.cellCoordinate,
        fill: details.dragAndFill,
      ),
    );
  }

  /// Handles updates to a ongoing drag operation. It updates the last selection
  /// to a cell selection.
  void handleDragUpdate(IntVector2 cellCoordinate) {
    if (cellCoordinate == cachedDragCellCoordinate) {
      return;
    }

    Actions.invoke(
      context,
      TableBodySelectionUpdateIntent(cellCoordinate),
    );
  }

  /// Handles the end to a ongoing drag operation.
  void handleDragEnd() {
    Actions.invoke(
      context,
      const TableBodySelectionEndIntent(),
    );
  }

  /// Handles the cancelling of an ongoing drag operation.
  void handleDragCancel() {
    if (mounted) {
      Actions.invoke(
        context,
        const TableBodySelectionCancelIntent(),
      );
    }
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

            // Cache the gesture for a possible drag.
            _cachedDragGestureDetails = tableGestureDetails;

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
                      // Uses the cached drag if one exists.
                      final tableGestureDetails = _cachedDragGestureDetails ??
                          _getTableGestureDetails(
                            context,
                            details.globalPosition,
                          );

                      cachedDragCellCoordinate =
                          tableGestureDetails.cellCoordinate;

                      _cachedDragGestureDetails = tableGestureDetails;

                      // Does not start one if we have the cache drag already
                      // which means we already started on the onPointerDown.
                      if (_cachedDragGestureDetails == null) {
                        handleStartSelection(tableGestureDetails);
                      }

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
                      _endDrag(cancelled: false);
                    }
                    ..onCancel = () => _endDrag(cancelled: true);
                },
              ),
              DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  DoubleTapGestureRecognizer>(
                () => DoubleTapGestureRecognizer(debugOwner: this),
                (DoubleTapGestureRecognizer instance) {
                  instance
                    ..onDoubleTapDown = (TapDownDetails details) {
                      final tableGestureDetails = _getTableGestureDetails(
                        context,
                        details.globalPosition,
                      );

                      // Get the coordinate in which the double tap gesture is
                      // effective to. Equals to the position of the first tap
                      final gestureCoordinate =
                          tableGestureDetails.cellCoordinate;

                      // If the fist and second tap were made over different
                      // cells, do nothing.
                      if (tapDownCoordinateCache != gestureCoordinate) {
                        return;
                      }

                      if (tableGestureDetails.dragAndFill) {
                        final primary = internalScope.controller.selection
                            .userSelectionState.primarySelection;

                        if (primary is! CellUserSelectionModel) {
                          return;
                        }

                        Actions.invoke(
                          context,
                          FillIntoUnknownIntent(source: primary),
                        );

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

  void _endDrag({
    required bool cancelled,
  }) {
    internalScope.controller.scroll
      ..stopAutoScroll(Axis.vertical)
      ..stopAutoScroll(Axis.horizontal);

    cachedDragCellCoordinate = null;
    dragOriginOffsetCache = null;
    _cachedDragGestureDetails = null;

    cancelled ? handleDragCancel() : handleDragEnd();
  }
}
