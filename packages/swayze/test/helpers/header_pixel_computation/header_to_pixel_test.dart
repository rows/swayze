import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:swayze/src/helpers/header_pixel_computation/header_computation_auxiliary_data.dart';
import 'package:swayze/src/helpers/header_pixel_computation/header_to_pixel.dart';

import 'create_header_computation_auxiliary_data.dart';

@isTest
void testWithAuxiliaryData(
  Object description,
  dynamic Function(HeaderComputationAuxiliaryData auxiliaryData) body, {
  required Map<int, double> customSizedHeaders,
  required int totalHeadersCount,
  double defaultHeaderExtent = 10,
  Axis? axis,
}) {
  final auxiliaryData = createHeaderComputationAuxiliaryData(
    axis: axis ?? Axis.horizontal,
    count: totalHeadersCount,
    defaultHeaderExtent: defaultHeaderExtent,
    customSizedHeaders: customSizedHeaders,
  );

  test(description, () => body(auxiliaryData));
}

void main() {
  group('getAxisHeaderOffset', () {
    testWithAuxiliaryData(
      'for index zero',
      (auxiliaryData) {
        final result = getAxisHeaderOffset(0, auxiliaryData);

        expect(result, equals(0.0));
      },
      totalHeadersCount: 100,
      customSizedHeaders: {1: 150},
    );

    testWithAuxiliaryData(
      'when there is no custom sized headers',
      (auxiliaryData) {
        final result = getAxisHeaderOffset(10, auxiliaryData);

        expect(result, equals(100.0));
      },
      totalHeadersCount: 100,
      customSizedHeaders: {},
    );

    testWithAuxiliaryData(
      'where there is custom sized headers in between',
      (auxiliaryData) {
        final result = getAxisHeaderOffset(10, auxiliaryData);

        expect(result, equals(370.0));
      },
      totalHeadersCount: 100,
      customSizedHeaders: {
        1: 100,
        2: 100,
        3: 100,
        11: 100,
      },
    );

    testWithAuxiliaryData(
      'where there is custom sized headers after',
      (auxiliaryData) {
        final result = getAxisHeaderOffset(10, auxiliaryData);

        expect(result, equals(190.0));
      },
      totalHeadersCount: 100,
      customSizedHeaders: {
        1: 100,
        12: 100,
        13: 100,
        14: 100,
      },
    );

    testWithAuxiliaryData(
      'when index is custom sized',
      (auxiliaryData) {
        final result = getAxisHeaderOffset(10, auxiliaryData);

        expect(result, equals(190.0));
      },
      totalHeadersCount: 100,
      customSizedHeaders: {
        1: 100,
        10: 100,
        11: 100,
        12: 100,
      },
    );
  });
}
