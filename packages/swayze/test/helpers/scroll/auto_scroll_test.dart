import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/src/core/scrolling/sliver_scrolling_data_builder.dart';
import 'package:swayze/src/helpers/scroll/auto_scroll.dart';

ScrollingData createScrollingData({
  required double precedingScrollExtent,
  required double totalExtent,
  required double leadingPadding,
}) {
  return ScrollingData.fromSliverConstraints(
    leadingPadding: leadingPadding,
    constraints: SliverConstraints(
      axisDirection: AxisDirection.down,
      cacheOrigin: -157.0,
      crossAxisDirection: AxisDirection.right,
      crossAxisExtent: 1500.0,
      growthDirection: GrowthDirection.forward,
      overlap: 0.0,
      precedingScrollExtent: precedingScrollExtent,
      remainingCacheExtent: 1700.0,
      remainingPaintExtent: 1400.0,
      scrollOffset: 157.0,
      userScrollDirection: ScrollDirection.idle,
      viewportMainAxisExtent: 1400.0,
    ),
    totalExtent: totalExtent,
  );
}

void main() {
  group('getVerticalAutoScrollData', () {
    group('when has slivers before', () {
      test('should scroll upwards if pointer is in top trigger zone', () {
        final scrollingData = createScrollingData(
          leadingPadding: 96.0,
          precedingScrollExtent: 1500.0, // extent of previous slivers
          totalExtent: 2000.0,
        );

        final result = getVerticalDragScrollData(
          displacement: -15.0,
          globalOffset: 157.0,
          localOffset: 10.0,
          gestureOriginOffset: 16.0,
          // position pixel is after the previous slivers + an offset in the
          // current table
          positionPixel: 1700.0,
          screenHeight: 1000.0,
          scrollingData: scrollingData,
          viewportExtent: 500.0,
          frozenExtent: 0.0,
        );

        result as AutoScrollDragScrollData;

        expect(result.pointerDistance, 5.0);
        expect(result.direction, AxisDirection.up);
        expect(result.maxToScroll, 215.0);
      });

      test('should scroll downwards if pointer is in bottom trigger zone', () {
        final scrollingData = createScrollingData(
          leadingPadding: 96.0,
          precedingScrollExtent: 1500.0,
          totalExtent: 2000.0,
        );

        final result = getVerticalDragScrollData(
          displacement: -15.0,
          globalOffset: 995.0,
          localOffset: 495.0,
          gestureOriginOffset: 16.0,
          positionPixel: 1700.0,
          screenHeight: 1000.0,
          scrollingData: scrollingData,
          viewportExtent: 500.0,
          frozenExtent: 0.0,
        );

        result as AutoScrollDragScrollData;

        // we're 5 pixels from the edge of the screen height, so we're 21px
        // from the threshold.
        expect(result.pointerDistance, 21.0);
        expect(result.direction, AxisDirection.down);
        expect(result.maxToScroll, 1228);
      });

      test('should not scroll if pointer is not in a trigger zone', () {
        final scrollingData = createScrollingData(
          leadingPadding: 96.0,
          precedingScrollExtent: 1500.0,
          totalExtent: 2000.0,
        );

        final result = getVerticalDragScrollData(
          displacement: -15.0,
          globalOffset: 500.0,
          localOffset: 200.0,
          gestureOriginOffset: 16.0,
          positionPixel: 1700.0,
          screenHeight: 1000.0,
          scrollingData: scrollingData,
          viewportExtent: 500.0,
          frozenExtent: 0.0,
        );

        expect(result, const TypeMatcher<DoNotScrollDragScrollData>());
      });
    });

    group('when there are no slivers before', () {
      test('should scroll upwards if pointer is in top trigger zone', () {
        final scrollingData = createScrollingData(
          leadingPadding: 96.0,
          precedingScrollExtent: 0.0,
          totalExtent: 2000.0,
        );

        final result = getVerticalDragScrollData(
          displacement: -15.0,
          globalOffset: 157.0,
          localOffset: 7.0,
          gestureOriginOffset: 16.0,
          positionPixel: 200.0,
          screenHeight: 1000.0,
          scrollingData: scrollingData,
          viewportExtent: 500.0,
          frozenExtent: 0.0,
        );

        result as AutoScrollDragScrollData;
        expect(result.pointerDistance, 8.0); // displacement - localoffset.x
        expect(result.direction, AxisDirection.up);
        expect(result.maxToScroll, 215); // positionpixel + displacement.abs
      });

      test('should scroll downwards if pointer is in bottom trigger zone', () {
        final scrollingData = createScrollingData(
          leadingPadding: 96.0,
          precedingScrollExtent: 0.0,
          totalExtent: 2000,
        );

        final result = getVerticalDragScrollData(
          displacement: -15.0,
          globalOffset: 995.0,
          localOffset: 495.0,
          gestureOriginOffset: 16.0,
          positionPixel: 200.0,
          screenHeight: 1000.0,
          scrollingData: scrollingData,
          viewportExtent: 500.0,
          frozenExtent: 0.0,
        );

        result as AutoScrollDragScrollData;

        // we're 5 pixels from the edge of the screen height, so we're 21px
        // from the threshold.
        expect(result.pointerDistance, 21.0);
        expect(result.direction, AxisDirection.down);
        expect(result.maxToScroll, 1228);
      });

      test('should not scroll if pointer is not in a trigger zone', () {
        final scrollingData = createScrollingData(
          leadingPadding: 96.0,
          precedingScrollExtent: 0.0,
          totalExtent: 2000,
        );

        final result = getVerticalDragScrollData(
          displacement: -15.0,
          globalOffset: 500.0,
          localOffset: 200.0,
          gestureOriginOffset: 16.0,
          positionPixel: 200.0,
          screenHeight: 1000.0,
          scrollingData: scrollingData,
          viewportExtent: 500.0,
          frozenExtent: 0.0,
        );

        expect(result, const TypeMatcher<DoNotScrollDragScrollData>());
      });
    });
  });

  group('getHorizontalAutoScrollData', () {
    test('should scroll left', () {
      final result = getHorizontalDragScrollData(
        displacement: -64.0,
        globalOffset: 14.0,
        screenWidth: 1200.0,
        localOffset: 14.0,
        gestureOriginOffset: 65.0,
        viewportExtent: 1000.0,
        frozenExtent: 0.0,
      );

      result as AutoScrollDragScrollData;

      expect(result.direction, AxisDirection.left);
      expect(result.pointerDistance, 50.0);
    });

    test('should scroll right', () {
      final result = getHorizontalDragScrollData(
        displacement: 0.0,
        globalOffset: 1185.0,
        screenWidth: 1200.0,
        localOffset: 985.0,
        gestureOriginOffset: 16.0,
        viewportExtent: 1000.0,
        frozenExtent: 0.0,
      );

      result as AutoScrollDragScrollData;

      expect(result.direction, AxisDirection.right);
      expect(result.pointerDistance, 35.0);
    });

    test('should not scroll', () {
      final result = getHorizontalDragScrollData(
        displacement: 0.0,
        globalOffset: 14,
        screenWidth: 1200.0,
        localOffset: 500.0,
        gestureOriginOffset: 16.0,
        viewportExtent: 1000.0,
        frozenExtent: 0.0,
      );

      expect(result, const TypeMatcher<DoNotScrollDragScrollData>());
    });
  });
}
//
