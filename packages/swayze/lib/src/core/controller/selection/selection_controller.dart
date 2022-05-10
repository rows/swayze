import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../controller.dart';

export 'model/selection.dart';
export 'model/selection_style.dart';
export 'user_selections/model.dart';
export 'user_selections/user_selection_state.dart';

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

  Listenable get userSelectionsListenable => userSelections;

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
    dataSelectionsValueListenable,
  ]);

  /// Recover the current [UserSelectionState]
  UserSelectionState get userSelectionState => userSelections.value;

  /// Recover the current list of data selections.
  Iterable<Selection> get dataSelections => dataSelectionsValueListenable.value;

  /// Update the current [userSelectionState]. The callback [stateUpdate]
  /// receives the actual version of the state and should return the updated
  /// version.
  /// If the returned state is the same as before, no update is triggered.
  void updateUserSelections(
    UserSelectionState Function(UserSelectionState previousState) stateUpdate,
  ) {
    userSelections.value = stateUpdate(userSelections.value);
  }

  /// Check if the index [headerIndex] is covered by any header selection.
  bool isHeaderSelected(int headerIndex, Axis axis) {
    final selections =
        userSelectionState.selections.whereType<HeaderUserSelectionModel>();

    for (final headerSelection in selections) {
      if (headerSelection.axis == axis &&
          headerSelection.contains(headerIndex)) {
        return true;
      }
    }
    return false;
  }

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

/// Dummy [ValueListenable] thata ct as default to
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
