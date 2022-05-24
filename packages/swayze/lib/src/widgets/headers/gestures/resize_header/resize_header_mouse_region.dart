import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../../widgets.dart';
import '../../../../core/virtualization/virtualization_calculator.dart'
    show VirtualizationState;
import '../../../internal_scope.dart';
import 'resize_header_overlay_line.dart';

/// A callback that gives back the context and a bool that tells if the resize
/// header line is visible or not.
typedef ResizeHeaderMouseRegionBuilder = Widget Function(
  BuildContext context,
  bool isResizeHeaderLineVisible,
);

/// Used when resizing an header. Contains useful information about the header
/// like the original width, the global pixel offset of the header edge and the
/// minimum global position that the resize line can go to.
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

  /// The axis of the header.
  final Axis axis;

  /// The minimum global position that the resize line can be at.
  ///
  /// If the mouse cursor is at a global position that is inferior to
  /// [minGlobalPosition], the resize line will still be shown at
  /// [minGlobalPosition] and not at the mouse cursor.
  late double minGlobalPosition;

  /// Computes the new width of the header.
  double getNewWidthForGlobalPosition(double globalPosition) {
    if (globalPosition > edgeGlobalPixelOffset) {
      return width + (globalPosition - edgeGlobalPixelOffset);
    }

    return max(width - (edgeGlobalPixelOffset - globalPosition), defaultSize);
  }

  /// The default size of the header.
  double get defaultSize =>
      axis == Axis.horizontal ? kDefaultCellWidth : kDefaultCellHeight;

  _ResizeHeaderDetails({
    required this.width,
    required this.edgeGlobalPixelOffset,
    required this.index,
    required this.axis,
  }) {
    if (width > defaultSize) {
      minGlobalPosition = edgeGlobalPixelOffset - (width - defaultSize);
    } else {
      minGlobalPosition = edgeGlobalPixelOffset;
    }
  }
}

/// Holds information about where to position the resize line as well as its
/// width and height.
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

/// A manager for the resize line overlay entries.
///
/// Creates a backdrop overlay entry to disable scrolling when resizing the
/// header and an overlay entry that takes a widget.
class _ResizeLineOverlayManager {
  OverlayEntry? _backdrop;
  OverlayEntry? _line;

  /// Creates the overlay entries for [_backdrop] and [_line] and inserts them
  /// at [overlayState].
  void createEntries({
    required OverlayState overlayState,
    required Widget child,
  }) {
    _backdrop ??= OverlayEntry(
      builder: (context) => const MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: ColoredBox(color: Color(0x00000000)),
      ),
    );

    _line ??= OverlayEntry(builder: (context) => child);

    overlayState.insertAll([_backdrop!, _line!]);
  }

  /// Removes [_backdrop] and [_line] from the overlay that they belong to
  /// and sets their value to null.
  void removeEntries() {
    _backdrop?.remove();
    _line?.remove();

    _backdrop = null;
    _line = null;
  }
}

/// Returns a mouse region that shows the resize cursor when the user hovers
/// the edge of an header.
///
/// Also has a listener that spawns the resize line at the mouse position when
/// [Listener.onPointerDown] is invoked and the mouse is hovering the edge of
/// the header.
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
  bool _isResizeHeaderLineVisible = false;

  _ResizeHeaderDetails? _resizeHeaderDetails;

  /// Gets the mouse cursor according to [_isHoveringHeaderEdge] and
  /// [widget.axis] values.
  MouseCursor _getMouseCursor() {
    if (!_isHoveringHeaderEdge) {
      return MouseCursor.defer;
    }

    return widget.axis == Axis.horizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;
  }

  /// Updates the value of [_isHoveringHeaderEdge].
  void _updateIsHoveringHeaderEdge(bool isHoveringHeaderEdge) {
    if (_isHoveringHeaderEdge == isHoveringHeaderEdge) {
      return;
    }

    setState(() {
      _isHoveringHeaderEdge = isHoveringHeaderEdge;
    });
  }

  /// Updates the value of [_isResizeHeaderLineVisible].
  void _updateIsResizeHeaderLineVisible(bool isResizeHeaderLineVisible) {
    if (_isResizeHeaderLineVisible == isResizeHeaderLineVisible) {
      return;
    }

    setState(() {
      _isResizeHeaderLineVisible = isResizeHeaderLineVisible;
    });
  }

  /// Gets the pixel offset for the current [widget.axis].
  double _getOffsetPositionForAxis(Offset offset) {
    return widget.axis == Axis.horizontal ? offset.dx : offset.dy;
  }

  /// Gets the pixel offset for the inverted [widget.axis].
  double _getInvertedOffsetPositionForAxis(Offset offset) {
    return widget.axis == Axis.horizontal ? offset.dy : offset.dx;
  }

  /// Checks if the mouse coordinates are at an header edge and updates
  /// [_isHoveringHeaderEdge] value.
  void _handleOnHover(PointerHoverEvent event) {
    final offsets = widget.viewportAxisContext.value.headersEdgesOffsets;

    final localPixelOffset = _getLocalPixelOffset(event.localPosition);

    if (offsets.containsKey(localPixelOffset)) {
      return _updateIsHoveringHeaderEdge(true);
    }

    _updateIsHoveringHeaderEdge(false);
  }

  /// Gets the pixel offset for the given [localPosition].
  ///
  /// Takes into consideration the current [VirtualizationState.displacement] in
  /// frozen headers.
  double _getLocalPixelOffset(Offset localPosition) {
    var localPixelOffset = _getOffsetPositionForAxis(localPosition);

    final virtualizationState = widget.viewportAxisContext.virtualizationState;

    if (localPixelOffset + virtualizationState.displacement <=
        widget.viewportAxisContext.value.frozenExtent + 2) {
      localPixelOffset += virtualizationState.displacement;
    }

    return localPixelOffset.ceilToDouble();
  }

  /// Callback invoked when the user has tapped an header.
  ///
  /// Computes the position and size of the header resize line and adds it
  /// to the current [Overlay].
  void _handleStartResizing(PointerDownEvent event) {
    if (!_isHoveringHeaderEdge) {
      return;
    }

    final offsets = widget.viewportAxisContext.value.headersEdgesOffsets;

    final localPixelOffset = _getLocalPixelOffset(event.localPosition);

    // a safe check
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

    final renderObject = context.findRenderObject();

    if (renderObject == null) {
      return;
    }

    final renderBox = renderObject as RenderBox;
    final globalPosition = renderBox.localToGlobal(Offset.zero);

    final size = flippedHeaderController.value.extent +
        widget.flippedAxisViewportContext.virtualizationState.displacement;

    if (widget.axis == Axis.horizontal) {
      _resizeWidgetDetails.value = ResizeWidgetDetails(
        left: _getOffsetPositionForAxis(event.position),
        top: _getInvertedOffsetPositionForAxis(globalPosition),
        width: widget.internalScope.style.resizeHeaderStyle.lineThickness,
        height: size,
      );
    } else {
      _resizeWidgetDetails.value = ResizeWidgetDetails(
        left: _getInvertedOffsetPositionForAxis(globalPosition),
        top: _getOffsetPositionForAxis(event.position),
        width: size,
        height: widget.internalScope.style.resizeHeaderStyle.lineThickness,
      );
    }

    final overlay = Overlay.of(context);

    if (overlay == null) {
      return;
    }

    resizeLineOverlayManager.createEntries(
      overlayState: overlay,
      child: ResizeHeaderOverlayLine(
        swayzeStyle: widget.internalScope.style,
        axis: widget.axis,
        resizeWidgetDetails: _resizeWidgetDetails,
      ),
    );

    _updateIsResizeHeaderLineVisible(true);
  }

  /// Callback invoked when the user is dragging the header resize line.
  ///
  /// Computes and sets the new position of the header resize line.
  void _handleUpdateResize(PointerMoveEvent event) {
    if (!_isResizeHeaderLineVisible) {
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

  /// Callback invoked when the user has let go the mouse after resizing
  /// an header.
  ///
  /// Updates the header with the new width, calls `onHeaderExtentChanged` with
  /// the old width as well as the new one. Then, removes the resize line from
  /// the screen.
  void _handleStopResizing(PointerUpEvent event) {
    if (!_isResizeHeaderLineVisible) {
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

    _updateIsResizeHeaderLineVisible(false);
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
        child: widget.builder(context, _isResizeHeaderLineVisible),
      ),
    );
  }
}
