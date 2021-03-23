/// The four corners in a rectangular shape.
///
/// See also:
/// * [CellUserSelectionModel.anchorCorner] that describes which corner is the
///   anchor of a cell selection.
enum Corner { leftTop, rightTop, leftBottom, rightBottom }

/// Add methods to each [Corner] option.
extension CornerMethods on Corner {
  /// The geometrically opposite of a [Corner].
  ///
  /// See also:
  /// * [CellUserSelectionModel.focus] that is in the opposite of
  /// [CellUserSelectionModel.anchorCorner]
  Corner get opposite {
    switch (this) {
      case Corner.leftTop:
        return Corner.rightBottom;
      case Corner.rightTop:
        return Corner.leftBottom;
      case Corner.leftBottom:
        return Corner.rightTop;
      case Corner.rightBottom:
        return Corner.leftTop;
    }
  }
}

/// The edge of a one dimensional shape.
///
/// See also:
/// * [HeaderUserSelectionModel.anchorEdge] that describes which edge is anchor.
enum RangeEdge { leading, trailing }

/// Add methods to each [RangeEdge] option.
extension RangeEdgeMethods on RangeEdge {
  /// The geometrically opposite of a [RangeEdge].
  RangeEdge get opposite {
    switch (this) {
      case RangeEdge.leading:
        return RangeEdge.trailing;
      case RangeEdge.trailing:
        return RangeEdge.leading;
    }
  }
}
