import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../../widgets.dart';
import '../../../../core/viewport_context/viewport_context_provider.dart';
import '../../../internal_scope.dart';
import 'resize_header_details_notifier.dart';
import 'resize_line_overlay_manager.dart';

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
  late final resizeNotifier = ValueNotifier<ResizeHeaderDetails?>(null);
  late final internalScope = InternalScope.of(context);
  late final viewportContext = ViewportContextProvider.of(context);

  late final resizeLineOverlayManager = ResizeLineOverlayManager(
    internalScope: internalScope,
    resizeNotifier: resizeNotifier,
  );

  MouseCursor _getMouseCursor(ResizeHeaderDetails? resizeHeaderDetails) {
    if (resizeHeaderDetails == null) {
      return MouseCursor.defer;
    }

    return resizeHeaderDetails.axis == Axis.horizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;
  }

  /// Gets the pixel offset for the given [offset] and [axis].
  double _getOffsetPositionForAxis(Offset offset, Axis axis) {
    return axis == Axis.horizontal ? offset.dx : offset.dy;
  }

  /// Checks if the mouse coordinates are at an header edge.
  ///
  /// In case it does, it updates [_resizeNotifier.value].
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

  bool _updateHeaderEdgeDetails({
    required Offset localPosition,
    required Axis axis,
  }) {
    var localPixelOffset = _getOffsetPositionForAxis(localPosition, axis);

    final axisContext = viewportContext.getAxisContextFor(axis: axis);

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
        localPixelOffset < frozenExtent + 2;

    if (!ignoreDisplacement) {
      localPixelOffset += displacement.abs();
    }

    localPixelOffset = localPixelOffset.ceilToDouble();

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
      axis == Axis.horizontal ? kDefaultCellWidth : kDefaultCellHeight;

  void _handleOnPointerDown(PointerDownEvent event) {
    if (!isResizingEnabled) {
      return;
    }

    final details = resizeNotifier.value!;
    final axis = details.axis;

    final initialOffset = _getOffsetPositionForAxis(event.localPosition, axis) +
        details.edgeInfo.displacement;

    final minOffset =
        initialOffset - (details.edgeInfo.width - minExtent(axis));

    resizeNotifier.value = details.copyWith(
      offset: initialOffset,
      initialOffset: initialOffset,
      minOffset: minOffset,
    );

    resizeLineOverlayManager.insertEntries(context);
  }

  void _handleOnPointerMove(PointerMoveEvent event) {
    if (!didResizingStart) {
      return;
    }

    final details = resizeNotifier.value!;
    final axis = details.axis;
    final offset = details.offset!;

    final newOffset = offset + _getOffsetPositionForAxis(event.delta, axis);

    resizeNotifier.value = details.copyWith(offset: newOffset);
  }

  void _handleOnPointerUp(PointerUpEvent event) {
    if (!didResizingStart) {
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

    headerController.updateState(
      (previousState) => headerController.value.setHeaderExtent(
        index,
        newExtent,
      ),
    );

    widget.onHeaderExtentChanged?.call(index, axis, extent, newExtent);

    resizeNotifier.value = null;

    resizeLineOverlayManager.removeEntries();
  }

  bool get isResizingEnabled => resizeNotifier.value?.edgeInfo.index != null;

  bool get didResizingStart => resizeNotifier.value?.offset != null;

  @override
  Widget build(BuildContext context) {
    return ResizeHeaderDetailsNotifier(
      notifier: resizeNotifier,
      child: Listener(
        onPointerDown: _handleOnPointerDown,
        onPointerMove: _handleOnPointerMove,
        onPointerUp: _handleOnPointerUp,
        // TODO(nfsxreloader): optimize builds
        child: ValueListenableBuilder<ResizeHeaderDetails?>(
          valueListenable: resizeNotifier,
          builder: (context, resizeHeaderDetails, child) {
            return MouseRegion(
              cursor: _getMouseCursor(resizeHeaderDetails),
              onHover: _handleOnHover,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
