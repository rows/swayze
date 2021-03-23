import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/src/core/controller/scroll/auto_scroll_activity.dart';

class _MockScrollPositionWithSingleContext extends Mock
    implements ScrollPositionWithSingleContext {}

void main() {
  group('AutoScrollController', () {
    test('should calculate velocity accordingly to pointer distance', () {
      final controller = AutoScrollController(pointerDistance: 0);
      expect(controller.velocity, 0);

      controller.pointerDistance = 6;
      expect(controller.velocity, lessThan(0.3));

      controller.pointerDistance = 13;
      expect(controller.velocity, lessThan(0.8));

      controller.pointerDistance = 26;
      expect(controller.velocity, 2.0);

      controller.pointerDistance = 30;
      expect(controller.velocity, lessThan(2.6));

      controller.pointerDistance = 42;
      expect(controller.velocity, 3.0);

      controller.pointerDistance = 1000;
      expect(controller.velocity, 3.0);
    });
  });

  group('AutoScrollActivity', () {
    test('should be able to scroll forward until maxToScroll', () {
      final controller = AutoScrollController(pointerDistance: 26);

      final position = _MockScrollPositionWithSingleContext();

      when(() => position.extentBefore).thenReturn(0.0);
      when(() => position.extentAfter).thenReturn(2000.0);
      when(() => position.applyUserOffset);

      final activity = AutoScrollActivity(
        delegate: position,
        position: position,
        direction: GrowthDirection.forward,
        controller: controller,
        maxToScroll: 1000,
      );

      activity.onTick(10);
      verify(() => position.applyUserOffset(-20.0)).called(1);

      activity.onTick(100);
      verify(() => position.applyUserOffset(-200.0)).called(1);

      activity.onTick(1000);
      verify(() => position.applyUserOffset(-780.0)).called(1);
    });

    test('should be able to scroll reverse until maxToScroll', () {
      final controller = AutoScrollController(pointerDistance: 26);

      final position = _MockScrollPositionWithSingleContext();

      when(() => position.extentBefore).thenReturn(2000.0);
      when(() => position.extentAfter).thenReturn(0.0);
      when(() => position.applyUserOffset);

      final activity = AutoScrollActivity(
        delegate: position,
        position: position,
        direction: GrowthDirection.reverse,
        controller: controller,
        maxToScroll: 1000,
      );

      activity.onTick(10);
      verify(() => position.applyUserOffset(20.0)).called(1);

      activity.onTick(100);
      verify(() => position.applyUserOffset(200.0)).called(1);

      activity.onTick(1000);
      verify(() => position.applyUserOffset(780.0)).called(1);
    });

    test('should call goIdle once it has scrolled the maxToScroll', () {
      final controller = AutoScrollController(pointerDistance: 26);

      final position = _MockScrollPositionWithSingleContext();

      when(() => position.extentBefore).thenReturn(0.0);
      when(() => position.extentAfter).thenReturn(2000.0);
      when(() => position.applyUserOffset);
      when(() => position.goIdle);

      final activity = AutoScrollActivity(
        delegate: position,
        position: position,
        direction: GrowthDirection.forward,
        controller: controller,
        maxToScroll: 1000,
      );

      activity.onTick(1000);
      verify(() => position.applyUserOffset(-1000.0)).called(1);

      activity.onTick(2);
      verify(position.goIdle).called(1);
    });

    test('should use the extent value if maxToScroll exceeds it', () {
      final controller = AutoScrollController(pointerDistance: 26);

      final position = _MockScrollPositionWithSingleContext();
      when(() => position.extentBefore).thenReturn(0.0);
      when(() => position.extentAfter).thenReturn(1000.0);
      when(() => position.applyUserOffset);

      final activity = AutoScrollActivity(
        delegate: position,
        position: position,
        direction: GrowthDirection.forward,
        controller: controller,
        maxToScroll: 2000,
      );

      activity.onTick(10);
      verify(() => position.applyUserOffset(-20.0)).called(1);

      activity.onTick(100);
      verify(() => position.applyUserOffset(-200.0)).called(1);

      activity.onTick(1000);
      verify(() => position.applyUserOffset(-780.0)).called(1);
    });
  });
}
