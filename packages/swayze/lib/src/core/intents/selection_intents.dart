import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../controller.dart';
import '../../widgets/table_body/gestures/table_body_gesture_detector.dart';
import 'swayze_intent.dart';

/// A [SwayzeIntent] to select the whole table
class SelectTableIntent extends SwayzeIntent {
  const SelectTableIntent();
}

/// A [SwayzeIntent] to move the [ActiveCell] in the given [AxisDirection]
class MoveActiveCellIntent extends SwayzeIntent {
  final AxisDirection direction;

  const MoveActiveCellIntent(this.direction);
}

/// A [SwayzeIntent] to move the [ActiveCell] in the given [AxisDirection]
/// by a block of cells.
class MoveActiveCellByBlockIntent extends SwayzeIntent {
  final AxisDirection direction;

  const MoveActiveCellByBlockIntent(this.direction);
}

/// A [SwayzeIntent] to expand the the current [Selection] in the given
/// [AxisDirection].
class ExpandSelectionIntent extends SwayzeIntent {
  final AxisDirection direction;

  const ExpandSelectionIntent(this.direction);
}

/// A [SwayzeIntent] to expand the current [Selection] in the given
/// [AxisDirection] by a block of cells.
class ExpandSelectionByBlockIntent extends SwayzeIntent {
  final AxisDirection direction;

  const ExpandSelectionByBlockIntent(this.direction);
}

/// A [SwayzeIntent] to fill a range based on cells from the source range.
///
/// This differs from [FillIntoUnknownIntent] as we know the target range.
///
/// See also:
/// - [TableBodyGestureDetector] that triggers this intent
class FillIntoTargetIntent extends SwayzeIntent {
  final Range2D source;

  final Range2D target;

  const FillIntoTargetIntent({
    required this.source,
    required this.target,
  });
}

/// A [SwayzeIntent] to fill unknown cells from a given range.
///
/// This differs from [FillIntoTargetIntent] as we know don't know the target
/// range.
///
/// See also:
/// - [TableBodyGestureDetector] that triggers this intent
class FillIntoUnknownIntent extends SwayzeIntent {
  final Range2D source;

  const FillIntoUnknownIntent({
    required this.source,
  });
}

/// A [SwayzeIntent] to start a selection in the table body.
///
/// See also:
/// - [TableBodyGestureDetector] that triggers this intent
class TableBodySelectionStartIntent extends SwayzeIntent {
  final IntVector2 cellCoordinate;

  /// `true` if this is a selection to be used to fill the cells.
  final bool fill;

  const TableBodySelectionStartIntent(
    this.cellCoordinate, {
    this.fill = false,
  });
}

/// A [SwayzeIntent] to start a selection in the table headers.
///
/// See also:
/// - [HeaderGestureDetector] that triggers this intent
class HeaderSelectionStartIntent extends SwayzeIntent {
  final int header;
  final Axis axis;

  const HeaderSelectionStartIntent({
    required this.header,
    required this.axis,
  });
}

/// A [SwayzeIntent] to update a selection in the table body.
///
/// See also:
/// - [TableBodyGestureDetector] that triggers this intent
class TableBodySelectionUpdateIntent extends SwayzeIntent {
  final IntVector2 cellCoordinate;

  const TableBodySelectionUpdateIntent(this.cellCoordinate);
}

/// A [SwayzeIntent] to end a selection in the table body.
///
/// See also:
/// - [TableBodyGestureDetector] that triggers this intent
class TableBodySelectionEndIntent extends SwayzeIntent {
  const TableBodySelectionEndIntent();
}

/// A [SwayzeIntent] to cancel a selection in the table body.
///
/// See also:
/// - [TableBodyGestureDetector] that triggers this intent
class TableBodySelectionCancelIntent extends SwayzeIntent {
  const TableBodySelectionCancelIntent();
}

/// A [SwayzeIntent] to update a selection in the headers.
///
/// See also:
/// - [HeaderGestureDetector] that triggers this intent
class HeaderSelectionUpdateIntent extends SwayzeIntent {
  final int header;
  final Axis axis;

  const HeaderSelectionUpdateIntent({
    required this.header,
    required this.axis,
  });
}
