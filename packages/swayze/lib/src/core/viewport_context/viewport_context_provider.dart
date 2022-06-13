import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../widgets/headers/gestures/resize_header/header_edge_info.dart';
import '../../widgets/internal_scope.dart';
import '../controller/controller.dart';
import '../virtualization/virtualization_calculator.dart'
    show VirtualizationCalculator, VirtualizationState;
import 'viewport_context.dart';

const _kMinEdgeOffsetAdder = -2;
const kMaxEdgeOffsetAdder = 2;

/// A [StatefulWidget] that detects changes on the two axis
/// [VirtualizationState.rangeNotifier] to create a [ViewportContext] and
/// add it to the tree context via [_ViewportContextProviderScope].
///
/// Descendant widgets can access the state via [VirtualizationState.of].
///
/// The state of this widget is an implementation of [ViewportContext].
///
/// See also:
/// - [ViewportContext] the interface where the descendant widgets access
///   this widgets state.
/// - [VirtualizationState] used by this widget to compute its values on
///   range changes.
@internal
class ViewportContextProvider extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  final VirtualizationState horizontalVirtualizationState;

  final VirtualizationState verticalVirtualizationState;

  const ViewportContextProvider({
    Key? key,
    required this.child,
    required this.horizontalVirtualizationState,
    required this.verticalVirtualizationState,
  }) : super(key: key);

  @override
  _ViewportContextProviderState createState() =>
      _ViewportContextProviderState();

  /// From descendants of [_ViewportContextProviderScope], recover the nearest
  /// [ViewportContext].
  static ViewportContext of(BuildContext context) {
    return context
        .findAncestorWidgetOfExactType<_ViewportContextProviderScope>()!
        .state;
  }
}

class _ViewportContextProviderState extends State<ViewportContextProvider>
    implements ViewportContext {
  late final tableController =
      InternalScope.of(context).controller.tableDataController;

  /// A value notifier to subscribe to changes in the visible columns.
  /// It is generated by the ancestor [VirtualizationCalculator].
  late final ValueNotifier<Range> horizontalRangeNotifier =
      widget.horizontalVirtualizationState.rangeNotifier;

  /// A value notifier to subscribe to changes in the visible rows.
  /// It is generated by the ancestor [VirtualizationCalculator].
  late final ValueNotifier<Range> verticalRangeNotifier =
      widget.verticalVirtualizationState.rangeNotifier;

  @override
  late final _ChangeableViewportHeaderAxisState columns =
      _ChangeableViewportHeaderAxisState(
    Axis.horizontal,
    widget.horizontalVirtualizationState,
  );

  @override
  late final _ChangeableViewportHeaderAxisState rows =
      _ChangeableViewportHeaderAxisState(
    Axis.vertical,
    widget.verticalVirtualizationState,
  );

  /// Listen for changes in both [columns] and [rows].
  late final _bothAxisListenable = Listenable.merge([columns, rows]);

  @override
  _ChangeableViewportHeaderAxisState getAxisContextFor({
    required Axis axis,
  }) {
    return axis == Axis.horizontal ? columns : rows;
  }

  @override
  void addListener(VoidCallback listener) {
    _bothAxisListenable.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _bothAxisListenable.removeListener(listener);
  }

  @override
  void initState() {
    super.initState();

    // listen for changes on the visible ranges
    horizontalRangeNotifier.addListener(updateColumns);
    verticalRangeNotifier.addListener(updateRows);
    tableController.columns.addListener(updateColumns);
    tableController.rows.addListener(updateRows);

    // compute initial values
    updateColumns();
    updateRows();
  }

  @override
  void dispose() {
    // remove listeners on dispose
    horizontalRangeNotifier.removeListener(updateColumns);
    verticalRangeNotifier.removeListener(updateRows);
    tableController.columns.removeListener(updateColumns);
    tableController.rows.removeListener(updateRows);
    super.dispose();
  }

  void updateColumns() {
    updateAxis(Axis.horizontal);
  }

  void updateRows() {
    updateAxis(Axis.vertical);
  }

  void updateAxis(Axis axis) {
    final viewportAxisContext = getAxisContextFor(axis: axis);
    final rangeNotifier = Axis.horizontal == axis
        ? horizontalRangeNotifier
        : verticalRangeNotifier;

    final headerController = tableController.getHeaderControllerFor(axis: axis);
    final scrollableRange = rangeNotifier.value;

    final headersEdgesOffsets = <double, HeaderEdgeInfo>{};

    // Frozen
    final frozenSizes = <double>[];
    final frozenOffsets = <double>[];
    final visibleFrozenHeaders = <int>[];
    var frozenExtentAcc = 0.0;

    final frozenCount = headerController.value.frozenCount;

    for (var index = 0; index < frozenCount; index++) {
      frozenOffsets.add(frozenExtentAcc);
      final size = headerController.value.getHeaderExtentFor(index: index);
      frozenSizes.add(size);
      frozenExtentAcc += size;

      _addHeaderEdge(
        headersEdgesOffsets,
        offset: frozenExtentAcc,
        index: index,
        size: size,
      );

      if (size > 0) {
        visibleFrozenHeaders.add(index);
      }
    }

    // Scrollable
    final sizes = <double>[];
    final offsets = <double>[];
    final visibleHeaders = <int>[];
    var extentAcc = frozenExtentAcc;

    for (final index in scrollableRange.iterable) {
      offsets.add(extentAcc);
      final size = headerController.value.getHeaderExtentFor(index: index);
      sizes.add(size);
      extentAcc += size;

      _addHeaderEdge(
        headersEdgesOffsets,
        offset: extentAcc,
        index: index,
        size: size,
      );

      if (size > 0) {
        visibleHeaders.add(index);
      }
    }

    final dragState = headerController.value.dragState;
    ViewportHeaderDragContextState? dragContextState;
    if (dragState != null) {
      var draggingHeaderExtent = 0.0;
      for (final index in dragState.headers.iterable) {
        draggingHeaderExtent +=
            headerController.value.getHeaderExtentFor(index: index);
      }

      dragContextState = ViewportHeaderDragContextState(
        headers: dragState.headers,
        dropAtIndex: dragState.dropAtIndex,
        position: dragState.position,
        headersExtent: draggingHeaderExtent,
      );
    }

    viewportAxisContext._unprotectedSetState(
      ViewportAxisContextState(
        scrollableRange: scrollableRange,
        frozenRange: Range(0, frozenCount),
        extent: extentAcc,
        frozenExtent: frozenExtentAcc,
        offsets: offsets,
        frozenOffsets: frozenOffsets,
        sizes: sizes,
        frozenSizes: frozenSizes,
        visibleIndices: visibleHeaders,
        visibleFrozenIndices: visibleFrozenHeaders,
        headerDragState: dragContextState,
        headersEdgesOffsets: headersEdgesOffsets,
      ),
    );
  }

  /// Maps the headers edges to the corresponding index.
  ///
  /// Since we also want to show the resize cursor when the user hovers a bit
  /// to the left or right of the edge, we save a range of positions and map
  /// them to the right header index.
  void _addHeaderEdge(
    Map<double, HeaderEdgeInfo> headersEdgesOffsets, {
    required double offset,
    required int index,
    required double size,
  }) {
    for (var i = _kMinEdgeOffsetAdder; i <= kMaxEdgeOffsetAdder; i++) {
      headersEdgesOffsets[offset.floorToDouble() + i] = HeaderEdgeInfo(
        index: index,
        width: size,
        displacement: -i,
        offset: offset,
      );
    }
  }

  @override
  PositionResult pixelToPosition(double pixelOffset, Axis axis) {
    const leadingEdge = 0.0;

    final axisContext = getAxisContextFor(axis: axis);
    final axisContextState = axisContext.value;
    final trailingEdge =
        axisContextState.extent + axisContextState.frozenExtent;
    final virtualizationState = axisContext.virtualizationState;

    // Check if there is any overflow
    late final OffscreenDetails overflow;
    if (pixelOffset < leadingEdge) {
      overflow = OffscreenDetails.leading;
    } else if (pixelOffset > trailingEdge) {
      overflow = OffscreenDetails.trailing;
    } else {
      overflow = OffscreenDetails.noOverflow;
    }

    // Check if it is in a frozen position
    if (pixelOffset - virtualizationState.displacement.abs() <=
        axisContextState.frozenExtent) {
      final position = _pixelOffsetToIndex(
        pixelOffset - virtualizationState.displacement.abs(),
        axisContextState.frozenOffsets,
      );

      return PositionResult(
        position: position,
        overflow: overflow,
        axis: axis,
        isFrozen: true,
      );
    }

    final range = axisContextState.scrollableRange;
    final headerCollection = axisContextState.offsets;

    // Position is clamped to the viewport bounds, so if there is overflow,
    // it will be indicated with either the value equal to the trailing or the
    // leading edge of the visible range.
    final position = range.start +
        _pixelOffsetToIndex(
          pixelOffset,
          headerCollection,
        );

    return PositionResult(
      position: position,
      overflow: overflow,
      axis: axis,
      isFrozen: false,
    );
  }

  /// Given a [globalPosition] and a [Axis] compute its pixel position based
  /// on the [ViewportAxisContextState] sizes.
  @override
  PixelResult positionToPixel(
    int globalPosition,
    Axis axis, {
    required bool isForFrozenPanes,
  }) {
    final stateValue = getAxisContextFor(axis: axis).value;

    final range =
        isForFrozenPanes ? stateValue.frozenRange : stateValue.scrollableRange;
    final headerCollection =
        isForFrozenPanes ? stateValue.frozenOffsets : stateValue.offsets;
    final leadingEdge = isForFrozenPanes ? 0.0 : stateValue.frozenExtent;
    final trailingEdge =
        isForFrozenPanes ? stateValue.frozenExtent : stateValue.extent;

    if (range.isNil) {
      final virtualizationState =
          getAxisContextFor(axis: axis).virtualizationState;
      final hasScrolledPastIt =
          virtualizationState.scrollingData.constraints.scrollOffset > 0;
      return PixelResult(
        axis: axis,
        offscreenDetails: hasScrolledPastIt
            ? OffscreenDetails.leading
            : OffscreenDetails.trailing,
        pixel: 0.0,
      );
    }

    final isOnScreen = range.contains(globalPosition);

    if (isOnScreen) {
      final localPosition =
          (globalPosition - range.start).clamp(0, range.iterable.length - 1);
      final offset = headerCollection.elementAt(localPosition);

      return PixelResult(
        axis: axis,
        offscreenDetails: OffscreenDetails.noOverflow,
        pixel: offset,
      );
    }

    if (globalPosition < range.start) {
      return PixelResult(
        axis: axis,
        offscreenDetails: OffscreenDetails.leading,
        pixel: leadingEdge,
      );
    }

    return PixelResult(
      axis: axis,
      offscreenDetails: OffscreenDetails.trailing,
      pixel: trailingEdge,
    );
  }

  @override
  CellPositionResult getCellPosition(IntVector2 globalPosition) {
    final isFrozenX = globalPosition.dx < columns.value.frozenOffsets.length;
    final isFrozenY = globalPosition.dy < rows.value.frozenOffsets.length;

    final columnRange = columns.value.scrollableRange;
    final rowRange = rows.value.scrollableRange;

    final isOffscreenX = !columnRange.contains(globalPosition.dx) && !isFrozenX;
    final isOffscreenY = !rowRange.contains(globalPosition.dy) && !isFrozenY;

    if (isOffscreenX || isOffscreenY) {
      return CellPositionResult.offscreen(
        isOffscreenX: isOffscreenX,
        isOffscreenY: isOffscreenY,
      );
    }
    late final double left;
    late final double width;
    if (isFrozenX) {
      final localX = globalPosition.dx;
      left = columns.value.frozenOffsets.elementAt(localX);
      width = columns.value.frozenSizes[localX];
    } else {
      final maxX = columnRange.iterable.length - 1;
      final localX = (globalPosition.dx - columnRange.start).clamp(0, maxX);
      left = columns.value.offsets.elementAt(localX);
      width = columns.value.sizes[localX];
    }

    late final double top;
    late final double height;
    if (isFrozenY) {
      final localY = globalPosition.dy;
      top = rows.value.frozenOffsets.elementAt(localY);
      height = rows.value.frozenSizes[localY];
    } else {
      final maxY = rowRange.iterable.length - 1;
      final localY = (globalPosition.dy - rowRange.start).clamp(0, maxY);
      top = rows.value.offsets.elementAt(localY);
      height = rows.value.sizes[localY];
    }

    return CellPositionResult(
      leftTop: Offset(left, top),
      cellSize: Size(width, height),
    );
  }

  @override
  EvaluateHoverResult evaluateHover(Offset pixelOffset) {
    final internalScope = InternalScope.of(context);

    final selectionState =
        internalScope.controller.selection.userSelectionState;

    final primary = selectionState.primarySelection is CellUserSelectionModel
        ? selectionState.primarySelection as CellUserSelectionModel
        : null;

    final style = internalScope.config.isDragFillEnabled
        ? internalScope.style.dragAndFillStyle.handle
        : null;

    final positionX = pixelToPosition(pixelOffset.dx, Axis.horizontal);
    final positionY = pixelToPosition(pixelOffset.dy, Axis.vertical);

    Range2D? fillRange;

    // If the primary selection allows fill, check if we're over the handle.
    if (primary?.type != CellUserSelectionType.fill && style != null) {
      final cellPosition = getCellPosition(primary!.focus);
      final cellRect = cellPosition.leftTop & cellPosition.cellSize;

      final canFillCell = Rect.fromLTRB(
        cellRect.right - style.size.width,
        cellRect.bottom - style.size.height,
        cellRect.right + style.size.width,
        cellRect.bottom + style.size.height,
      ).inflate(style.borderWidth).contains(pixelOffset);

      if (canFillCell) {
        fillRange = primary;
      }
    }

    return EvaluateHoverResult(
      cell: IntVector2(positionX.position, positionY.position),
      overflowX: positionX.overflow,
      overflowY: positionY.overflow,
      fillRange: fillRange,
    );
  }

  @override
  Widget build(BuildContext context) => _ViewportContextProviderScope(
        // this state is provided as ViewportContext
        state: this,
        child: widget.child,
      );
}

/// A [InheritedWidget] that makes a [ViewportContext] (it is really a
/// [_ViewportContextProviderState] but do not tell anybody 🤫) accessible to
/// its descendants.
///
/// It does not trigger dependency updates.
///
/// To access [state] on descendants, use [ViewportContext.of].
///
/// See also:
/// - [_ViewportContextProviderState.build] where this widget is added to the
///   tree.
class _ViewportContextProviderScope extends InheritedWidget {
  /// The [ViewportContext] to be accessed by descendants.
  final ViewportContext state;

  const _ViewportContextProviderScope({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_ViewportContextProviderScope oldWidget) {
    return false;
  }
}

/// Returns the index of a column/row in a pixel offset.
///
/// Used by [_ViewportContextProviderState.pixelToPosition]
int _pixelOffsetToIndex(double pixelOffset, List<double> headerCollection) {
  var local = -1;
  for (final headerOffset in headerCollection) {
    if (pixelOffset < headerOffset) {
      break;
    }
    local++;
  }
  return local.clamp(0, headerCollection.length);
}

/// A unprotected version of [ViewportAxisContext] in which is possible
/// to update the state with no fear by calling [_unprotectedSetState].
class _ChangeableViewportHeaderAxisState extends ViewportAxisContext {
  _ChangeableViewportHeaderAxisState(
    Axis axis,
    VirtualizationState virtualizationState,
  ) : super(axis, virtualizationState);

  void _unprotectedSetState(ViewportAxisContextState newValue) {
    super.setState(newValue);
  }
}
