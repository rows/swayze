import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import 'swayze_intent.dart';

/// A [SwayzeIntent] to start a header drag by creating a new
/// [SwayzeHeaderDragState].
class HeaderDragStartIntent extends SwayzeIntent {
  /// Headers being dragged.
  final Range headers;

  /// Headers axis.
  final Axis axis;

  /// Current drag offset.
  final Offset draggingPosition;

  const HeaderDragStartIntent({
    required this.headers,
    required this.axis,
    required this.draggingPosition,
  });
}

/// A [SwayzeIntent] to update the current drag state by setting a new given
/// [draggingPosition] and a new reference [header].
class HeaderDragUpdateIntent extends SwayzeIntent {
  /// The current header index where the [draggingPosition] is on top of.
  ///
  /// This would be the index to move the current dragged headers if a
  /// [HeaderDragEndIntent] is invoked.
  final int header;

  /// Header axis.
  final Axis axis;

  /// Current drag offset.
  final Offset draggingPosition;

  const HeaderDragUpdateIntent({
    required this.header,
    required this.axis,
    required this.draggingPosition,
  });
}

/// A [SwayzeIntent] that completes a drag event (a drop action), it should
/// end the [SwayzeHeaderDragState].
class HeaderDragEndIntent extends SwayzeIntent {
  /// The current header index where the headers should be moved to.
  final int header;

  /// Header axis.
  final Axis axis;

  const HeaderDragEndIntent({
    required this.header,
    required this.axis,
  });
}

/// A [SwayzeIntent] to cancel a drag action resetting [SwayzeHeaderDragState].
class HeaderDragCancelIntent extends SwayzeIntent {
  /// Header axis.
  final Axis axis;

  const HeaderDragCancelIntent(this.axis);
}
