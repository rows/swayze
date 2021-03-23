import 'package:flutter/foundation.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../core/controller/table/header_state.dart';
import 'header_computation_auxiliary_data.dart';

/// Calculates which columns/rows should be rendered
/// from a given scroll offset (point).
///
/// This is the workhorse of the virtualization mechanism.
///
/// To be invoked after every scroll frame, this takes as parameters the
/// viewport bounded by [leadingPixel] and [trailingPixel].
/// Also, [auxiliaryData] provides some extra information.
VirtualizationCalcResult pixelRangeToHeaderRange(
  double leadingPixel,
  double trailingPixel,
  HeaderComputationAuxiliaryData auxiliaryData,
) {
  assert(leadingPixel <= trailingPixel);

  // Displace the leading pixel with the frozen extent
  final resolvedLeadingPixel = leadingPixel + auxiliaryData.frozenExtent;

  // Ranges can only be calculated in a delta positive space.
  if (trailingPixel <= resolvedLeadingPixel) {
    return VirtualizationCalcResult.zero;
  }

  // Find the index and displacement of the leading edge.
  final leadingResult = _pixelToHeaderIndex(
    pointToAnalyze: resolvedLeadingPixel,
    orderedKeys: auxiliaryData.orderedCustomSizedIndices,
    customSizesMap: auxiliaryData.customSizedHeaders,
    defaultSize: auxiliaryData.defaultSize,
  );
  // Find the index and displacement of the trailing edge.
  final trailingResult = _pixelToHeaderIndex(
    pointToAnalyze: trailingPixel,
    orderedKeys: auxiliaryData.orderedCustomSizedIndices,
    customSizesMap: auxiliaryData.customSizedHeaders,
    defaultSize: auxiliaryData.defaultSize,

    // Accumulators
    // we save this into these variables to start to look for the trailing point
    // from where we stopped when looking for the starting point
    customSizesPointerStart: leadingResult.customSizesPointer,
    indexAccumulatorStart: leadingResult.indexPointer,
    extentAccumulatorStart: leadingResult.extentAccumulator,
  );

  // Clamp the leading index into acceptable boundaries.
  final leadingIndex = leadingResult.headerIndexInPoint.clamp(
    0,
    auxiliaryData.lastHeaderIndex,
  );

  // Clamp the trailing index into acceptable boundaries.
  final trailingIndex = trailingResult.headerIndexInPoint.clamp(
    0,
    auxiliaryData.lastHeaderIndex,
  );

  // The effective displacement of the range in relation to the top-left corner
  // of the table
  final effectiveDisplacement = -leadingResult.displacement;

  return VirtualizationCalcResult(
    effectiveDisplacement,
    Range(
      leadingIndex,
      trailingIndex + 1, // range is not inclusive, trailingIndex edge is.
    ),
  );
}

/// A transport class that contains the result of the computation on the
/// virtualization function.
@immutable
class VirtualizationCalcResult {
  /// A displacement of this range in pixels in relation to the top/left corner of the table.
  ///
  /// See also:
  /// * [VirtualizationState.displacement]
  final double displacement;

  /// The range that describes the visible columns/rows indices in a virtualization state.
  final Range range;

  /// A neutral result.
  static const VirtualizationCalcResult zero = VirtualizationCalcResult(
    0.0,
    Range.zero,
  );

  const VirtualizationCalcResult(this.displacement, this.range);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirtualizationCalcResult &&
          runtimeType == other.runtimeType &&
          displacement == other.displacement &&
          range == other.range;

  @override
  int get hashCode => displacement.hashCode ^ range.hashCode;

  @override
  String toString() {
    return 'VirtualizationCalcResult('
        'range: $range, '
        'displacement: $displacement'
        ')';
  }
}

/// A function that computes an index of a column/row given an point in pixels
/// in an axis
///
/// This is the core of the virtualization mechanism.
///
/// This seeks for the exact column/row given a [pointToAnalyze].
///
/// First it iterates over the columns/rows with a custom size, filling all the
/// remaining space with [defaultSize] sized columns/rows.
///
/// See also:
/// * [pixelRangeToHeaderRange] that calls this function for the leading and
/// trailing edge of the screen.
_IndexFindersAccumulators _pixelToHeaderIndex({
  /// The point in which the returned index covers
  required final double pointToAnalyze,

  /// A ordered collection of custom sized columns/rows keys on [customSizesMap].
  required final Iterable<int> orderedKeys,

  /// A collection of columns/rows custom sizes mapped by its indices.
  required final Map<int, SwayzeHeaderData> customSizesMap,

  /// The default size for columns/rows in pixels
  required final double defaultSize,

  // Pointers: in case of starting the calculation from a previously set point in the row/header collection.

  /// A starting pointer for the column/row index to iterate.
  final int customSizesPointerStart = 0,

  /// A starting accumulator.
  final int indexAccumulatorStart = 0,

  /// The extent in pixels to start the search.
  final double extentAccumulatorStart = 0,
}) {
  assert(pointToAnalyze >= extentAccumulatorStart);

  // The index of the custom sized column/row in the [orderedKeys] list in analysis.
  var customSizesPointer = customSizesPointerStart;
  // The index of the next column/row to be analyzed
  var indexPointer = indexAccumulatorStart;
  // How many pixels we already covered in our search
  var extentAccumulator = extentAccumulatorStart;

  // Look up into the custom sized columns/rows to find the actual index.
  while (customSizesPointer < orderedKeys.length) {
    // Get the index of the custom sized column/row
    final customSizeKey = orderedKeys.elementAt(customSizesPointer);

    // Get how many cells exists between the actual and the last custom sized
    // column/row. These are all default sized ones.
    final regularHeadersIntervalCount = customSizeKey - indexPointer;

    // Get what all of these regular sized columns/rows means in pixels
    final regularHeadersIntervalExtent =
        regularHeadersIntervalCount * defaultSize;

    // Leading edge of the current custom sized column/row in the extent,
    // in pixels
    final leadingEdgeExtent = extentAccumulator + regularHeadersIntervalExtent;

    // If the leading edge of this custom sized columnRow is after the point of
    // interest, we should stop looking into the custom sized headers without
    // updating the pointers.
    if (leadingEdgeExtent >= pointToAnalyze) {
      break;
    }

    // Update the index pointer to include up to the column/row before the
    // current custom sized.
    indexPointer += regularHeadersIntervalCount;
    // Update the extent accumulator to include up to the column/row before the
    // current custom sized.
    extentAccumulator = leadingEdgeExtent;

    // Trailing edge of the current custom sized column/row in the extent, in pixels..
    final trailingEdgeExtent = leadingEdgeExtent +
        (customSizesMap[customSizeKey]?.effectiveExtent ?? 0.0);

    // The trailing edge of this custom sized column/row is after the
    // pointToAnalyze, means that this custom sized header is the header we are
    // looking for.
    if (trailingEdgeExtent > pointToAnalyze) {
      return _IndexFindersAccumulators(
        headerIndexInPoint: customSizeKey,
        displacement: pointToAnalyze - leadingEdgeExtent,
        customSizesPointer: customSizesPointer,
        indexPointer: indexPointer,
        extentAccumulator: extentAccumulator,
      );
    }

    // Otherwise, update accumulators for the next iteration
    extentAccumulator = trailingEdgeExtent;
    indexPointer += 1;
    customSizesPointer += 1;
  }

  // Now that we have included all the custom sized columns/rows, we can include the
  // subsequent regular sized headers.

  // Find how many pixels are after the last included custom sized column/row
  final intervalExtent = pointToAnalyze - extentAccumulator;
  // Find how many regular columns/rows are after the last included custom sized
  // column/row
  final headerCount = (intervalExtent / defaultSize).floor();

  // Get the index of the regular sized column/row in which the index is.
  final headerIndex = headerCount + indexPointer;
  final displacement = intervalExtent % defaultSize;

  return _IndexFindersAccumulators(
    headerIndexInPoint: headerIndex,
    displacement: displacement,
    customSizesPointer: customSizesPointer,
    indexPointer: indexPointer,
    extentAccumulator: extentAccumulator,
  );
}

/// A representation of how the accumulator values from [_pixelToHeaderIndex]
/// were in its end of execution.
class _IndexFindersAccumulators {
  final int headerIndexInPoint;
  final double displacement;

  // pointers

  final int indexPointer;
  final double extentAccumulator;
  final int customSizesPointer;

  _IndexFindersAccumulators({
    required this.headerIndexInPoint,
    required this.displacement,

    // pointers

    required this.indexPointer,
    required this.extentAccumulator,
    required this.customSizesPointer,
  });
}
