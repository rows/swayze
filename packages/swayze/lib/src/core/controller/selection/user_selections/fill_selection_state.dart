import 'package:meta/meta.dart';
import 'package:swayze_math/swayze_math.dart';

import 'model.dart';

/// A immutable description of the disposition of the [FillSelectionModel], used
/// for the drag and fill operations.
///
/// It allows at most one selection at a time, if any.
///
/// This is the portion of selections on [SwayzeSelectionController] that are
/// created and changed by user gestures.
///
/// See also:
/// - [SwayzeSelectionController] which keeps this state in a [ValueListenable].
@immutable
class FillSelectionState {
  final FillSelectionModel? selection;

  const FillSelectionState._({
    required this.selection,
  });

  const FillSelectionState.empty() : this._(selection: null);

  /// Clears the current selection..
  FillSelectionState clear() => const FillSelectionState.empty();

  /// Adds a new selection, if none exists.
  FillSelectionState addIfNoneExists(
    FillSelectionModel newSelection,
  ) {
    if (selection != null) {
      return this;
    }

    return FillSelectionState._(
      selection: newSelection,
    );
  }

  /// Updates the selection, if one exists.
  FillSelectionState update({
    required IntVector2 anchor,
    required IntVector2 focus,
  }) {
    final currentSelection = selection;

    if (currentSelection == null) {
      return this;
    }

    return FillSelectionState._(
      selection: FillSelectionModel.fromSelectionModel(
        currentSelection,
        anchor: anchor,
        focus: focus,
      ),
    );
  }
}
