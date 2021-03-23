import 'package:flutter/widgets.dart';
import 'package:memoize/memoize.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../helpers/header_pixel_computation/header_computation_auxiliary_data.dart';
import '../../helpers/header_pixel_computation/pixel_to_header.dart';
import '../../widgets/internal_scope.dart';
import '../../widgets/table_body/cells/cells.dart';
import '../controller/table/header_state.dart';
import '../scrolling/sliver_scrolling_data_builder.dart';
import '../viewport_context/viewport_context.dart';

/// An interface for children of [VirtualizationCalculator] to recover
/// the state of the virtualization of a specific [axis].
///
/// It contains the actual visible columns/rows via [rangeNotifier.value] and the
/// [displacement].
///
/// See also:
/// - [VirtualizationCalculator] that calculates this state given scroll
///   constraints.
/// - [ViewportContext] that calculates the disposition of columns and
///   rows in the screen given the range provided by this state.
/// - [Cells] a widget that uses the virtualization state to control which
///    cells should be visible.
abstract class VirtualizationState {
  /// A value notifier for ranges in this [axis].
  /// This will trigger widgets to rebuild and relayout only when the visible
  /// range changes.
  ///
  /// The particular value of this field is not supposed to change across time.
  ValueNotifier<Range> get rangeNotifier;

  /// The space between the leading edge of the first column/row visible and the
  /// edge of the viewport in this [axis].
  ///
  /// For example: when the first visible column in a table is only partially
  /// visible (after scrolling), [displacement] is equivalent to the extend
  /// invisible part of this column.
  double get displacement;

  /// The axis in which this state belongs to.
  Axis get axis;

  /// The scrolling data that triggered the virtualization computation
  /// that generated this state.
  ///
  /// See also:
  /// - [VirtualizationCalculator] that computes a [VirtualizationState]
  /// from a [ScrollingData].
  ScrollingData get scrollingData;

  /// The size occupied by the headers in this [axis]
  double get headerSize;
}

typedef VirtualizationStateWidgetBuilder = Widget Function(
  BuildContext context,
  VirtualizationState virtualizationState,
);

/// A [StatefulWidget] that computes the ranges to be rendered given a
/// [ScrollingData] for each axis.
///
/// It is essentially what computes the virtualization using the UI constraints
/// (scroll offset and viewport extent).
class VirtualizationCalculator extends StatefulWidget {
  /// The state of the scroll received from the [SliverScrollingDataBuilder]
  final ScrollingData scrollingData;

  /// The underlying axis in which the virtualization has to be calculated..
  final Axis axis;

  /// The immediate child has access to the resulting [VirtualizationState].
  final VirtualizationStateWidgetBuilder contentBuilder;

  /// The size occupied by the headers in this [axis]
  final double headerSize;

  final int frozenAmount;

  const VirtualizationCalculator({
    Key? key,
    required this.scrollingData,
    required this.axis,
    required this.contentBuilder,
    required this.headerSize,
    required this.frozenAmount,
  }) : super(key: key);

  @override
  State createState() => _VirtualizationCalculatorState();
}

class _VirtualizationCalculatorState extends State<VirtualizationCalculator>
    implements VirtualizationState {
  late final controller = InternalScope.of(context).controller;

  late final headerController =
      controller.tableDataController.getHeaderControllerFor(axis: axis);

  /// See [VirtualizationState.rangeNotifier]
  @override
  late ValueNotifier<Range> rangeNotifier;

  /// See [VirtualizationState.displacement]
  @override
  late double displacement;

  /// See [VirtualizationState.axis]
  @override
  Axis get axis => widget.axis;

  /// See [VirtualizationState.scrollingData]
  @override
  ScrollingData get scrollingData => widget.scrollingData;

  /// See [VirtualizationState.headerSize]
  @override
  double get headerSize => widget.headerSize;

  @override
  void initState() {
    super.initState();

    final offset = widget.scrollingData.constraints.scrollOffset;
    final extent = widget.scrollingData.remainingContentExtent;

    // Compute the initial virtualization.
    final initialVirtualization = calcVirtualizationMemoized(
      offset,
      extent,
      headerController.value,
    );

    // The initial state values
    displacement = initialVirtualization.displacement;
    rangeNotifier = ValueNotifier(initialVirtualization.range);
  }

  @override
  void didUpdateWidget(covariant VirtualizationCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);

    assert(oldWidget.axis == axis);

    // Detect a scroll event.
    if (oldWidget.scrollingData != widget.scrollingData ||
        oldWidget.frozenAmount != widget.frozenAmount) {
      // When there is a scroll event.
      final scrollingData = widget.scrollingData;

      final offset = scrollingData.constraints.scrollOffset;
      final extent = scrollingData.remainingContentExtent;

      // Compute the range and displacement.
      final virtualizationResult = calcVirtualizationMemoized(
        offset,
        extent,
        headerController.value,
      );

      // update state
      rangeNotifier.value = virtualizationResult.range;

      setState(() {
        displacement = virtualizationResult.displacement;
      });
    }
  }

  @override
  void dispose() {
    rangeNotifier.dispose();
    super.dispose();
  }

  /// A memoized function to invoke the virtualization computation.
  late final VirtualizationCalcResult Function(
    double,
    double,
    SwayzeHeaderState,
  ) calcVirtualizationMemoized = memo3(
    (double offset, double extent, SwayzeHeaderState headerState) {
      return pixelRangeToHeaderRange(
        offset,
        offset + extent,
        HeaderComputationAuxiliaryData.fromHeaderState(
          axis: widget.axis,
          headerState: headerController.value,
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => widget.contentBuilder(context, this);
}
