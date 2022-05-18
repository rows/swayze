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

/// A [SwayzeIntent] to start a selection in the table body.
///
/// See also:
/// - [TableBodyGestureDetector] that triggers this intent
class TableBodySelectionStartIntent extends SwayzeIntent {
  final IntVector2 cellCoordinate;

  const TableBodySelectionStartIntent(this.cellCoordinate);
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

// TODO: [victor] doc
class HeaderDragStartIntent extends SwayzeIntent {
  final Range headers;
  final Axis axis;
  final Offset draggingPosition;

  const HeaderDragStartIntent({
    required this.headers,
    required this.axis,
    required this.draggingPosition,
  });
}

// TODO: [victor] doc
class HeaderDragUpdateIntent extends SwayzeIntent {
  final int header;
  final Axis axis;
  final Offset draggingPosition;

  const HeaderDragUpdateIntent({
    required this.header,
    required this.axis,
    required this.draggingPosition,
  });
}

// TODO: [victor] doc
class HeaderDragEndIntent extends SwayzeIntent {
  final int header;
  final Axis axis;

  const HeaderDragEndIntent({
    required this.header,
    required this.axis,
  });
}

class HeaderDragCancelIntent extends SwayzeIntent {
  final Axis axis;

  const HeaderDragCancelIntent(this.axis);
}
