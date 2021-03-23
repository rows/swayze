import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../style/style.dart';

const _kListEquality = ListEquality<double>();

const kDefaultDashIntervals = [5.0, 3.0, 6.0, 3.0];

/// Describes how each side of a [Selection] border should be rendered.
@immutable
class SelectionBorderSide {
  final Color? color;
  final double width;

  final bool dashed;

  /// The interval between dashes and empty spaces in a dashed border.
  ///
  /// For example, the array `[5, 10]` would result in dashes 5 pixels long
  /// followed by blank spaces 10 pixels long. The array `[5, 10, 5]` would
  /// result in a 5 pixel dash, a 10 pixel gap, a 5 pixel dash, a 5 pixel gap,
  /// a 10 pixel dash, etc.
  final List<double> dashIntervals;

  const SelectionBorderSide.solid({
    this.color,
    required this.width,
  })  : dashed = false,
        dashIntervals = const <double>[];

  const SelectionBorderSide.dashed({
    this.color,
    required this.width,
    this.dashIntervals = kDefaultDashIntervals,
  }) : dashed = true;

  const SelectionBorderSide.none()
      : dashed = false,
        dashIntervals = const <double>[],
        width = 0,
        color = null;

  /// Convert to [BorderSide].
  ///
  /// Defaults color to transparent black.
  /// Warning: flutter border size does not support dashed outline.
  BorderSide toFlutterBorderSide() {
    return BorderSide(
      color: color ?? const Color(0x00000000),
      width: width,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionBorderSide &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          width == other.width &&
          dashed == other.dashed &&
          _kListEquality.equals(dashIntervals, other.dashIntervals);

  @override
  int get hashCode =>
      color.hashCode ^
      width.hashCode ^
      dashed.hashCode ^
      dashIntervals.hashCode;
}

/// A decoration used in the widget tree to render a visual representation
/// of a [Selection].
@immutable
class SelectionStyle {
  final Color? backgroundColor;
  final SelectionBorderSide borderSide;

  const SelectionStyle({
    required this.backgroundColor,
    required this.borderSide,
  });

  /// Create a [SelectionStyle] with the predefined relation between
  /// border and background.
  ///
  /// This creates a [SelectionStyle] with a semi transparent background and a
  /// border both styled with [color].
  ///
  /// See also:
  /// - [UserSelectionModel] in which usually uses style for this defined on
  /// [SwayzeStyle]
  SelectionStyle.semiTransparent({
    required Color color,
    double borderWidth = 2.0,
  }) : this(
          backgroundColor: color.withOpacity(0.20),
          borderSide: SelectionBorderSide.solid(
            color: color,
            width: borderWidth,
          ),
        );

  /// Create a [SelectionStyle] with the predefined relation between
  /// border and background.
  SelectionStyle.dashedBorderOnly({
    required Color color,
    double borderWidth = 1.0,
  }) : this(
          backgroundColor: null,
          borderSide: SelectionBorderSide.dashed(
            color: color,
            width: borderWidth,
          ),
        );

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  SelectionStyle copyWith({
    Color? backgroundColor,
    SelectionBorderSide? borderSide,
    bool? dashed,
  }) {
    return SelectionStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderSide: borderSide ?? this.borderSide,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderSide == other.borderSide;

  @override
  int get hashCode => backgroundColor.hashCode ^ borderSide.hashCode;
}
