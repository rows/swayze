import 'package:flutter/foundation.dart';
import 'package:swayze_math/swayze_math.dart';

/// A [LocalKey] that uses ranges as value.
@immutable
class RangePairKey extends LocalKey {
  final Range x;
  final Range y;

  const RangePairKey(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangePairKey &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
