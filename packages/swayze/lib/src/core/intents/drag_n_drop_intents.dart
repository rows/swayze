import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import 'swayze_intent.dart';

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
