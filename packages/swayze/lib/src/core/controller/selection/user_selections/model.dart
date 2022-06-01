import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../helpers/basic_types.dart';
import '../model/selection.dart';
import '../model/selection_style.dart';

/// Defines a [Selection] that is controllable by a [UserSelectionState].
abstract class UserSelectionModel extends Selection {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSelectionModel && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

/// A completely unbounded [UserSelectionModel].
/// It selects the entire table.
class TableUserSelectionModel implements UserSelectionModel {
  @override
  final SelectionStyle? style = null;

  TableUserSelectionModel._({
    required this.anchorCoordinate,
  });

  factory TableUserSelectionModel.fromSelectionModel(
    UserSelectionModel original,
  ) {
    return TableUserSelectionModel._(
      anchorCoordinate: original.anchorCoordinate,
    );
  }

  @override
  int? get bottom => null;

  @override
  int? get left => null;

  @override
  int? get right => null;

  @override
  int? get top => null;

  @override
  IntVector2 get focusCoordinate => anchorCoordinate;

  @override
  late final IntVector2 anchorCoordinate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableUserSelectionModel &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          anchorCoordinate == other.anchorCoordinate;

  @override
  int get hashCode => style.hashCode ^ anchorCoordinate.hashCode;
}

/// A [UserSelectionModel] that covers entire columns or rows.
///
/// Unlike [CellUserSelectionModel], the edges of this kind of selection are
/// defined only by coordinates in one [axis], the selection is assumed to cover
/// the totality of the opposite (cross) axis.
///
/// Its [anchor] and [focus] are indices of columns/rows.
///
/// It is always constructed via [AxisBoundedSelection.crossAxisUnbounded].
class HeaderUserSelectionModel extends AxisBoundedSelection
    implements UserSelectionModel {
  /// See [UserSelectionModel.style]
  @override
  final SelectionStyle? style;

  const HeaderUserSelectionModel._({
    required Axis boundedAxis,
    required RangeEdge anchorEdge,
    required int start,
    required int end,
    required this.style,
  }) : super.crossAxisUnbounded(
          axis: boundedAxis,
          anchorEdge: anchorEdge,
          start: start,
          end: end,
        );

  /// Create a [HeaderUserSelectionModel] given its edges
  /// ([anchor] and [focus]).
  ///
  /// if [id] is omitted, an uuid is generated.
  ///
  /// Since this selection is simply a [Range], we convert [anchor] and [focus]
  /// into range's [start] and [end] values.
  factory HeaderUserSelectionModel.fromAnchorFocus({
    required int anchor,
    required int focus,
    required Axis axis,
    SelectionStyle? style,
  }) {
    final start = min(anchor, focus);

    // Focus and anchor are inclusive, end on the range is not.
    final end = max(anchor, focus) + 1;

    final anchorEdge = anchor <= focus ? RangeEdge.leading : RangeEdge.trailing;

    return HeaderUserSelectionModel._(
      anchorEdge: anchorEdge,
      start: start,
      end: end,
      boundedAxis: axis,
      style: style,
    );
  }

  /// Create a [HeaderUserSelectionModel] from any [UserSelectionModel] given
  /// an [anchor], [focus] and [axis].
  factory HeaderUserSelectionModel.fromSelectionModel(
    UserSelectionModel original, {
    required int anchor,
    required int focus,
    required Axis axis,
  }) {
    return HeaderUserSelectionModel.fromAnchorFocus(
      anchor: anchor,
      focus: focus,
      axis: axis,
      style: original.style,
    );
  }

  /// Creates a copy of [HeaderUserSelectionModel] with the specified properties
  /// replaced.
  ///
  /// Calling this method on a selection will return a new transformed selection
  /// based on the provided properties.
  HeaderUserSelectionModel copyWith({
    int? anchor,
    int? focus,
    Axis? axis,
    SelectionStyle? style,
  }) =>
      HeaderUserSelectionModel.fromAnchorFocus(
        anchor: anchor ?? this.anchor,
        focus: focus ?? this.focus,
        axis: axis ?? this.axis,
        style: style ?? this.style,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (super == other &&
          other is HeaderUserSelectionModel &&
          runtimeType == other.runtimeType &&
          style == other.style);

  @override
  int get hashCode => super.hashCode ^ style.hashCode;
}

/// A [UserSelectionModel] that represents a [Range2D] of cells.
///
/// Unlike [HeaderUserSelectionModel], the edges of this king of selection are
/// defined by the coordinates in both axis. The selection only covers the
/// cells in the axis.
class CellUserSelectionModel extends BoundedSelection
    implements UserSelectionModel {
  @override
  final SelectionStyle? style;

  CellUserSelectionModel._({
    required IntVector2 leftTop,
    required IntVector2 rightBottom,
    required Corner anchorCorner,
    required this.style,
  }) : super(
          leftTop: leftTop,
          rightBottom: rightBottom,
          anchorCorner: anchorCorner,
        );

  /// Create a [CellUserSelectionModel] given its opposite corners
  /// ([anchor] and [focus]).
  ///
  /// If [id] is omitted, an uuid is generated.
  ///
  /// Since this selection is a [Range2D], we convert [anchor] and [focus]
  /// into range's [leftTop] and [rightBottom] values.
  factory CellUserSelectionModel.fromAnchorFocus({
    required IntVector2 anchor,
    required IntVector2 focus,
    SelectionStyle? style,
  }) {
    final leftTop = IntVector2(
      min(anchor.dx, focus.dx),
      min(anchor.dy, focus.dy),
    );

    // Focus and anchor are inclusive, rightBottom on Range2D is not.
    final rightBottom = IntVector2(
      max(anchor.dx, focus.dx) + 1,
      max(anchor.dy, focus.dy) + 1,
    );

    // Define where the anchor is from their positions
    late Corner anchorCorner;
    if (anchor.dx <= focus.dx && anchor.dy <= focus.dy) {
      anchorCorner = Corner.leftTop;
    } else if (anchor.dx >= focus.dx && anchor.dy >= focus.dy) {
      anchorCorner = Corner.rightBottom;
    } else if (anchor.dx < focus.dx) {
      anchorCorner = Corner.leftBottom;
    } else {
      anchorCorner = Corner.rightTop;
    }

    return CellUserSelectionModel._(
      leftTop: leftTop,
      rightBottom: rightBottom,
      anchorCorner: anchorCorner,
      style: style,
    );
  }

  /// Create a [CellUserSelectionModel] from any [UserSelectionModel] given an
  /// [anchor] and [focus].
  factory CellUserSelectionModel.fromSelectionModel(
    UserSelectionModel original, {
    required IntVector2 anchor,
    required IntVector2 focus,
  }) {
    return CellUserSelectionModel.fromAnchorFocus(
      anchor: anchor,
      focus: focus,
      style: original.style,
    );
  }

  /// Whether this selection that covers only one cell
  bool get isSingleCell => isSingle;

  /// Creates a copy of the selection with the specified properties replaced.
  ///
  /// Calling this method on a selection will return a new transformed selection
  /// based on the provided properties.
  CellUserSelectionModel copyWith({
    IntVector2? anchor,
    IntVector2? focus,
    SelectionStyle? style,
  }) =>
      CellUserSelectionModel.fromAnchorFocus(
        anchor: anchor ?? this.anchor,
        focus: focus ?? this.focus,
        style: style ?? this.style,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CellUserSelectionModel &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => super.hashCode ^ style.hashCode;
}
