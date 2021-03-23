import 'package:flutter/widgets.dart';

import '../../config.dart' as config;
import '../../core/scrolling/sliver_scrolling_data_builder.dart';
import '../../core/virtualization/virtualization_calculator.dart';
import '../../widgets/headers/gestures/header_gesture_detector.dart';
import '../../widgets/table_body/gestures/table_body_gesture_detector.dart';

const kAutoScrollTriggerThreshold = 26;

/// A base class for classes that describe the behavior of scroll given a
/// drag gesture.
///
/// Used by [TableBodyGestureDetector] and [HeaderGestureDetector].
///
/// See the subclasses:
/// - [AutoScrollDragScrollData]
/// - [DoNotScrollDragScrollData]
/// - [ResetScrollDragScrollData]
@immutable
abstract class DragScrollData {}

/// [DragScrollData] for automatic scroll from a drag gesture.
///
/// Used to transport information from [getHorizontalDragScrollData] or
/// [getVerticalDragScrollData] that identifies when a drag gesture on
/// [TableBodyGestureDetector] or [HeaderGestureDetector] may cause auto
/// scroll when the gesture reaches the edges of the screen.
///
/// Used to kick start a [AutoScrollActivity].
class AutoScrollDragScrollData implements DragScrollData {
  final AxisDirection direction;
  final double pointerDistance;
  final double? maxToScroll;

  const AutoScrollDragScrollData({
    required this.direction,
    required this.pointerDistance,
    this.maxToScroll,
  });
}

/// [DragScrollData] for when there is not supposed to have any scroll given a
/// drag gesture.
class DoNotScrollDragScrollData implements DragScrollData {}

/// [DragScrollData] for when a drag gesture may cause the scroll to reset to
/// the start of the table in the given axis.
class ResetScrollDragScrollData implements DragScrollData {}

/// Given the pointer local and global offsets return [DragScrollData] for
/// the vertical axis.
///
/// Parameters:
/// - [displacement] see [VirtualizationState.displacement].
/// - [globalOffset] The `y` offset from the events `globalPosition`.
/// - [localOffset] The `y` offset from the events `localPosition`.
/// - [gestureOriginOffset] The `y` offset from the coordinate where the drag
/// gesture started.
/// - [viewportExtent] The total extent of the viewport in the vertical axis.
/// - [screenHeight] the height of the screen
/// - [frozenExtent] How much of the viewport is dedicated to frozen headers.
/// - [positionPixel] the current scrolled amount in the scroll view
/// - [scrollingData] see [VirtualizationState.scrollingData]
DragScrollData getVerticalDragScrollData({
  required double displacement,
  required double globalOffset,
  required double localOffset,
  required double gestureOriginOffset,
  required double viewportExtent,
  required double screenHeight,
  required double frozenExtent,
  required double positionPixel,
  required ScrollingData scrollingData,
}) {
  // The point that represents the top edge of the scrollable part.
  final topThreshold = displacement.abs() + frozenExtent;
  if (gestureOriginOffset < topThreshold) {
    // If the gesture started in a frozen pane
    if (localOffset >= topThreshold) {
      // Going to the scrollable area should reset scroll
      return ResetScrollDragScrollData();
    }
    // Keeping the drag in the frozen area should not scroll
    return DoNotScrollDragScrollData();
  }

  final precedingScrollExtent = scrollingData.constraints.precedingScrollExtent;

  final pointerDistanceToTopThreshold = topThreshold - localOffset;
  if (pointerDistanceToTopThreshold > 0) {
    return AutoScrollDragScrollData(
      direction: AxisDirection.up,
      maxToScroll: positionPixel - precedingScrollExtent + displacement.abs(),
      pointerDistance: pointerDistanceToTopThreshold,
    );
  }

  final bottomThreshold = screenHeight - kAutoScrollTriggerThreshold;
  final pointerDistanceToBottomThreshold = globalOffset - bottomThreshold;
  if (pointerDistanceToBottomThreshold > 0) {
    // The bottom of the table is the amount scrolled on previous slivers
    // plus the total extent of the table (which includes headers and top
    // padding).
    final tableBottomPixel = precedingScrollExtent + scrollingData.totalExtent;

    // The current bottom of the table is the which is the amount of pixels
    // already scrolled plus the leadingPadding (header + top padding) and
    // the current viewport extent.
    final viewportTableBottom =
        positionPixel + viewportExtent + scrollingData.leadingPadding;
    return AutoScrollDragScrollData(
      direction: AxisDirection.down,
      maxToScroll:
          tableBottomPixel - viewportTableBottom + config.kColumnHeaderHeight,
      pointerDistance: pointerDistanceToBottomThreshold,
    );
  }

  return DoNotScrollDragScrollData();
}

/// Given the pointer local and global offsets return [DragScrollData] for
/// the horizontal axis.
///
///
/// Parameters:
/// - [displacement] see [VirtualizationState.displacement].
/// - [globalOffset] The `x` offset from the events `globalPosition`.
/// - [localOffset] The `x` offset from the events `localPosition`.
/// - [gestureOriginOffset] The `x` offset from the coordinate where the drag
/// gesture started.
/// - [viewportExtent] The total extent of the viewport in the horizontal axis.
/// - [screenWidth] the height of the screen
/// - [frozenExtent] How much of the viewport is dedicated to frozen headers.
DragScrollData getHorizontalDragScrollData({
  required double displacement,
  required double globalOffset,
  required double localOffset,
  required double gestureOriginOffset,
  required double viewportExtent,
  required double screenWidth,
  required double frozenExtent,
}) {
  // The point that represents the left edge of the scrollable part.
  final leftThreshold = displacement.abs() + frozenExtent;
  if (gestureOriginOffset < leftThreshold) {
    // If the gesture started in a frozen pane
    if (localOffset >= leftThreshold) {
      // Going to the scrollable area should reset scroll
      return ResetScrollDragScrollData();
    }
    // Keeping the drag in the frozen area should not scroll
    return DoNotScrollDragScrollData();
  }

  final pointerDistanceToLeftThreshold = leftThreshold - localOffset;

  if (pointerDistanceToLeftThreshold > 0) {
    return AutoScrollDragScrollData(
      direction: AxisDirection.left,
      pointerDistance: pointerDistanceToLeftThreshold,
    );
  }

  final rightThreshold =
      screenWidth - config.kRowHeaderWidth - kAutoScrollTriggerThreshold;
  final pointerDistanceToRightThreshold = globalOffset - rightThreshold;
  if (pointerDistanceToRightThreshold > 0) {
    return AutoScrollDragScrollData(
      direction: AxisDirection.right,
      pointerDistance: pointerDistanceToRightThreshold,
    );
  }

  return DoNotScrollDragScrollData();
}
