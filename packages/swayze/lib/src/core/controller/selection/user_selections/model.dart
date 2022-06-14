// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/basic_types.dart';
import '../model/selection.dart';
import '../model/selection_style.dart';

const _uuid = Uuid();

/// Defines a [Selection] that is controllable by a [UserSelectionState].
abstract class UserSelectionModel extends Selection {
  /// Unique identifier of a selection in a [UserSelectionState]
  @Deprecated('')
  String get id;

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
  @Deprecated('')
  final String id;

  @override
  final SelectionStyle? style = null;

  TableUserSelectionModel._({
    @Deprecated('') String? id,
    required this.anchorCoordinate,
  }) : id = id ?? _uuid.v4();

  factory TableUserSelectionModel.fromSelectionModel(
    UserSelectionModel original,
  ) {
    return TableUserSelectionModel._(
      id: original.id,
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
          id == other.id &&
          style == other.style &&
          anchorCoordinate == other.anchorCoordinate;

  @override
  int get hashCode => id.hashCode ^ style.hashCode ^ anchorCoordinate.hashCode;
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
  /// See [UserSelectionModel.id]
  @override
  @Deprecated('')
  final String id;

  /// See [UserSelectionModel.style]
  @override
  final SelectionStyle? style;

  HeaderUserSelectionModel._({
    @Deprecated('') String? id,
    required Axis boundedAxis,
    required RangeEdge anchorEdge,
    required int start,
    required int end,
    required this.style,
  })  : id = id ?? _uuid.v4(),
        super.crossAxisUnbounded(
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
    @Deprecated('') String? id,
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
      id: id,
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
      id: original.id,
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
        id: id,
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
  int get hashCode => super.hashCode ^ id.hashCode ^ style.hashCode;
}

/// A [UserSelectionModel] that represents a [Range2D] of cells.
///
/// Unlike [HeaderUserSelectionModel], the edges of this kind of selection are
/// defined by the coordinates in both axis. The selection only covers the
/// cells in the axis.
class CellUserSelectionModel extends BoundedSelection
    implements UserSelectionModel {
  @override
  @Deprecated('')
  final String id;

  @override
  final SelectionStyle? style;

  CellUserSelectionModel._({
    @Deprecated('') String? id,
    required IntVector2 leftTop,
    required IntVector2 rightBottom,
    required Corner anchorCorner,
    required this.style,
  })  : id = id ?? _uuid.v4(),
        super(
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
    @Deprecated('') String? id,
    required IntVector2 anchor,
    required IntVector2 focus,
    SelectionStyle? style,
  }) {
    final range = _calculateRange(
      anchor: anchor,
      focus: focus,
    );

    // Define where the anchor is from their positions
    final anchorCorner = _calculateCorner(
      anchor: anchor,
      focus: focus,
    );

    return CellUserSelectionModel._(
      id: id,
      leftTop: range.leftTop,
      rightBottom: range.rightBottom,
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
      id: original.id,
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
        id: id,
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
          id == other.id &&
          style == other.style;

  @override
  int get hashCode => super.hashCode ^ id.hashCode ^ style.hashCode;
}

/// A [UserSelectionModel] that represents a [Range2D] used on drag and fill
/// cells operations.
///
/// Unlike [HeaderUserSelectionModel], the edges of this kind of selection are
/// defined by the coordinates in both axis. The selection only covers the
/// cells in the axis.
class FillSelectionModel extends BoundedSelection
    implements UserSelectionModel {
  @override
  @Deprecated('')
  final String id;

  @override
  final SelectionStyle? style;

  FillSelectionModel._({
    @Deprecated('') String? id,
    required IntVector2 leftTop,
    required IntVector2 rightBottom,
    required Corner anchorCorner,
    required this.style,
  })  : id = id ?? _uuid.v4(),
        super(
          leftTop: leftTop,
          rightBottom: rightBottom,
          anchorCorner: anchorCorner,
        );

  /// Create a [FillSelectionModel] given its opposite corners
  /// ([anchor] and [focus]).
  ///
  /// If [id] is omitted, an uuid is generated.
  ///
  /// Since this selection is a [Range2D], we convert [anchor] and [focus]
  /// into range's [leftTop] and [rightBottom] values.
  factory FillSelectionModel.fromAnchorFocus({
    @Deprecated('') String? id,
    required IntVector2 anchor,
    required IntVector2 focus,
    SelectionStyle? style,
  }) {
    final range = _calculateRange(
      anchor: anchor,
      focus: focus,
    );

    return FillSelectionModel._(
      id: id,
      leftTop: range.leftTop,
      rightBottom: range.rightBottom,
      anchorCorner: _calculateCorner(
        anchor: anchor,
        focus: focus,
      ),
      style: style,
    );
  }

  /// Creates a [FillSelectionModel] from any [UserSelectionModel] given an
  /// [anchor] and [focus].
  factory FillSelectionModel.fromSelectionModel(
    UserSelectionModel original, {
    required IntVector2 anchor,
    required IntVector2 focus,
  }) =>
      FillSelectionModel.fromAnchorFocus(
        id: original.id,
        anchor: anchor,
        focus: focus,
        style: original.style,
      );

  /// Creates a copy of the selection with the specified properties replaced.
  ///
  /// Calling this method on a selection will return a new transformed selection
  /// based on the provided properties.
  FillSelectionModel copyWith({
    IntVector2? anchor,
    IntVector2? focus,
    SelectionStyle? style,
  }) =>
      FillSelectionModel.fromAnchorFocus(
        id: id,
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
          id == other.id &&
          style == other.style;

  @override
  int get hashCode => super.hashCode ^ id.hashCode ^ style.hashCode;
}

/// Returns an inclusive range with points based on [anchor] and [focus].
Range2D _calculateRange({
  required IntVector2 anchor,
  required IntVector2 focus,
}) {
  return Range2D.fromPoints(
    IntVector2(
      min(anchor.dx, focus.dx),
      min(anchor.dy, focus.dy),
    ),
    // Focus and anchor are inclusive, rightBottom on Range2D is not.
    IntVector2(
      max(anchor.dx, focus.dx) + 1,
      max(anchor.dy, focus.dy) + 1,
    ),
  );
}

/// Returns the corner based on the given [anchor] and [focus].
Corner _calculateCorner({
  required IntVector2 anchor,
  required IntVector2 focus,
}) {
  if (anchor.dx <= focus.dx && anchor.dy <= focus.dy) {
    return Corner.leftTop;
  }

  if (anchor.dx >= focus.dx && anchor.dy >= focus.dy) {
    return Corner.rightBottom;
  }

  if (anchor.dx < focus.dx) {
    return Corner.leftBottom;
  }

  return Corner.rightTop;
}
