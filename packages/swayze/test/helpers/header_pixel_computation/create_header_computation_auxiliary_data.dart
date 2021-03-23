import 'package:flutter/widgets.dart';
import 'package:swayze/src/config.dart';
import 'package:swayze/src/core/controller/table/header_state.dart';
import 'package:swayze/src/helpers/header_pixel_computation/header_computation_auxiliary_data.dart';

HeaderComputationAuxiliaryData createHeaderComputationAuxiliaryData({
  required Axis axis,
  int count = 3,
  double? defaultHeaderExtent,
  Map<int, double> customSizedHeaders = const {},
  double frozenExtent = 0,
}) {
  final headers = <int, SwayzeHeaderData>{};

  customSizedHeaders.forEach((key, value) {
    headers.putIfAbsent(
      key,
      () => SwayzeHeaderData(index: key, extent: value, hidden: false),
    );
  });

  final configuredDefaultExtent =
      axis == Axis.horizontal ? kDefaultCellWidth : kDefaultCellHeight;

  return HeaderComputationAuxiliaryData(
    axis: axis,
    defaultSize: defaultHeaderExtent ?? configuredDefaultExtent,
    lastHeaderIndex: count,
    customSizedHeaders: headers,
    orderedCustomSizedIndices: headers.keys.toList()..sort(),
    frozenExtent: frozenExtent,
  );
}
