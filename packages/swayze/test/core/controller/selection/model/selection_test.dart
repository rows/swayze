import 'package:flutter/painting.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

class _TestAxisBoundedSelection extends AxisBoundedSelection {
  const _TestAxisBoundedSelection.crossAxisPartiallyBounded({
    required Axis axis,
    required RangeEdge anchorEdge,
    required int start,
    required int end,
    required RangeEdge crossAxisBoundedEdge,
    required int crossAxisBound,
  }) : super.crossAxisPartiallyBounded(
          axis: axis,
          anchorEdge: anchorEdge,
          start: start,
          end: end,
          crossAxisBoundedEdge: crossAxisBoundedEdge,
          crossAxisBound: crossAxisBound,
        );

  const _TestAxisBoundedSelection.crossAxisUnbounded({
    required Axis axis,
    required RangeEdge anchorEdge,
    required int start,
    required int end,
  }) : super.crossAxisUnbounded(
          axis: axis,
          anchorEdge: anchorEdge,
          start: start,
          end: end,
        );

  @override
  SelectionStyle? get style => throw UnimplementedError();
}

class _TestBoundedSelection extends BoundedSelection {
  _TestBoundedSelection({
    required IntVector2 leftTop,
    required IntVector2 rightBottom,
    required Corner anchorCorner,
  }) : super(
          leftTop: leftTop,
          rightBottom: rightBottom,
          anchorCorner: anchorCorner,
        );

  @override
  SelectionStyle? get style => throw UnimplementedError();
}

void main() {
  group('bound', () {
    group('AxisBoundedSelection', () {
      group('crossAxisUnbounded', () {
        group('in the range', () {
          test('should be bounded', () {
            const selection = _TestAxisBoundedSelection.crossAxisUnbounded(
              anchorEdge: RangeEdge.leading,
              axis: Axis.vertical,
              start: 2,
              end: 4,
            );

            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(0, 1),
                const IntVector2(5, 6),
              ),
            );

            expect(
              result,
              Range2D.fromLTRB(
                const IntVector2(0, 2),
                const IntVector2(5, 4),
              ),
            );
          });
        });
        group('partially in the range', () {
          test('should be bounded', () {
            const selection = _TestAxisBoundedSelection.crossAxisUnbounded(
              anchorEdge: RangeEdge.leading,
              axis: Axis.horizontal,
              start: 2,
              end: 14,
            );

            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(10, 11),
                const IntVector2(15, 16),
              ),
            );

            expect(
              result,
              Range2D.fromLTRB(
                const IntVector2(10, 11),
                const IntVector2(14, 16),
              ),
            );
          });
        });
        group('out of the range', () {
          test('should be bounded', () {
            const selection = _TestAxisBoundedSelection.crossAxisUnbounded(
              anchorEdge: RangeEdge.leading,
              axis: Axis.vertical,
              start: 12,
              end: 14,
            );

            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(100, 101),
                const IntVector2(102, 103),
              ),
            );

            expect(
              result,
              Range2D.fromPoints(
                const IntVector2(100, 101),
                const IntVector2(102, 101),
              ),
            );
          });
        });
      });
      group('crossAxisPartiallyBounded', () {
        group('in the range', () {
          test('should be bounded', () {
            const selection =
                _TestAxisBoundedSelection.crossAxisPartiallyBounded(
              anchorEdge: RangeEdge.leading,
              axis: Axis.vertical,
              start: 2,
              end: 4,
              crossAxisBound: 4,
              crossAxisBoundedEdge: RangeEdge.trailing,
            );

            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(0, 1),
                const IntVector2(5, 6),
              ),
            );

            expect(
              result,
              Range2D.fromLTRB(
                const IntVector2(0, 2),
                const IntVector2(4, 4),
              ),
            );
          });
        });
        group('partially in the range', () {
          test('should be bounded', () {
            const selection =
                _TestAxisBoundedSelection.crossAxisPartiallyBounded(
              anchorEdge: RangeEdge.leading,
              axis: Axis.horizontal,
              start: 2,
              end: 14,
              crossAxisBound: 13,
              crossAxisBoundedEdge: RangeEdge.leading,
            );

            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(10, 11),
                const IntVector2(15, 16),
              ),
            );

            expect(
              result,
              Range2D.fromLTRB(
                const IntVector2(10, 13),
                const IntVector2(14, 16),
              ),
            );
          });
        });
        group('out of the range', () {
          test('should be bounded', () {
            const selection =
                _TestAxisBoundedSelection.crossAxisPartiallyBounded(
              anchorEdge: RangeEdge.leading,
              axis: Axis.vertical,
              start: 12,
              end: 14,
              crossAxisBound: 2,
              crossAxisBoundedEdge: RangeEdge.leading,
            );

            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(100, 101),
                const IntVector2(102, 103),
              ),
            );

            expect(
              result,
              Range2D.fromPoints(
                const IntVector2(100, 101),
                const IntVector2(102, 101),
              ),
            );
          });
        });
      });
    });
    group('BoundedSelection', () {
      group('in the range', () {
        test('should be bounded', () {
          final selection = _TestBoundedSelection(
            leftTop: const IntVector2(2, 3),
            rightBottom: const IntVector2(4, 5),
            anchorCorner: Corner.leftTop,
          );
          final result = selection.bound(
            to: Range2D.fromLTRB(
              const IntVector2(0, 1),
              const IntVector2(9, 10),
            ),
          );

          expect(
            result,
            Range2D.fromPoints(
              const IntVector2(2, 3),
              const IntVector2(4, 5),
            ),
          );
        });
      });
      group('partially in the range', () {
        group('to the left top', () {
          test('should be bounded', () {
            final selection = _TestBoundedSelection(
              leftTop: const IntVector2(2, 3),
              rightBottom: const IntVector2(14, 15),
              anchorCorner: Corner.leftTop,
            );
            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(10, 11),
                const IntVector2(19, 20),
              ),
            );

            expect(
              result,
              Range2D.fromPoints(
                const IntVector2(10, 11),
                const IntVector2(14, 15),
              ),
            );
          });
        });
        group('to the right bottom', () {
          test('should be bounded', () {
            final selection = _TestBoundedSelection(
              leftTop: const IntVector2(12, 13),
              rightBottom: const IntVector2(24, 25),
              anchorCorner: Corner.leftTop,
            );
            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(10, 11),
                const IntVector2(19, 20),
              ),
            );

            expect(
              result,
              Range2D.fromPoints(
                const IntVector2(12, 13),
                const IntVector2(19, 20),
              ),
            );
          });
        });
      });
      group('out of the range', () {
        group('to the left top', () {
          test('should be bounded', () {
            final selection = _TestBoundedSelection(
              leftTop: const IntVector2(2, 3),
              rightBottom: const IntVector2(4, 5),
              anchorCorner: Corner.leftTop,
            );
            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(10, 11),
                const IntVector2(19, 20),
              ),
            );

            expect(
              result,
              Range2D.fromPoints(
                const IntVector2(10, 11),
                const IntVector2(10, 11),
              ),
            );
          });
        });
        group('to the right bottom', () {
          test('should be bounded', () {
            final selection = _TestBoundedSelection(
              leftTop: const IntVector2(22, 23),
              rightBottom: const IntVector2(24, 25),
              anchorCorner: Corner.leftTop,
            );
            final result = selection.bound(
              to: Range2D.fromLTRB(
                const IntVector2(10, 11),
                const IntVector2(19, 20),
              ),
            );

            expect(
              result,
              Range2D.fromPoints(
                const IntVector2(19, 20),
                const IntVector2(19, 20),
              ),
            );
          });
        });
      });
    });
  });
  group('AxisBoundedSelection', () {
    group('anchor/focus', () {
      group('crossAxisUnbounded', () {
        test('anchor edge leading', () {
          const selection = _TestAxisBoundedSelection.crossAxisUnbounded(
            axis: Axis.horizontal,
            anchorEdge: RangeEdge.leading,
            start: 3,
            end: 5,
          );

          expect(selection.anchor, 3);
          expect(selection.focus, 4);
          expect(selection.anchorCoordinate, const IntVector2(3, 0));
          expect(selection.focusCoordinate, const IntVector2(4, 0));
        });
        test('anchor edge trailing', () {
          const selection = _TestAxisBoundedSelection.crossAxisUnbounded(
            axis: Axis.horizontal,
            anchorEdge: RangeEdge.trailing,
            start: 3,
            end: 5,
          );

          expect(selection.anchor, 4);
          expect(selection.focus, 3);
          expect(selection.anchorCoordinate, const IntVector2(4, 0));
          expect(selection.focusCoordinate, const IntVector2(3, 0));
        });
      });
      group('crossAxisPartiallyBounded', () {
        test('anchor edge leading', () {
          const selection = _TestAxisBoundedSelection.crossAxisPartiallyBounded(
            axis: Axis.horizontal,
            anchorEdge: RangeEdge.leading,
            start: 3,
            end: 5,
            crossAxisBound: 8,
            crossAxisBoundedEdge: RangeEdge.leading,
          );

          expect(selection.anchor, 3);
          expect(selection.focus, 4);
          expect(selection.anchorCoordinate, const IntVector2(3, 8));
          expect(selection.focusCoordinate, const IntVector2(4, 8));
        });
      });
      test('anchor edge trailing', () {
        const selection = _TestAxisBoundedSelection.crossAxisPartiallyBounded(
          axis: Axis.horizontal,
          anchorEdge: RangeEdge.trailing,
          start: 3,
          end: 5,
          crossAxisBound: 8,
          crossAxisBoundedEdge: RangeEdge.leading,
        );

        expect(selection.anchor, 4);
        expect(selection.focus, 3);
        expect(selection.anchorCoordinate, const IntVector2(4, 8));
        expect(selection.focusCoordinate, const IntVector2(3, 8));
      });
    });
  });

  group('BoundedSelection', () {
    group('anchor/focus', () {
      group('leftTop/rightBottom', () {
        test('anchor is leftTop', () {
          final selection = _TestBoundedSelection(
            leftTop: const IntVector2(2, 3),
            rightBottom: const IntVector2(4, 5),
            anchorCorner: Corner.leftTop,
          );

          expect(selection.anchor, const IntVector2(2, 3));
          expect(selection.focus, const IntVector2(3, 4));
        });

        test('anchor is rightBottom', () {
          final selection = _TestBoundedSelection(
            leftTop: const IntVector2(2, 3),
            rightBottom: const IntVector2(4, 5),
            anchorCorner: Corner.rightBottom,
          );

          expect(selection.anchor, const IntVector2(3, 4));
          expect(selection.focus, const IntVector2(2, 3));
        });
      });
      group('rightTop/leftBottom', () {
        test('anchor is rightTop', () {
          final selection = _TestBoundedSelection(
            leftTop: const IntVector2(2, 3),
            rightBottom: const IntVector2(4, 5),
            anchorCorner: Corner.rightTop,
          );

          expect(selection.anchor, const IntVector2(3, 3));
          expect(selection.focus, const IntVector2(2, 4));
        });
        test('anchor is leftBottom', () {
          final selection = _TestBoundedSelection(
            leftTop: const IntVector2(2, 3),
            rightBottom: const IntVector2(4, 5),
            anchorCorner: Corner.leftBottom,
          );

          expect(selection.anchor, const IntVector2(2, 4));
          expect(selection.focus, const IntVector2(3, 3));
        });
      });
    });
  });
}
