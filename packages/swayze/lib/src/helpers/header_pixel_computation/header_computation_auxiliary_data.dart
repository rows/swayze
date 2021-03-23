import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/controller/table/header_state.dart';
import 'header_to_pixel.dart';
import 'pixel_to_header.dart';

/// A transport class for auxiliary data for computation that depends on header
/// data.
///
/// Used by [pixelRangeToHeaderRange] and [getAxisHeaderOffset].
@immutable
class HeaderComputationAuxiliaryData {
  /// The underlying axis
  final Axis axis;

  /// The default size of a column/row in the given axis.
  final double defaultSize;

  /// The index of the last column/row in this axis.
  final int lastHeaderIndex;

  /// A ordered collection of custom sized columns/rows keys on
  /// [customSizedHeaders].
  final Iterable<int> orderedCustomSizedIndices;

  /// A collection of columns/rows custom sizes mapped by its indices.
  final Map<int, SwayzeHeaderData> customSizedHeaders;

  /// The sum of sizes of frozen headers in the given axis.
  final double frozenExtent;

  @visibleForTesting
  const HeaderComputationAuxiliaryData({
    required this.axis,
    required this.defaultSize,
    required this.lastHeaderIndex,
    required this.orderedCustomSizedIndices,
    required this.customSizedHeaders,
    required this.frozenExtent,
  });

  HeaderComputationAuxiliaryData.fromHeaderState({
    required this.axis,
    required SwayzeHeaderState headerState,
  })  : defaultSize = headerState.defaultHeaderExtent,
        lastHeaderIndex = headerState.totalCount,
        orderedCustomSizedIndices = headerState.orderedCustomSizedIndices,
        customSizedHeaders = headerState.customSizedHeaders,
        frozenExtent = headerState.frozenExtent;
}
