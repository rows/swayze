import 'package:flutter/material.dart';
import 'package:swayze/src/helpers/header_pixel_computation/pixel_to_header.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

import 'create_header_computation_auxiliary_data.dart';

void main() {
  group('when leading and trailing are the same', () {
    test('should return VirtualizationCalcResult.zero', () {
      final res = pixelRangeToHeaderRange(
        10,
        10,
        createHeaderComputationAuxiliaryData(axis: Axis.vertical),
      );

      expect(res, equals(VirtualizationCalcResult.zero));
    });
  });

  group(
    'when no custom header sizes are provided',
    () {
      test(
        'should be able to calculate range/displacement with the default sizes on vertical axis',
        () {
          final res = pixelRangeToHeaderRange(
            120,
            630,
            createHeaderComputationAuxiliaryData(
              axis: Axis.vertical,
              count: 200,
            ),
          );

          // In this test case the rows height is not configured so they're
          // using the default size. To calculate displacement we need to see
          // how much of the first visible row does not fit entirely in the
          // visible viewport.
          // In our case the row with index 3, has 22px out of the viewport
          // and 4px within the viewport.
          //
          //   26px + 26px + 26px + 22px => 100px of the leading pixel
          expect(
            res,
            equals(
              const VirtualizationCalcResult(
                -21.0,
                Range(3, 20),
              ),
            ),
          );
        },
      );

      test(
        'should be able to calculate range/displacement with the default sizes on horizontal axis',
        () {
          final res = pixelRangeToHeaderRange(
            300,
            1000,
            createHeaderComputationAuxiliaryData(
              axis: Axis.horizontal,
              count: 100,
            ),
          );

          // In this test case we're going over the horizontal axis where the
          // default size is 100px
          expect(
            res,
            equals(
              const VirtualizationCalcResult(
                -60.0,
                Range(2, 9),
              ),
            ),
          );
        },
      );
    },
  );

  group('when custom header sizes are provided', () {
    test('when the given computing for the vertical axis', () {
      final res = pixelRangeToHeaderRange(
        90,
        600,
        createHeaderComputationAuxiliaryData(
          axis: Axis.vertical,
          count: 100,
          customSizedHeaders: {
            1: 40,
            2: 27,
            4: 140,
          },
        ),
      );

      // following the sizes of our rows until the leading pixel
      // 26px + 40px + 24px => 90px
      // Which means the displacement is 24px
      expect(
        res,
        equals(const VirtualizationCalcResult(-17.0, Range(2, 15))),
      );
    });

    test('when the given computing for the horizontal axis', () {
      final res = pixelRangeToHeaderRange(
        180,
        600,
        createHeaderComputationAuxiliaryData(
          axis: Axis.horizontal,
          count: 100,
          customSizedHeaders: {
            1: 75,
            2: 50,
            4: 150,
          },
        ),
      );

      // following the sizes of our rows until the leading pixel
      // 100 + 50 => 150px
      expect(
        res,
        equals(const VirtualizationCalcResult(-60.0, Range(1, 6))),
      );
    });

    test('when all custom sizes are within the edges', () {
      final res = pixelRangeToHeaderRange(
        240,
        1200,
        createHeaderComputationAuxiliaryData(
          axis: Axis.horizontal,
          count: 100,
          customSizedHeaders: {
            4: 200,
            5: 300,
          },
        ),
      );

      expect(
        res,
        equals(const VirtualizationCalcResult(0.0, Range(2, 8))),
      );
    });

    test('when all custom sizes are before leading edge', () {
      final res = pixelRangeToHeaderRange(
        250,
        1200,
        createHeaderComputationAuxiliaryData(
          axis: Axis.horizontal,
          count: 100,
          customSizedHeaders: {
            0: 50,
            1: 75,
            2: 125,
          },
        ),
      );

      expect(
        res,
        equals(const VirtualizationCalcResult(0.0, Range(3, 11))),
      );
    });

    test('when all custom sizes are after trailing edge', () {
      final res = pixelRangeToHeaderRange(
        240,
        720,
        createHeaderComputationAuxiliaryData(
          axis: Axis.horizontal,
          count: 100,
          customSizedHeaders: {
            7: 50,
            8: 75,
            9: 125,
          },
        ),
      );

      expect(
        res,
        equals(const VirtualizationCalcResult(0.0, Range(2, 7))),
      );
    });

    test('when theres a custom sizes right on the leading edge', () {
      final res = pixelRangeToHeaderRange(
        180,
        1200,
        createHeaderComputationAuxiliaryData(
          axis: Axis.horizontal,
          count: 100,
          customSizedHeaders: {
            1: 250,
          },
        ),
      );

      expect(
        res,
        equals(const VirtualizationCalcResult(-60.0, Range(1, 9))),
      );
    });

    test('when theres a custom sizes right on the trailing edge', () {
      final res = pixelRangeToHeaderRange(
        120,
        1260,
        createHeaderComputationAuxiliaryData(
          axis: Axis.horizontal,
          count: 100,
          customSizedHeaders: {
            10: 250,
          },
        ),
      );

      expect(
        res,
        equals(const VirtualizationCalcResult(0.0, Range(1, 11))),
      );
    });
  });

  group('when there is frozen headers', () {
    test('when there is a few frozen headers', () {
      final res = pixelRangeToHeaderRange(
        120,
        1260,
        createHeaderComputationAuxiliaryData(
          axis: Axis.horizontal,
          count: 100,
          customSizedHeaders: {
            10: 250,
          },
          frozenExtent: 290,
        ),
      );

      expect(
        res,
        equals(const VirtualizationCalcResult(-50.0, Range(3, 11))),
      );
    });
    test('when there is frozen headers past the viewport', () {
      final res = pixelRangeToHeaderRange(
        90,
        120,
        createHeaderComputationAuxiliaryData(
          axis: Axis.vertical,
          count: 100,
          customSizedHeaders: {
            1: 140,
            2: 27,
            4: 140,
          },
          frozenExtent: 140,
        ),
      );

      expect(res, equals(VirtualizationCalcResult.zero));
    });
  });
}
