import 'package:swayze_math/swayze_math.dart';

import 'intents.dart';

/// A [SwayzeIntent] triggered when a checkbox cell is tapped.
class OpenInlineEditorIntent extends SwayzeIntent {
  /// Coordinates of the checkboxes' cell.
  final IntVector2? cellPosition;

  final String? initialText;

  const OpenInlineEditorIntent({
    this.cellPosition,
    this.initialText,
  });
}
