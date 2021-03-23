import 'dart:math';

import 'package:meta/meta.dart';

import 'int_vector2.dart';
import 'range.dart';

/// Defines an underlying rectangle in an [int] universe. Each dimension can be
/// defined by a [Range]
@immutable
class Range2D {
  final IntVector2 leftTop;
  final IntVector2 rightBottom;

  IntVector2 get rightTop => IntVector2(rightBottom.dx, leftTop.dy);

  IntVector2 get leftBottom => IntVector2(leftTop.dx, rightBottom.dy);

  const Range2D.fromLTRB(this.leftTop, this.rightBottom)
      : assert(leftTop != rightBottom),
        assert(leftTop <= rightBottom);

  Range2D.fromPoints(IntVector2 a, IntVector2 b)
      : leftTop = IntVector2(min(a.dx, b.dx), min(a.dy, b.dy)),
        rightBottom = IntVector2(max(a.dx, b.dx), max(a.dy, b.dy));

  const Range2D.fromLTWH(this.leftTop, IntVector2 size)
      : rightBottom = leftTop + size;

  Range2D.fromSides(Range horizontal, Range vertical)
      : leftTop = IntVector2(horizontal.start, vertical.start),
        rightBottom = IntVector2(horizontal.end, vertical.end);

  IntVector2 get size => rightBottom - leftTop;

  Range get xRange => Range(leftTop.dx, rightBottom.dx);

  Range get yRange => Range(leftTop.dy, rightBottom.dy);

  bool get isNil => xRange.isNil || yRange.isNil;

  bool overlaps(Range2D otherRange) =>
      xRange.overlaps(otherRange.xRange) && yRange.overlaps(otherRange.yRange);

  /// Defines if this range contains [otherRange] entirely
  bool containsRange(Range2D otherRange) {
    return xRange.containsRange(otherRange.xRange) &&
        yRange.containsRange(otherRange.yRange);
  }

  /// Defines if this range contains a specific vector
  bool containsVector(IntVector2 intVector2) {
    return xRange.contains(intVector2.dx) && yRange.contains(intVector2.dy);
  }

  Range2D operator &(Range2D other) {
    final xRange = this.xRange & other.xRange;
    final yRange = this.yRange & other.yRange;
    return Range2D.fromSides(xRange, yRange);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range2D &&
          runtimeType == other.runtimeType &&
          leftTop == other.leftTop &&
          rightBottom == other.rightBottom;

  @override
  int get hashCode => leftTop.hashCode ^ rightBottom.hashCode;

  @override
  String toString() => 'Range2D(leftTop: $leftTop, rightBottom: $rightBottom)';
}
