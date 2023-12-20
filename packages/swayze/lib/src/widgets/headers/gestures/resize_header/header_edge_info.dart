import 'package:meta/meta.dart';

@immutable
class HeaderEdgeInfo {
  /// The header index of the hovered edge.
  final int index;

  /// The header width of the hovered edge.
  final double width;

  /// This value is the offset from the header separator to the mouse cursor.
  ///
  /// Useful to display the resize line at the header separator and not a bit
  /// to the left or right of it (since when hovering the edge, the resize
  /// cursor still shows when the user hovers a bit to the left or right
  /// of the separator).
  final int displacement;

  /// The position of the header separator (which together with the
  /// [displacement] can be used to know if the user is hovering an header's
  /// edge or not.
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
