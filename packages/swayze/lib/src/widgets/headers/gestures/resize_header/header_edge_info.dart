import 'package:meta/meta.dart';

@immutable
class HeaderEdgeInfo {
  final int index;
  final double width;
  final int displacement;
  final double offset;

  const HeaderEdgeInfo({
    required this.index,
    required this.width,
    required this.displacement,
    required this.offset,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is HeaderEdgeInfo &&
        other.index == index &&
        other.width == width &&
        other.displacement == displacement &&
        other.offset == offset;
  }

  @override
  int get hashCode =>
      index.hashCode ^ width.hashCode ^ displacement.hashCode ^ offset.hashCode;
}
