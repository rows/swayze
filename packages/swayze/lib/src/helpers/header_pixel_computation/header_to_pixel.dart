import 'header_computation_auxiliary_data.dart';

// TODO(renancaraujo): this is always discovering the offset from index zero,
//  we may consider not iterating over all headers preceeding the given index
//  but discover the offset from an known header position.
/// Get the global pixel offset of an specific column/row anywhere in a table
/// considering all custom sized headers.
///
/// It is the workhorse of the 'scroll to' methods on [SwayzeScrollController].
double getAxisHeaderOffset(
  int targetIndex,
  HeaderComputationAuxiliaryData headerComputationAuxiliaryData,
) {
  // First column is always zero.
  if (targetIndex == 0) {
    return 0.0;
  }

  // Amount of headers that should be encapsulated in the resulting offset.
  final headersInBetween = targetIndex;

  // Double accumulator of the widths of all headers preceeding the
  // given index.
  var customSizedHeadersInBetweenSize = 0.0;
  var customSizedHeadersInBetweenCount = 0;

  // Iterate over all preceeding custom sized headers
  for (final customSizedHeaderIndex
      in headerComputationAuxiliaryData.orderedCustomSizedIndices) {
    // When go past the given index, stop the iteration
    if (customSizedHeaderIndex >= targetIndex) {
      break;
    }

    // Accumulate header count and sizes
    customSizedHeadersInBetweenCount++;
    customSizedHeadersInBetweenSize += headerComputationAuxiliaryData
        .customSizedHeaders[customSizedHeaderIndex]!.effectiveExtent;
  }

  // The amount of default sized headers preceeding in the given index
  final defaultSizedHeaderInBetweenCount =
      headersInBetween - customSizedHeadersInBetweenCount;

  // Sum up custom and default sized headers sizes
  final offset = customSizedHeadersInBetweenSize +
      (defaultSizedHeaderInBetweenCount *
          headerComputationAuxiliaryData.defaultSize);

  return offset;
}
