import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:swayze_math/swayze_math.dart';

/// A immutable data structure that holds data of a particular cell. It only
/// holds the relevant data to cell rendering on swayze.
///
/// This should be subclassed in the app side and overridden with feature
/// specific logic (like function data label).
///
/// When subclassing this, mind to override [isPristine].
@immutable
abstract class SwayzeCellData {
  final String id;

  final IntVector2 position;

  const SwayzeCellData({
    required this.id,
    required this.position,
  });

  @mustCallSuper
  Alignment get contentAlignment;

  /// Define if this cell data has no relevant value for cell display.
  @mustCallSuper
  bool get hasVisibleContent;

  @nonVirtual
  bool get hasNoVisibleContent => !hasVisibleContent;

  @mustCallSuper
  bool get isPristine => hasNoVisibleContent;

  /// Define if this cell data is completely empty,
  /// when it could be substituted by a null value.
  @mustCallSuper
  bool get isEmpty => isPristine;

  /// Define if this cell data is not completely empty,
  ///
  /// See also:
  /// * [isEmpty]
  /// * [isPristine]
  @nonVirtual
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeCellData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          position == other.position &&
          contentAlignment == other.contentAlignment &&
          hasVisibleContent == other.hasVisibleContent;

  @override
  int get hashCode =>
      id.hashCode ^
      position.hashCode ^
      contentAlignment.hashCode ^
      hasVisibleContent.hashCode;
}
