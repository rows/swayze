import 'package:meta/meta.dart';

/// A 2D vector of ints
@immutable
class IntVector2 {
  final int dx;
  final int dy;

  const IntVector2(this.dx, this.dy);

  const IntVector2.symmetric(int side)
      : dx = side,
        dy = side;

  IntVector2.from(IntVector2 other)
      : dx = other.dx,
        dy = other.dy;

  IntVector2 get flipped => IntVector2(dy, dx);

  IntVector2 copyWith({int? x, int? y}) => IntVector2(x ?? dx, y ?? dy);

  /// Returns a new vector that represents the dimensions of a diff between two
  /// vectors
  IntVector2 operator -(IntVector2 otherVector) => IntVector2(
        dx - otherVector.dx,
        dy - otherVector.dy,
      );

  IntVector2 operator +(IntVector2 otherVector) => IntVector2(
        dx + otherVector.dx,
        dy + otherVector.dy,
      );

  bool operator <(IntVector2 otherVector) {
    return dx < otherVector.dx && dy < otherVector.dy;
  }

  bool operator >(IntVector2 otherVector) {
    return dx > otherVector.dx && dy > otherVector.dy;
  }

  bool operator <=(IntVector2 otherVector) {
    return dx <= otherVector.dx && dy <= otherVector.dy;
  }

  bool operator >=(IntVector2 otherVector) {
    return dx >= otherVector.dx && dy >= otherVector.dy;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntVector2 &&
          runtimeType == other.runtimeType &&
          dx == other.dx &&
          dy == other.dy;

  @override
  int get hashCode => dx.hashCode ^ dy.hashCode;

  @override
  String toString() => 'IntVector2($dx, $dy)';
}
