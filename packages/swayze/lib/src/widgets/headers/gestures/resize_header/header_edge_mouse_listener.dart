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

  double? _initialOffset;

  MouseCursor _getMouseCursor() {
    if (resizeNotifier.value == null) {
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
  ///
  /// In case it does, it updates [_resizeNotifier.value].
  void _handleOnHover(PointerHoverEvent event) {
    Axis? axis;

    final isRowHeaderBeingHovered =
        event.localPosition.dy > kColumnHeaderHeight &&
            event.localPosition.dx < kRowHeaderWidth;

    final isColumnHeaderBeingHovered =
        event.localPosition.dy < kColumnHeaderHeight;

    if (isRowHeaderBeingHovered) {
      axis = Axis.vertical;
    } else if (isColumnHeaderBeingHovered) {
      axis = Axis.horizontal;
    }

    if (axis == null) {
      return resizeNotifier.value = null;
    }

    final result = _updateHeaderEdgeDetails(
      localPosition: event.localPosition,
      axis: axis,
    );

    if (result) {
      return;
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
      final index = offsets[localPixelOffset]!;

      resizeNotifier.value = ResizeHeaderDetails(
        index: index,
        axis: axis,
      );

      return true;
    }

    return false;
  }

  void _handleOnPointerDown(PointerDownEvent event) {
    if (!isResizingEnabled) {
      return;
    }

    final axis = resizeNotifier.value!.axis;

    _initialOffset = _getOffsetPositionForAxis(event.localPosition, axis);

    resizeNotifier.value = resizeNotifier.value!.copyWith(
      offset: _initialOffset,
    );

    resizeLineOverlayManager.insertEntries(context);
  }

  void _handleOnPointerMove(PointerMoveEvent event) {
    if (!didResizingStart) {
      return;
    }

    final value = resizeNotifier.value!;
    final axis = value.axis;

    final newOffset =
        value.offset! + _getOffsetPositionForAxis(event.delta, axis);

    final minWidth =
        axis == Axis.horizontal ? kDefaultCellWidth : kDefaultCellHeight;

    final width = internalScope.controller.tableDataController
        .getHeaderControllerFor(axis: axis)
        .value
        .getHeaderExtentFor(index: value.index);

    double minGlobalPixelOffset;

    if (width > minWidth) {
      minGlobalPixelOffset = _initialOffset! - (width - minWidth);
    } else {
      minGlobalPixelOffset = _initialOffset!;
    }

    if (newOffset < minGlobalPixelOffset) {
      return;
    }

    resizeNotifier.value = value.copyWith(offset: newOffset);
  }

  void _handleOnPointerUp(PointerUpEvent event) {
    if (!didResizingStart) {
      return;
    }

    final value = resizeNotifier.value!;
    final axis = value.axis;

    final headerController = internalScope.controller.tableDataController
        .getHeaderControllerFor(axis: axis);

    final index = value.index;
    final initialOffset = _initialOffset!;
    final offset = value.offset!;
    final extent = headerController.value.getHeaderExtentFor(index: index);

    double newWidth;

    if (offset < initialOffset) {
      newWidth = max(minSize, extent - (initialOffset - offset));
    } else {
      newWidth = extent + (offset - initialOffset);
    }

    headerController.updateState(
      (previousState) => headerController.value.setHeaderExtent(
        index,
        newWidth,
      ),
    );

    widget.onHeaderExtentChanged?.call(index, axis, extent, newWidth);

    resizeNotifier.value = null;

    resizeLineOverlayManager.removeEntries();
  }

  /// The minimum size that an header can have.
  double get minSize => resizeNotifier.value?.axis == Axis.horizontal
      ? kDefaultCellWidth
      : kDefaultCellHeight;

  bool get isResizingEnabled => resizeNotifier.value?.index != null;

  bool get didResizingStart => resizeNotifier.value?.offset != null;

  @override
  Widget build(BuildContext context) {
    return ResizeHeaderDetailsNotifier(
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
