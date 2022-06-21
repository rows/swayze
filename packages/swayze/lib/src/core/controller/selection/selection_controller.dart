import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../controller.dart';
import 'user_selections/fill_selection_state.dart';

export 'model/selection.dart';
export 'model/selection_style.dart';
export 'user_selections/model.dart';
export 'user_selections/user_selection_state.dart';

typedef SwayzeSelectionChangerCallback<T> = T Function(T previousState);

/// A [ControllerBase] that keeps track of the active selections in the table.
///
/// Selections are divided in two main groups that are defined by its
/// precedence.
///
/// ## User selections
///
/// User selections are the selections in which the control is primarily made by
/// swayze. These selections are the result of some user gestures in the grid.
/// It is guaranteed to exist at least one [UserSelectionModel] in the state
/// at any given time.
/// These selections maintained by am internal [ValueNotifier] of
/// [UserSelectionState], which can be accessed via [userSelectionState] and
/// updated via [updateUserSelections].
///
/// ## Data selections
///
/// The selections that are created and maintained outside swayze.
/// May be result of some computation of datas and specific features.
/// To implement these custom selections, override
/// [dataSelectionsValueListenable].
///
/// See also:
/// - [SwayzeScrollController]
class SwayzeSelectionController extends Listenable implements ControllerBase {
  /// Internal [ValueNotifier] to control [UserSelectionState]
  @protected
  final userSelections = _UserSelectionsValueNotifier();

  /// Internal [ValueNotifier] that controls the [FillSelectionState].
  @protected
  final fillSelection = _FillSelectionsValueNotifier();

  Listenable get userSelectionsListenable => userSelections;

  Listenable get fillSelectionListenable => fillSelection;

  SwayzeSelectionController();

  /// The [ValueListenable] that is  supposed to maintain a iterable of
  /// [Selection]s that are result of some externally imposed rules to render
  /// special selections. It is ideal to maintain selections that are result of
  /// different data rather than user gestures.
  ///
  /// Override this to implement a custom data selection controller.
  ///
  /// By default [dataSelectionsValueListenable] is a dummy value listenable
  /// that never notify listeners.
  @protected
  ValueListenable<Iterable<Selection>> get dataSelectionsValueListenable {
    return _DummyDataSelectionsValueNotifier();
  }

  // this controller as a listenable, notify listeners from changes in user
  // selections and data selections.
  late final _mergeListenable = Listenable.merge([
    userSelections,
    fillSelection,
    dataSelectionsValueListenable,
  ]);

  /// Recover the current [UserSelectionState]
  UserSelectionState get userSelectionState => userSelections.value;

  /// Recover the current [FillSelectionState]
  FillSelectionState get fillSelectionState => fillSelection.value;

  /// Recover the current list of data selections.
  Iterable<Selection> get dataSelections => dataSelectionsValueListenable.value;

  /// Update the current [userSelectionState]. The callback [stateUpdate]
  /// receives the actual version of the state and should return the updated
  /// version.
  /// If the returned state is the same as before, no update is triggered.
  void updateUserSelections(
    SwayzeSelectionChangerCallback<UserSelectionState> stateUpdate,
  ) {
    userSelections.value = stateUpdate(userSelections.value);
  }

  /// Update the current [fillSelectionState]. The callback [stateUpdate]
  /// receives the actual version of the state and should return the updated
  /// version.
  /// If the returned state is the same as before, no update is triggered.
  void updateFillSelections(
    SwayzeSelectionChangerCallback<FillSelectionState> stateUpdate,
  ) =>
      fillSelection.value = stateUpdate(fillSelection.value);

  /// Check if the index [headerIndex] is covered by any header selection.
  bool isHeaderSelected(int headerIndex, Axis axis) =>
      userSelectionState.selections.any(
        (selection) =>
            selection is HeaderUserSelectionModel &&
            selection.axis == axis &&
            selection.contains(headerIndex),
      );

  @override
  void addListener(VoidCallback listener) {
    _mergeListenable.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _mergeListenable.removeListener(listener);
  }

  @override
  void dispose() {
    fillSelection.dispose();
    userSelections.dispose();
  }
}

/// The internal [ValueNotifier] that keeps track of changes on
/// [UserSelectionState].
class _UserSelectionsValueNotifier extends ValueNotifier<UserSelectionState> {
  _UserSelectionsValueNotifier() : super(UserSelectionState.initial);

  @override
  @protected
  set value(UserSelectionState newValue) {
    super.value = newValue;
  }

  @override
  @protected
  UserSelectionState get value => super.value;
}

/// The internal [ValueNotifier] that keeps track of changes on
/// [FillSelectionState].
class _FillSelectionsValueNotifier extends ValueNotifier<FillSelectionState> {
  _FillSelectionsValueNotifier()
      : super(
          const FillSelectionState.empty(),
        );

  @override
  @protected
  set value(FillSelectionState newValue) {
    super.value = newValue;
  }

  @override
  @protected
  FillSelectionState get value => super.value;
}

/// Dummy [ValueListenable] that act as default to
/// [SwayzeSelectionController.dataSelectionsValueListenable]
class _DummyDataSelectionsValueNotifier
    implements ValueListenable<Iterable<Selection>> {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  late final Iterable<Selection> value = <Selection>[];
}
