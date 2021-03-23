import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../helpers/header_pixel_computation/header_computation_auxiliary_data.dart';
import '../../../helpers/header_pixel_computation/header_to_pixel.dart';
import '../../../widgets/internal_scope.dart';
import '../../../widgets/table.dart';
import '../../scrolling/sliver_two_axis_scroll.dart';
import '../../viewport_context/viewport_context.dart';
import '../../viewport_context/viewport_context_provider.dart';
import '../controller.dart';
import 'auto_scroll_activity.dart';

/// A [SubController] that manages scroll of a single table.
///
/// It attaches itself to a vertical [ScrollController] (the same passed to
/// [SliverSwayzeTable]) and a horizontal one (managed internally by
/// [SliverTwoAxisScroll]). For that, it uses an internal widget
/// [ScrollControllerAttacher] that is instantiated under scroll views for
/// both axis.
///
/// To verify if this controller was attached to the widget tree, use
/// [isAttached].
///
/// See also:
/// - [SwayzeSelectionController] another [SubController] that manages
/// selections on a table.
/// - [ScrollControllerAttacher] that attaches this controller into the internal
/// widget tree.
class SwayzeScrollController<ParentType extends SwayzeController>
    extends SubController<ParentType> {
  /// When this controller [isAttached] internally, this points to the internal
  /// [ScrollController] that manages the horizontal scroll view.
  ScrollController? horizontalScrollController;

  /// When this controller [isAttached] internally,this points to the internal
  /// [ScrollController] that manages the horizontal scroll view.
  ScrollController? verticalScrollController;
  BuildContext? _internalContext;

  AutoScrollController? verticalAutoScrollController;
  AutoScrollController? horizontalAutoScrollController;

  SwayzeScrollController(ParentType parent) : super(parent);

  /// Called by [ScrollControllerAttacher] when the controller is attached to a
  /// widget tree. It sets up [horizontalScrollController],
  /// [verticalScrollController] and a internal [BuildContext].
  void _attach({
    required ScrollController horizontalScrollController,
    required ScrollController verticalScrollController,
    required BuildContext internalContext,
  }) {
    this.horizontalScrollController = horizontalScrollController;
    this.verticalScrollController = verticalScrollController;
    _internalContext = internalContext;
  }

  /// As opposite to [_attach], it defines a [SwayzeScrollController] to not be
  /// attached to any scroll controller nor widget tree.
  void _detach() {
    horizontalScrollController = null;
    verticalScrollController = null;
    verticalAutoScrollController = null;
    horizontalAutoScrollController = null;
    _internalContext = null;
  }

  /// Define if this controller was attached to the internal widget tree.
  bool get isAttached =>
      horizontalScrollController != null &&
      verticalScrollController != null &&
      _internalContext != null;

  /// Shorthand access to the internal [ViewportContext]
  ViewportContext? get _viewportContext => _internalContext != null
      ? ViewportContextProvider.of(_internalContext!)
      : null;

  /// Define how many pixels are occupied by other widgets before this one on
  /// the an axis.
  /// For the horizontal axis, it i always zero. For the vertical, it is
  /// correspondent to the heights of tables and other widgets in the same
  /// vertical scroll view.
  double _precedingPixels(Axis axis) => axis == Axis.horizontal
      ? 0.0
      : _viewportContext!.rows.virtualizationState.scrollingData.constraints
          .precedingScrollExtent;

  /// Get a [ScrollController] for the specified [axis].
  ScrollController? getScrollControllerFor({required Axis axis}) {
    return axis == Axis.horizontal
        ? horizontalScrollController
        : verticalScrollController;
  }

  /// Get a [AutoScrollController] for the specified [axis].
  AutoScrollController? getAutoScrollControllerFor({required Axis axis}) {
    return axis == Axis.horizontal
        ? horizontalAutoScrollController
        : verticalAutoScrollController;
  }

  /// Returns true if any of the [AutoScrollController] is instantiated.
  bool get isAutoScrollOn =>
      horizontalAutoScrollController != null ||
      verticalAutoScrollController != null;

  /// Scroll to the table in the vertical axis.
  ///
  /// See also:
  /// - [ScrollPosition.ensureVisible] to understand the parameters.
  Future<void> ensureTableVisibility({
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
  }) async {
    // If this controller is not attached, do nothing.
    if (!isAttached) {
      return;
    }

    // Find the render objects that represents this table.
    final tableRenderObject = _internalContext!
        .findRootAncestorStateOfType<SliverSwayzeTableState>()!
        .context
        .findRenderObject()!;

    // Scroll to the render object.
    return verticalScrollController!.position.ensureVisible(
      tableRenderObject,
      alignment: alignment,
      duration: duration,
      curve: curve,
      alignmentPolicy: alignmentPolicy,
    );
  }

  /// From an [index] of a column/row, discover its global offset in the
  /// scroll view from an [axis].
  ///
  /// It should return null when there should not be a scroll.
  double? _getOffsetToHeader(
    int index,
    Axis axis,
    ScrollController scrollController,
  ) {
    final headersState =
        parent.tableDataController.getHeaderControllerFor(axis: axis).value;
    final frozenExtent = headersState.frozenExtent;

    // If this controller is not attached, do nothing.
    if (!isAttached) {
      return null;
    }

    final headerState =
        parent.tableDataController.getHeaderControllerFor(axis: axis).value;

    // If the given index is out of the table bounds, return null.
    if (index < 0 || index >= headerState.totalCount) {
      return null;
    }

    // Access the relevant states
    final viewportContext = ViewportContextProvider.of(_internalContext!);
    final virtualizationState =
        viewportContext.getAxisContextFor(axis: axis).virtualizationState;

    final isForFrozenPanes = viewportContext
        .getAxisContextFor(axis: axis)
        .value
        .frozenRange
        .contains(index);

    // Define the position of the header in relation to the current viewport.
    final offscreenDetails = viewportContext
        .positionToPixel(
          index,
          axis,
          isForFrozenPanes: isForFrozenPanes,
        )
        .offscreenDetails;

    // Recover the current visible range
    final visibleRange = virtualizationState.rangeNotifier.value;

    // Define the alignment of the header for scroll, if it is offscreen to the
    // leading edge of the viewport, scroll until the leading edge header aligns
    // into it.
    // The same goes logic applies for when the header is offscreen for the
    // trailing edge of the viewport.
    late final bool scrollToTheViewportLeadingEdge;
    if (!offscreenDetails.isOffscreen && !visibleRange.isNil) {
      // When the header is on the viewport

      if (index != visibleRange.start && index != visibleRange.end - 1) {
        // if it is not in the edges of the viewport, return null.

        return null;
      }

      if (index == visibleRange.start &&
          virtualizationState.displacement == 0.0) {
        // if the header is in the leading edge with no displacement,
        // do not scroll.

        return null;
      }

      // Align to leading edge of the viewport if it is in the leading edge of
      // the range when there is displacement. Otherwise align with the trailing
      // edge of the viewport.
      scrollToTheViewportLeadingEdge = index == visibleRange.start;
    } else {
      // When the header is offscreen, align with the according edge.
      scrollToTheViewportLeadingEdge =
          offscreenDetails == OffscreenDetails.leading;
    }

    final preceedingPixels = _precedingPixels(axis);

    // The extra pixels to apply to a scroll offset to comply with the policy
    // defined by scrollToTheViewportLeadingEdge.
    late final double viewportCompensation;
    // The real index of the header in with the leading edge shall be
    // discovered.
    late final int indexToDiscoverOffset;
    if (scrollToTheViewportLeadingEdge) {
      // When the scroll align to the leading edge of the viewport, apply
      // compensation to frozen headers.
      viewportCompensation = frozenExtent;
      indexToDiscoverOffset = index;
    } else {
      // When scrolling to the bottom of the viewport, verify if the bottom
      // edge of the physical space occupied by the table is further or
      // alongside the bottom of the viewport.
      final viewportBottomEdge = scrollController.position.pixels +
          virtualizationState.scrollingData.constraints.viewportMainAxisExtent;

      final tableBottomEdge = preceedingPixels +
          headerState.extent +
          virtualizationState.scrollingData.leadingPadding;

      if (tableBottomEdge < viewportBottomEdge) {
        return null;
      }

      // When the scroll align to the trailing edge of the viewport, create a
      // compensation for the real viewport size
      viewportCompensation =
          virtualizationState.scrollingData.constraints.viewportMainAxisExtent -
              virtualizationState.scrollingData.leadingPadding;
      // the scroll should reveal the trailing edge of the header, which is the
      // leading edge of the next header.
      indexToDiscoverOffset = index + 1;
    }

    // Discover the pixel offset of the leading edge of a header on index
    // [indexToDiscoverOffset]
    final targetOffset = getAxisHeaderOffset(
      indexToDiscoverOffset,
      HeaderComputationAuxiliaryData.fromHeaderState(
        axis: axis,
        headerState: headerState,
      ),
    );

    // Finally, sum up to achieve the real offset of a header.
    final absolutePosition =
        preceedingPixels + targetOffset - viewportCompensation;

    return absolutePosition;
  }

  /// Jumps the scroll position of an [axis] from its current value to the
  /// corresponding value of a header in the index [index].
  ///
  /// See also:
  /// - [animateToHeader] scroll to a header position with an animation.
  /// - [jumpToCoordinate] make a coordinate visible
  /// - [ScrollController.jumpTo] the corresponding built int to flutter
  /// scroll mechanism.
  void jumpToHeader(int index, Axis axis) {
    if (!isAttached) {
      return;
    }

    final scrollController = getScrollControllerFor(axis: axis)!;

    // Get the pixel offset of this header necessary to make it visible.
    final jumpOffset = _getOffsetToHeader(index, axis, scrollController);

    // If there is no jump offset, don't scroll
    if (jumpOffset == null) {
      return;
    }

    // Finally, apply offset
    scrollController.jumpTo(jumpOffset);
  }

  /// Animates the scroll position of an [axis from its current value to the
  /// corresponding value of a header in the index [index].
  ///
  /// See also:
  /// - [jumpToHeader] instantly scroll to a header with no animation
  /// - [animateToCoordinate] animate to a particular coordinate
  /// - [ScrollController.animateTo] the corresponding built int to flutter
  /// scroll mechanism.
  Future<void> animateToHeader(
    int index,
    Axis axis, {
    Duration duration = kDefaultScrollAnimationDuration,
    Curve curve = kDefaultScrollAnimationCurve,
  }) async {
    if (!isAttached) {
      return;
    }

    final scrollController = getScrollControllerFor(axis: axis)!;

    // Get the pixel offset of this header necessary to make it visible.
    final animationOffset = _getOffsetToHeader(index, axis, scrollController);

    // If there is no animation offset, don't scroll
    if (animationOffset == null) {
      return;
    }

    // Finally, apply offset
    return scrollController.animateTo(
      animationOffset,
      duration: duration,
      curve: curve,
    );
  }

  /// Manages scroll in both axis to instantly scroll to a specific
  /// [coordinate].
  ///
  /// See also:
  /// - [jumpToHeader] called by this method for both axis.
  /// - [animateToCoordinate]
  void jumpToCoordinate(IntVector2 coordinate) {
    jumpToHeader(coordinate.dx, Axis.horizontal);
    jumpToHeader(coordinate.dy, Axis.vertical);
  }

  /// Animate the scroll  in both axis to make a specific [coordinate]
  /// visible.
  ///
  /// See also:
  /// - [animateToHeader] called by this method for both axis.
  /// - [jumpToCoordinate]
  Future<void> animateToCoordinate(
    IntVector2 coordinate, {
    Duration duration = kDefaultScrollAnimationDuration,
    Curve curve = kDefaultScrollAnimationCurve,
  }) =>
      Future.wait([
        animateToHeader(
          coordinate.dx,
          Axis.horizontal,
          duration: duration,
          curve: curve,
        ),
        animateToHeader(
          coordinate.dy,
          Axis.vertical,
          duration: duration,
          curve: curve,
        ),
      ]);

  /// Start or update a [AutoScrollActivity] in the given [AxisDirection]
  /// until [maxToScroll] pixels have been scrolled with a velocity calculated
  /// from the [pointerDistance].
  ///
  /// If [maxToScroll] is not specified it scrolls until it reaches the end of
  /// the scrollable area.
  void startOrUpdateAutoScroll({
    required AxisDirection direction,
    required double pointerDistance,
    double? maxToScroll,
  }) {
    final axis = axisDirectionToAxis(direction);
    final controller = getScrollControllerFor(axis: axis)!;
    final autoScrollController = getAutoScrollControllerFor(axis: axis);
    final position = controller.position as ScrollPositionWithSingleContext;

    if (autoScrollController != null) {
      autoScrollController.pointerDistance = pointerDistance;
      return;
    }

    GrowthDirection growthDirection;
    if (direction == AxisDirection.right || direction == AxisDirection.down) {
      growthDirection = GrowthDirection.forward;
    } else {
      growthDirection = GrowthDirection.reverse;
    }

    final newAutoScrollController = AutoScrollController(
      pointerDistance: pointerDistance,
    );
    if (axis == Axis.vertical) {
      verticalAutoScrollController = newAutoScrollController;
    } else {
      horizontalAutoScrollController = newAutoScrollController;
    }

    position.beginActivity(
      AutoScrollActivity(
        delegate: position,
        position: position,
        direction: growthDirection,
        controller: newAutoScrollController,
        maxToScroll: maxToScroll,
      ),
    );
  }

  /// Starts a [IdleScrollActivity] to stop a ongoing autoscroll activity.
  void stopAutoScroll(Axis axis) {
    if (getAutoScrollControllerFor(axis: axis) == null) {
      return;
    }

    if (axis == Axis.vertical) {
      verticalAutoScrollController = null;
    } else {
      horizontalAutoScrollController = null;
    }

    final scrollController = getScrollControllerFor(axis: axis)!;
    (scrollController.position as ScrollPositionWithSingleContext).goIdle();
  }

  @override
  void dispose() {
    // When the controller is disposed, only detach it from the widget tree.
    _detach();
  }
}

/// An internal [StatefulWidget] that attaches [SwayzeScrollController] into
/// the widget tree. Allowing access of internal states such as
/// [ViewportContext].
///
/// It should not be accessible externally from the package.
///
/// Mounted on [SliverTwoAxisScroll].
class ScrollControllerAttacher extends StatefulWidget {
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;

  final Widget child;

  const ScrollControllerAttacher({
    Key? key,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    required this.child,
  }) : super(key: key);

  @override
  _ScrollControllerAttacherState createState() =>
      _ScrollControllerAttacherState();
}

class _ScrollControllerAttacherState extends State<ScrollControllerAttacher> {
  late final SwayzeScrollController swayzeScrollController =
      InternalScope.of(context).controller.scroll;

  @override
  void initState() {
    super.initState();
    // Attach the controller to this widget tree
    swayzeScrollController._attach(
      horizontalScrollController: widget.horizontalScrollController,
      verticalScrollController: widget.verticalScrollController,
      internalContext: context,
    );
  }

  @override
  void dispose() {
    // When this widget si removed from the tree, detach the controller as well
    swayzeScrollController._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
