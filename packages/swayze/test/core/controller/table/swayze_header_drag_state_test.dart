import 'package:flutter/material.dart';
import 'package:swayze/src/core/controller/table/header_state.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

void main() {
  group('Swayze header drag state', () {
    test('is allowed to drop', () {
      expect(
        const SwayzeHeaderDragState(
          headers: Range(0, 5),
          position: Offset(10, 0),
          dropAtIndex: 10,
        ).isDropAllowed,
        isTrue,
      );
      expect(
        const SwayzeHeaderDragState(
          headers: Range(0, 5),
          position: Offset(10, 0),
          dropAtIndex: 6,
        ).isDropAllowed,
        isTrue,
      );
      expect(
        const SwayzeHeaderDragState(
          headers: Range(10, 11),
          position: Offset(10, 0),
          dropAtIndex: 9,
        ).isDropAllowed,
        isTrue,
      );
    });

    test('is not allowed to drop', () {
      expect(
        const SwayzeHeaderDragState(
          headers: Range(0, 5),
          position: Offset(10, 0),
          dropAtIndex: 2,
        ).isDropAllowed,
        isFalse,
      );
      expect(
        const SwayzeHeaderDragState(
          headers: Range(10, 11),
          position: Offset(10, 0),
          dropAtIndex: 10,
        ).isDropAllowed,
        isFalse,
      );
      expect(
        const SwayzeHeaderDragState(
          headers: Range(10, 15),
          position: Offset(10, 0),
          dropAtIndex: 14,
        ).isDropAllowed,
        isFalse,
      );
    });

    test('equality', () {
      expect(
        const SwayzeHeaderDragState(
          headers: Range(0, 5),
          position: Offset(10, 0),
          dropAtIndex: 10,
        ),
        const SwayzeHeaderDragState(
          headers: Range(0, 5),
          position: Offset(10, 0),
          dropAtIndex: 10,
        ),
      );
    });
  });
}
