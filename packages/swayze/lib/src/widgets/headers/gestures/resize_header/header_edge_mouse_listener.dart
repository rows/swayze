import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../../helpers.dart';
import '../../../../../widgets.dart';
import '../../../../core/viewport_context/viewport_context_provider.dart';
import '../../../internal_scope.dart';
import 'resize_header_details_notifier.dart';
import 'resize_line_overlay_manager.dart';

/// A class that returns a mouse region that changes the mouse cursor to
/// [SystemMouseCursors.resizeColumn] or [SystemMouseCursors.resizeRow],
/// depending on the axis, when the user is hovering an header edge.
///
/// It also has a listener that takes care of showing the resize line when
/// the user taps the mouse button. Updating the resize line when the user
/// moves the mouse cursor. Updating the header extent when the user lets go
/// the mouse button.
class HeaderEdgeMouseListener extends StatefulWidget {
  final OnHeaderExtentChanged? onHeaderExtentChanged;
  final Widget child;

  const HeaderEdgeMouseListener({
    Key? key,
    required this.onHeaderExtentChanged,
    required this.child,
  }) : super(key: key);

  @override
  State<HeaderEdgeMouseListener> createState() =>
      _HeaderEdgeMouseListenerState();
}

class _HeaderEdgeMouseListenerState extends State<HeaderEdgeMouseListener> {
  late final resizeNotifier = ResizeHeaderDetailsNotifier(null);
  late final internalScope = InternalScope.of(context);
  late final viewportContext = ViewportContextProvider.of(context);

  late final resizeLineOverlayManager = ResizeLineOverlayManager(
    internalScope: internalScope,
    resizeNotifier: resizeNotifier,
  );

  bool _showResizeCursor = false;

  @override
  void initState() {
    super.initState();

    resizeNotifier.addListener(_didHoverHeaderEdge);
    _didHoverHeaderEdge();
  }

  @override
  void dispose() {
    resizeNotifier.removeListener(_didHoverHeaderEdge);

    super.dispose();
  }

  /// Update the resize cursor if the user is hovering an header edge.
  void _didHoverHeaderEdge() {
    final showResizeCursor = resizeNotifier.value != null;

    if (showResizeCursor == _showResizeCursor) {
      return;
    }

    setState(() {
      _showResizeCursor = showResizeCursor;
    });
  }

  MouseCursor _getMouseCursor() {
    if (!_showResizeCursor) {
      return MouseCursor.defer;
    }

    return resizeNotifier.value!.axis == Axis.horizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;
  }

  /// Gets the pixel offset for the given [offset] and [axis].
  double _getOffsetPositionForAxis(Offset offset, Axis axis) {
    return axis == Axis.horizontal ? offset.dx : offset.dy;
  }

  /// Checks if the mouse coordinates are at an header edge.
  void _handleOnHover(PointerHoverEvent event) {
    Axis? axis;

    // vertical header is being hovered
    if (event.localPosition.dy > kColumnHeaderHeight &&
        event.localPosition.dx < kRowHeaderWidth) {
      axis = Axis.vertical;
    }

    // horizontal header is being hovered
    if (event.localPosition.dy < kColumnHeaderHeight) {
      axis = Axis.horizontal;
    }

    if (axis != null) {
      final result = _updateHeaderEdgeDetails(
        localPosition: event.localPosition,
        axis: axis,
      );

      if (result) {
        return;
      }
    }

    resizeNotifier.value = null;
  }

  /// Updates [resizeNotifier.value] if the user is hovering an headers edge.
  ///
  /// Returns `true` if [resizeNotifier.value] has been updated and `false`
  /// otherwise.
  bool _updateHeaderEdgeDetails({
    required Offset localPosition,
    required Axis axis,
  }) {
    var localPixelOffset = _getOffsetPositionForAxis(localPosition, axis);

    final axisContext = viewportContext.getAxisContextFor(axis: axis);

    // since this widget will be placed at a table, we need to take into account
    // that from `0` to `kRowHeaderWidth` or `kColumnHeaderHeight` (depending on
    // the axis), there's an empty space. Since the `localPosition` will still
    // count that into its offset, we subtract that extent.
    if (axis == Axis.horizontal) {
      localPixelOffset -= kRowHeaderWidth;
    } else {
      localPixelOffset -= kColumnHeaderHeight;
    }

    final frozenExtent = axisContext.value.frozenExtent;
    final hasFrozenHeaders = frozenExtent > 0;
    final displacement = axisContext.virtualizationState.displacement;

    final ignoreDisplacement = hasFrozenHeaders &&
        displacement < 0 &&
        // since hovering the last frozen header separator plus
        // `kMaxEdgeOffsetAdder` also counts as hovering the frozen header,
        // we take into account the frozen headers extent and
        // `kMaxEdgeOffsetAdder`.
        localPixelOffset < frozenExtent + kMaxEdgeOffsetAdder;

    // we need to ignore the `displacement` in frozen headers since they are
    // fixed when we scroll.
    if (!ignoreDisplacement) {
      localPixelOffset += displacement.abs();
    }

    localPixelOffset = localPixelOffset.floorToDouble();

    final offsets = axisContext.value.headersEdgesOffsets;

    if (offsets.containsKey(localPixelOffset)) {
      final headerEdgeInfo = offsets[localPixelOffset]!;

      resizeNotifier.value = ResizeHeaderDetails(
        edgeInfo: headerEdgeInfo,
        axis: axis,
      );

      return true;
    }

    return false;
  }

  double minExtent(Axis axis) =>
      axis == Axis.horizontal ? kMinCellWidth : kDefaultCellHeight;

  /// Inserts an [OverlayEntry] to the current [OverlayState] with resize line
  /// on it at the header edge that is being hovered.
  void _handleOnPointerDown(PointerDownEvent event) {
    if (!resizeNotifier.isHoveringHeaderEdge) {
      return;
    }

    final details = resizeNotifier.value!;
    final axis = details.axis;

    final initialOffset = _getOffsetPositionForAxis(event.localPosition, axis) +
        details.edgeInfo.displacement;

    final minOffset =
        initialOffset - (details.edgeInfo.width - minExtent(axis));

    resizeNotifier.value = details.copyWith(
      offset: Wrapped.value(initialOffset),
      initialOffset: Wrapped.value(initialOffset),
      minOffset: Wrapped.value(minOffset),
    );

    resizeLineOverlayManager.insertResizeLine(context);
  }

  /// Updates the resize line position by adding [event.delta] to
  /// its current position.
  void _handleOnPointerMove(PointerMoveEvent event) {
    if (!resizeNotifier.isResizingHeader) {
      return;
    }

    final details = resizeNotifier.value!;
    final axis = details.axis;
    final offset = details.offset!;

    final newOffset = offset + _getOffsetPositionForAxis(event.delta, axis);

    resizeNotifier.value = details.copyWith(offset: Wrapped.value(newOffset));
  }

  /// Sets the header extent of the header that has been resized and removes the
  /// [OverlayEntry] that contains the resize line.
  void _handleOnPointerUp(PointerUpEvent event) {
    if (!resizeNotifier.isResizingHeader) {
      return;
    }

    final value = resizeNotifier.value!;
    final axis = value.axis;

    final headerController = internalScope.controller.tableDataController
        .getHeaderControllerFor(axis: axis);

    final index = value.edgeInfo.index;
    final initialOffset = value.initialOffset!;
    final offset = value.offset!;
    final extent = value.edgeInfo.width;

    double newExtent;

    if (offset < initialOffset) {
      newExtent = max(minExtent(axis), extent - (initialOffset - offset));
    } else {
      newExtent = extent + (offset - initialOffset);
    }

    newExtent = newExtent.floorToDouble();

    headerController.updateState(
      (previousState) => headerController.value.setHeaderExtent(
        index,
        newExtent,
      ),
    );

    if (extent != newExtent) {
      widget.onHeaderExtentChanged?.call(index, axis, extent, newExtent);
    }

    resizeNotifier.value = null;

    resizeLineOverlayManager.removeResizeLine(context);
  }

  @override
  Widget build(BuildContext context) {
    return ResizeHeaderDetailsNotifierProvider(
      notifier: resizeNotifier,
      child: Listener(
        onPointerDown: _handleOnPointerDown,
        onPointerMove: _handleOnPointerMove,
        onPointerUp: _handleOnPointerUp,
        child: MouseRegion(
          cursor: _getMouseCursor(),
          onHover: _handleOnHover,
          child: widget.child,
        ),
      ),
    );
  }
}
