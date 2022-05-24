import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../../widgets.dart';
import '../../../internal_scope.dart';
import 'resize_header_overlay_line.dart';

typedef ResizeHeaderMouseRegionBuilder = Widget Function(
  BuildContext context,
  bool isResizeHeaderLineOpened,
);

class _ResizeHeaderDetails {
  /// Holds the header width.
  final double width;

  /// The global position pixel offset of the header right edge if the Axis is
  /// horizontal.
  ///
  /// If the Axis is vertical, this variable will hold the global position pixel
  /// offset of the header bottom edge.
  final double edgeGlobalPixelOffset;

  /// The index of the header that is being resized.
  final int index;

  final Axis axis;

  /// The minimum global position that the resize line can be at.
  ///
  /// If the mouse cursor is at a global position that is inferior to
  /// [minGlobalPosition], the resize line will still be shown at
  /// [minGlobalPosition] and not at the mouse cursor.
  late double minGlobalPosition;

  double getNewWidthForGlobalPosition(double globalPosition) {
    if (globalPosition > edgeGlobalPixelOffset) {
      return width + (globalPosition - edgeGlobalPixelOffset);
    }

    return max(width - (edgeGlobalPixelOffset - globalPosition), maxSize);
  }

  double get maxSize =>
      axis == Axis.horizontal ? kDefaultCellWidth : kDefaultCellHeight;

  _ResizeHeaderDetails({
    required this.width,
    required this.edgeGlobalPixelOffset,
    required this.index,
    required this.axis,
  }) {
    if (width > maxSize) {
      minGlobalPosition = edgeGlobalPixelOffset - (width - maxSize);
    } else {
      minGlobalPosition = edgeGlobalPixelOffset;
    }
  }
}

@immutable
class ResizeWidgetDetails {
  final double left;
  final double top;
  final double width;
  final double height;

  const ResizeWidgetDetails({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  ResizeWidgetDetails copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return ResizeWidgetDetails(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResizeWidgetDetails &&
        other.left == left &&
        other.top == top &&
        other.height == height;
  }

  @override
  int get hashCode => left.hashCode ^ top.hashCode ^ height.hashCode;
}

class _ResizeLineOverlayManager {
  OverlayEntry? _line;
  OverlayEntry? _backdrop;

  void initialize({
    required OverlayState overlayState,
    required Widget child,
  }) {
    _backdrop ??= OverlayEntry(
      builder: (context) => const ColoredBox(color: Color(0x00000000)),
    );

    _line ??= OverlayEntry(builder: (context) => child);

    overlayState.insertAll([_backdrop!, _line!]);
  }

  void removeEntries() {
    _backdrop?.remove();
    _line?.remove();

    _backdrop = null;
    _line = null;
  }
}

class ResizeHeaderMouseRegion extends StatefulWidget {
  final InternalScope internalScope;
  final ViewportAxisContext viewportAxisContext;
  final ViewportAxisContext flippedAxisViewportContext;
  final Axis axis;
  final OnHeaderExtentChanged? onHeaderExtentChanged;
  final ResizeHeaderMouseRegionBuilder builder;

  const ResizeHeaderMouseRegion({
    Key? key,
    required this.internalScope,
    required this.viewportAxisContext,
    required this.flippedAxisViewportContext,
    required this.axis,
    required this.builder,
    this.onHeaderExtentChanged,
  }) : super(key: key);

  @override
  State<ResizeHeaderMouseRegion> createState() =>
      _ResizeHeaderMouseRegionState();
}

class _ResizeHeaderMouseRegionState extends State<ResizeHeaderMouseRegion> {
  late final headerController = widget
      .internalScope.controller.tableDataController
      .getHeaderControllerFor(axis: widget.axis);

  late final flippedHeaderController = widget
      .internalScope.controller.tableDataController
      .getHeaderControllerFor(
    axis: widget.axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
  );

  final _resizeWidgetDetails = ValueNotifier<ResizeWidgetDetails?>(null);

  final resizeLineOverlayManager = _ResizeLineOverlayManager();

  bool _isHoveringHeaderEdge = false;
  bool _isResizeHeaderLineOpened = false;

  _ResizeHeaderDetails? _resizeHeaderDetails;

  MouseCursor _getMouseCursor() {
    if (!_isHoveringHeaderEdge) {
      return MouseCursor.defer;
    }

    return widget.axis == Axis.horizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;
  }

  void _updateIsHoveringHeaderEdge(bool isHoveringHeaderEdge) {
    if (_isHoveringHeaderEdge == isHoveringHeaderEdge) {
      return;
    }

    setState(() {
      _isHoveringHeaderEdge = isHoveringHeaderEdge;
    });
  }

  void _updateIsResizeHeaderLineOpened(bool isResizeHeaderLineOpened) {
    if (_isResizeHeaderLineOpened == isResizeHeaderLineOpened) {
      return;
    }

    setState(() {
      _isResizeHeaderLineOpened = isResizeHeaderLineOpened;
    });
  }

  double _getOffsetPositionForAxis(Offset offset) {
    return widget.axis == Axis.horizontal ? offset.dx : offset.dy;
  }

  double _getInvertedOffsetPositionForAxis(Offset offset) {
    return widget.axis == Axis.horizontal ? offset.dy : offset.dx;
  }

  void _handleOnHover(PointerHoverEvent event) {
    final offsets = widget.viewportAxisContext.value.headersEdgesOffsets;

    final localPixelOffset = _getLocalPixelOffset(event.localPosition);

    if (offsets.containsKey(localPixelOffset)) {
      return _updateIsHoveringHeaderEdge(true);
    }

    _updateIsHoveringHeaderEdge(false);
  }

  double _getLocalPixelOffset(Offset localPosition) {
    var localPixelOffset = _getOffsetPositionForAxis(localPosition);

    final virtualizationState = widget.viewportAxisContext.virtualizationState;

    if (localPixelOffset + virtualizationState.displacement <=
        widget.viewportAxisContext.value.frozenExtent + 2) {
      localPixelOffset += virtualizationState.displacement;
    }

    return localPixelOffset.ceilToDouble();
  }

  void _handleStartResizing(PointerDownEvent event) {
    if (!_isHoveringHeaderEdge) {
      return;
    }

    final offsets = widget.viewportAxisContext.value.headersEdgesOffsets;

    final localPixelOffset = _getLocalPixelOffset(event.localPosition);

    if (!offsets.containsKey(localPixelOffset)) {
      return;
    }

    final index = offsets[localPixelOffset]!;
    final globalPixelOffset = _getOffsetPositionForAxis(event.position);
    final width = headerController.value.getHeaderExtentFor(index: index);

    _resizeHeaderDetails = _ResizeHeaderDetails(
      width: width,
      index: index,
      edgeGlobalPixelOffset: globalPixelOffset,
      axis: widget.axis,
    );

    final renderBox = context.findRenderObject()! as RenderBox;
    final globalPosition = renderBox.localToGlobal(Offset.zero);

    final size = flippedHeaderController.value.extent +
        widget.flippedAxisViewportContext.virtualizationState.displacement;

    if (widget.axis == Axis.horizontal) {
      _resizeWidgetDetails.value = ResizeWidgetDetails(
        left: _getOffsetPositionForAxis(event.position),
        top: _getInvertedOffsetPositionForAxis(globalPosition),
        width: 1,
        height: size,
      );
    } else {
      _resizeWidgetDetails.value = ResizeWidgetDetails(
        left: _getInvertedOffsetPositionForAxis(globalPosition),
        top: _getOffsetPositionForAxis(event.position),
        width: size,
        height: 1,
      );
    }

    final overlay = Overlay.of(context);

    if (overlay == null) {
      return;
    }

    resizeLineOverlayManager.initialize(
      overlayState: overlay,
      child: ResizeHeaderOverlayLine(
        swayzeStyle: widget.internalScope.style,
        axis: widget.axis,
        resizeWidgetDetails: _resizeWidgetDetails,
      ),
    );

    _updateIsResizeHeaderLineOpened(true);
  }

  void _handleUpdateResize(PointerMoveEvent event) {
    if (!_isResizeHeaderLineOpened) {
      return;
    }

    final globalPixelOffset = _getOffsetPositionForAxis(event.position);

    if (globalPixelOffset < _resizeHeaderDetails!.minGlobalPosition) {
      return;
    }

    if (widget.axis == Axis.horizontal) {
      _resizeWidgetDetails.value = _resizeWidgetDetails.value!.copyWith(
        left: _getOffsetPositionForAxis(event.position),
      );
    } else {
      _resizeWidgetDetails.value = _resizeWidgetDetails.value!.copyWith(
        top: _getOffsetPositionForAxis(event.position),
      );
    }
  }

  void _handleStopResizing(PointerUpEvent event) {
    if (!_isResizeHeaderLineOpened) {
      return;
    }

    final resizeHeaderDetails = _resizeHeaderDetails!;

    final position = _getOffsetPositionForAxis(event.position);
    final index = resizeHeaderDetails.index;
    final oldWidth = resizeHeaderDetails.width;
    final newWidth = resizeHeaderDetails.getNewWidthForGlobalPosition(position);

    headerController.updateState((previousState) {
      return headerController.value.setHeaderExtent(index, newWidth);
    });

    widget.onHeaderExtentChanged?.call(index, widget.axis, oldWidth, newWidth);

    resizeLineOverlayManager.removeEntries();

    _updateIsResizeHeaderLineOpened(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleStartResizing,
      onPointerMove: _handleUpdateResize,
      onPointerUp: _handleStopResizing,
      child: MouseRegion(
        cursor: _getMouseCursor(),
        onHover: _handleOnHover,
        child: widget.builder(context, _isResizeHeaderLineOpened),
      ),
    );
  }
}
