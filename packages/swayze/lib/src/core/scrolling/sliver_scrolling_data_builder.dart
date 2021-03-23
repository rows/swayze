import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../virtualization/virtualization_calculator.dart';

/// A callback for children of [SliverScrollingDataBuilder].
typedef ContentWithScrollingDataBuilder = Widget Function(
  BuildContext context,
  ScrollingData constraints,
);

/// A sliver that exposes the sliver constraints to its children via a
/// [buildContent] callback.
///
/// This sliver also keeps the result of [contentBuilder] fixed in the viewport,
/// it means they are translated as the scroll offset changes.
class SliverScrollingDataBuilder extends StatelessWidget {
  /// Defines how many pixels this sliver should be allowed to scroll.
  final double extent;

  /// Build children widgets passing [SliverConstraints]
  final ContentWithScrollingDataBuilder contentBuilder;

  /// The amount of pixels taken by a padding in the leading edge of the sliver.
  final double leadingPadding;

  const SliverScrollingDataBuilder({
    Key? key,
    required this.leadingPadding,
    required this.extent,
    required this.contentBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final scrollingData = ScrollingData.fromSliverConstraints(
          leadingPadding: leadingPadding,
          constraints: constraints,
          totalExtent: extent,
        );
        return _SliverFixed(
          sliver: SliverToBoxAdapter(
            child: contentBuilder(context, scrollingData),
          ),
          extent: extent,
        );
      },
    );
  }
}

/// A Sliver render object widget that renders a child sliver in a fixed
/// position though out a distance equivalent to [extent].
class _SliverFixed extends SingleChildRenderObjectWidget {
  final double extent;

  const _SliverFixed({
    required Widget sliver,
    required this.extent,
  }) : super(child: sliver);

  @override
  RenderSliverFixedBoxAdapter createRenderObject(BuildContext context) {
    return RenderSliverFixedBoxAdapter(extent);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverFixedBoxAdapter renderObject,
  ) {
    renderObject..extent = extent;
  }
}

/// A render sliver object for [_SliverFixed].
/// It renders a sliver [child] on a fixed position since
/// [childMainAxisPosition] is zero.
///
/// It also produces a scroll extent equivalent to [extent].
class RenderSliverFixedBoxAdapter extends RenderProxySliver {
  RenderSliverFixedBoxAdapter(
    this._extent, [
    RenderSliver? child,
  ]) : super(child);

  double _extent;

  double get extent => _extent;

  set extent(double extent) {
    _extent = extent;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    /// Translate child as the parent scroll offset changes.
    ///
    /// This meant that for child, scroll offset should always be zero.
    final childConstraints = constraints.copyWith(scrollOffset: 0);

    // Make children render objects go trough layout.
    child!.layout(childConstraints);

    // If there is no child render object after the widget content is built, do
    // nothing.
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    // Get the size in which the children are occupying in the screen in a
    // scroll frame
    final paintedChildSize = calculatePaintOffset(
      constraints,
      from: 0.0,
      to: extent,
    );

    // Get the size in which the cache extent (given the size set by the
    // viewport) is occupying in the screen in a scroll frame
    final cacheExtent = calculateCacheOffset(
      constraints,
      from: 0.0,
      to: extent,
    );

    // Build the geometry used for paint and the parent Viewport processing of
    // sliver composition.
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: extent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: extent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
  }

  @override
  double childMainAxisPosition(RenderSliver child) {
    // The content should be fixed in the edge of the screen
    return 0.0;
  }
}

/// A transport class for information generated from
/// [SliverScrollingDataBuilder] and used on
/// [VirtualizationCalculator].
///
/// This is generated from a [SliverConstraints] and
/// [SliverScrollingDataBuilder.extent].
@immutable
class ScrollingData {
  /// The sliver constraints that was provided by the sliver layout to
  /// generate this scrolling data.
  ///
  /// See also:
  /// - [SliverScrollingDataBuilder] that generates a [ScrollingData] from
  ///   sliver constraints and [SliverScrollingDataBuilder.extent].
  final SliverConstraints constraints;

  /// The value that represents the total extent in pixels of the
  /// table in an axis.
  final double totalExtent;

  /// The amount of pixels taken by a padding in the leading edge of the sliver.
  final double leadingPadding;

  /// The height of the table minus the amount that was already scrolled
  /// limited to the size of the viewport.
  late final double viewportExtent =
      (totalExtent - constraints.scrollOffset).clamp(
    0.0,
    constraints.viewportMainAxisExtent,
  );

  /// The distance between the leading edge (top for vertical and left for
  /// horizontal) of the table (or of the screen, whichever is closer) and the
  /// trailing edge (bottom for vertical and right for horizontal) of the screen
  /// (or of the table, whichever is closer) in a scroll frame.
  late final double remainingContentExtent = min(
    viewportExtent - leadingPadding,
    constraints.remainingPaintExtent - leadingPadding,
  ).clamp(
    0.0,
    viewportExtent,
  );

  /// Create a [ScrollingData] from a [SliverConstraints]
  @visibleForTesting
  ScrollingData.fromSliverConstraints({
    required this.leadingPadding,
    required this.constraints,
    required this.totalExtent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollingData &&
          runtimeType == other.runtimeType &&
          constraints == other.constraints &&
          totalExtent == other.totalExtent &&
          viewportExtent == other.viewportExtent;

  @override
  int get hashCode =>
      constraints.hashCode ^ totalExtent.hashCode ^ viewportExtent.hashCode;

  @override
  String toString() {
    return '''
    ScrollingData(
      constraints: $constraints,
      totalExtent: $totalExtent,
      viewportExtent: $viewportExtent,
    )
    ''';
  }
}
