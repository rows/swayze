import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:swayze_math/swayze_math.dart';

import 'model.dart';

/// A immutable description of the disposition of [UserSelectionModel]s
/// in a given moment.
///
/// [selections] stores the currently active user selections.
///
/// This is the portion of selections on [SwayzeSelectionController] that are
/// created and changed by user gestures. It is guaranteed to have at least one
/// user selection active at any given moment.
///
/// See also:
/// - [SwayzeSelectionController] which keeps this state in a [ValueListenable].
@immutable
class UserSelectionState {
  /// A [UserSelectionState] to be applied to a table as soon as it renders for
  /// the first time.
  static UserSelectionState get initial => UserSelectionState._(
        BuiltList.from(
          <UserSelectionModel>[
            CellUserSelectionModel.fromAnchorFocus(
              anchor: const IntVector2.symmetric(0),
              focus: const IntVector2.symmetric(0),
            ),
          ],
        ),
      );

  /// The currently active selections.
  final BuiltList<UserSelectionModel> selections;

  /// The selection that contains the [activeCellCoordinate].
  ///
  /// It should be the selection that will be reseated on keyboard navigation.
  UserSelectionModel get primarySelection =>
      selections.elementAt(_primaryIndex);

  /// The index of the [primarySelection].
  final int _primaryIndex;

  Iterable<UserSelectionModel> get secondarySelections sync* {
    var index = 0;
    for (final selection in selections) {
      if (index == _primaryIndex) {
        continue;
      }
      yield selection;
      index++;
    }
  }

  /// The cell that represents the origin of the current selection state.
  ///
  /// It is the primary subject of the keyboard navigation.
  IntVector2 get activeCellCoordinate => primarySelection.anchorCoordinate;

  /// This is private because the state should be manipulated internally by
  /// [SelectionController] and we shall never have a condition where
  /// there is no selections.
  ///
  /// If [primaryIndex] is omitted, the last element on [selections]
  /// will be considered the [primarySelection].
  const UserSelectionState._(this.selections)
      : _primaryIndex = selections.length - 1;

  /// Reset user selections into it's initial value.
  UserSelectionState reset() {
    return initial;
  }

  /// Add a new selection to the end of [selections].
  UserSelectionState addSelection(
    UserSelectionModel newSelection,
  ) {
    if (selections.any((selection) => selection == newSelection)) {
      return this;
    }

    final newSelections =
        selections.rebuild((builder) => builder.add(newSelection));

    return UserSelectionState._(newSelections);
  }

  /// Reset all selections to a single [CellUserSelectionModel] created from
  /// [anchor] and [focus].
  ///
  /// The resulting lone selection copies everything from the [primarySelection]
  /// besides [anchor] and [focus].
  UserSelectionState resetSelectionsToACellSelection({
    required IntVector2 anchor,
    required IntVector2 focus,
  }) {
    final newList = BuiltList<UserSelectionModel>.from(
      <UserSelectionModel>[
        CellUserSelectionModel.fromSelectionModel(
          primarySelection,
          anchor: anchor,
          focus: focus,
        ),
      ],
    );
    return UserSelectionState._(newList);
  }

  /// Reset all selections to a single [HeaderUserSelectionModel] created from
  /// [anchor], [focus] and [axis].
  ///
  /// The resulting lone selection copies everything from the [primarySelection]
  /// besides [anchor], [focus] and [axis].
  UserSelectionState resetSelectionsToHeaderSelection({
    required Axis axis,
    required int anchor,
    required int focus,
  }) {
    final newList = BuiltList<UserSelectionModel>.from(
      <UserSelectionModel>[
        HeaderUserSelectionModel.fromSelectionModel(
          primarySelection,
          anchor: anchor,
          focus: focus,
          axis: axis,
        ),
      ],
    );
    return UserSelectionState._(newList);
  }

  /// Transform the last selection on [selections] into a
  /// [CellUserSelectionModel] with [anchor] and [focus].
  ///
  /// [anchor] defaults to the last selections
  /// [UserSelectionModel.anchorCoordinate].
  UserSelectionState updateLastSelectionToCellSelection({
    IntVector2? anchor,
    required IntVector2 focus,
  }) {
    final lastSelection = selections.last;
    final effectiveAnchor = anchor ?? lastSelection.anchorCoordinate;

    final builder = selections.toBuilder();
    builder
      ..take(selections.length - 1)
      ..add(
        CellUserSelectionModel.fromSelectionModel(
          lastSelection,
          anchor: effectiveAnchor,
          focus: focus,
        ),
      );
    return UserSelectionState._(builder.build());
  }

  /// Transform the last selection on [selections] into a
  /// [HeaderUserSelectionModel] with [anchor], [focus] and [axis].
  ///
  /// [anchor] defaults to the last selections
  /// [UserSelectionModel.anchorCoordinate].
  UserSelectionState updateLastSelectionToHeaderSelection({
    int? anchor,
    required int focus,
    required Axis axis,
  }) {
    final lastSelection = selections.last;
    final effectiveAnchor =
        anchor ?? _vectorValueFromAxis(lastSelection.anchorCoordinate, axis);

    final builder = selections.toBuilder();

    builder
      ..take(selections.length - 1)
      ..add(
        HeaderUserSelectionModel.fromSelectionModel(
          lastSelection,
          axis: axis,
          anchor: effectiveAnchor,
          focus: focus,
        ),
      );
    return UserSelectionState._(builder.build());
  }

  /// Converts the last [selections]'s to a new [TableUserSelectionModel]
  UserSelectionState resetSelectionsToTableSelection() {
    final newList = BuiltList<UserSelectionModel>.from(
      <UserSelectionModel>[
        TableUserSelectionModel.fromSelectionModel(
          primarySelection,
        ),
      ],
    );

    return UserSelectionState._(newList);
  }

  /// Expands last selection in a given [AxisDirection].
  ///
  /// [TableUserSelectionModel]s are not expandable, [HeaderUserSelectionModel]
  /// are expandable only on the cross axis and [CellUserSelectionModel]
  /// is expandable in all directions.
  ///
  /// See also:
  /// * [TableShortcuts] and [TableActions] where the shortcuts are mapped
  /// into actions that allow the user to expand the last selection
  UserSelectionState expandLastSelection(
    AxisDirection direction, {
    required IntVector2 Function(IntVector2 coordinate) getNextCoordinate,
  }) {
    if (primarySelection is TableUserSelectionModel) {
      return this;
    }

    if (primarySelection is HeaderUserSelectionModel) {
      final selection = primarySelection as HeaderUserSelectionModel;
      if (selection.axis != axisDirectionToAxis(direction)) {
        return this;
      }

      final newFocus = getNextCoordinate(selection.focusCoordinate);

      return updateLastSelectionToHeaderSelection(
        focus: selection.axis == Axis.horizontal ? newFocus.dx : newFocus.dy,
        axis: selection.axis,
      );
    }

    final selection = primarySelection as CellUserSelectionModel;
    final newFocus = getNextCoordinate(selection.focus);
    return updateLastSelectionToCellSelection(
      focus: newFocus,
      anchor: selection.anchor,
    );
  }

  /// Expands last selection in a given [AxisDirection] by a block of cells.
  ///
  /// [TableUserSelectionModel]s are not expandable, [HeaderUserSelectionModel]
  /// are expandable only on the cross axis and [CellUserSelectionModel] is
  /// expandable in all directions.
  ///
  /// See also:
  /// * [TableShortcuts] and [TableActions] where the shortcuts are mapped
  /// into actions that allow the user to expand the last selection
  UserSelectionState expandLastSelectionByBlock(
    AxisDirection direction, {
    required IntVector2 Function(IntVector2 coordinate)
        getNextCoordinateInCellsBlock,
    required int limit,
  }) {
    if (primarySelection is TableUserSelectionModel) {
      return this;
    }

    if (primarySelection is HeaderUserSelectionModel) {
      final selection = primarySelection as HeaderUserSelectionModel;
      if (selection.axis != axisDirectionToAxis(direction)) {
        return this;
      }

      final focus =
          direction == AxisDirection.up || direction == AxisDirection.left
              ? 0
              : limit;
      return updateLastSelectionToHeaderSelection(
        focus: focus,
        axis: selection.axis,
      );
    }

    final selection = primarySelection as CellUserSelectionModel;
    final newFocus = getNextCoordinateInCellsBlock(selection.focus);

    return updateLastSelectionToCellSelection(
      focus: newFocus,
      anchor: selection.anchor,
    );
  }

  /// Converts the [primarySelection]'s originCell into a
  /// [CellUserSelectionModel] and moves it in a given [AxisDirection].
  ///
  /// The only constraints applied to the new coordinate are that the new
  /// coordinates must be positive.
  ///
  /// See also:
  /// * [TableShortcuts] and [TableActions] where the shortcuts are mapped
  /// into actions that allow the user to expand the last selection
  UserSelectionState moveActiveCell(
    IntVector2 Function(IntVector2 coordinate) getNextCoordinate,
  ) {
    final newAnchor = getNextCoordinate(
      primarySelection.anchorCoordinate,
    );

    return resetSelectionsToACellSelection(
      anchor: newAnchor,
      focus: newAnchor,
    );
  }

  /// Converts the [primarySelection]'s originCell into a
  /// [CellUserSelectionModel] and moves it in a given [AxisDirection] by a
  /// block of cells.
  ///
  /// The only constraints applied to the new coordinate are that the new
  /// coordinates must be positive.
  ///
  /// See also:
  /// * [TableShortcuts] and [TableActions] where the shortcuts are mapped
  /// into actions that allow the user to expand the last selection
  UserSelectionState moveActiveCellByBlock(
    IntVector2 Function(IntVector2 coordinate) getNextCoordinateInCellsBlock,
  ) {
    final newAnchor = getNextCoordinateInCellsBlock(
      primarySelection.anchorCoordinate,
    );

    return resetSelectionsToACellSelection(
      anchor: newAnchor,
      focus: newAnchor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSelectionState &&
          runtimeType == other.runtimeType &&
          selections == other.selections &&
          _primaryIndex == other._primaryIndex;

  @override
  int get hashCode => selections.hashCode ^ _primaryIndex.hashCode;
}

/// Get the value of a [IntVector2] in an axis [axis].
int _vectorValueFromAxis(IntVector2 vector2, Axis axis) {
  return axis == Axis.horizontal ? vector2.dx : vector2.dy;
}
