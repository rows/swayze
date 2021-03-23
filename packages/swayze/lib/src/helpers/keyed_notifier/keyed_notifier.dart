import 'package:flutter/widgets.dart';

/// A Class that collects listeners for changes in an internal value notifier.
///
/// Each listener listen for changes involving a specific key.
/// If that key is selected to, the listener is called with
/// `true`, if that value is selected from, the listener
/// is called with `false`
class KeyedNotifier<KeyType> {
  final Map<KeyType, ValueChanged<bool>> _listeners = {};

  KeyType? _subjectBefore;

  late final _valueNotifier = ValueNotifier<KeyType?>(null)
    ..addListener(_onValueChange);

  void _onValueChange() {
    final currentValue = _valueNotifier.value;

    if (_subjectBefore != null && _listeners[_subjectBefore] != null) {
      final exitListener = _listeners[_subjectBefore]!;
      exitListener(false);
    }

    if (currentValue != null && _listeners[currentValue] != null) {
      final enterListener = _listeners[currentValue]!;
      enterListener(true);
    }
  }

  KeyType? get value => _valueNotifier.value;

  /// Fire a listener for a specific key.
  /// If a key was selected before, fires the listener for that key with
  /// [KeyedNotifierUpdate.unselected].
  void setKey(KeyType? subject) {
    final currentValue = _valueNotifier.value;
    if (currentValue == subject) {
      return;
    }
    _subjectBefore = currentValue;
    _valueNotifier.value = subject;
  }

  /// Set a listener to be fired when a specific key is selected or unselected.
  void setListenerForKey(
    KeyType key,
    ValueChanged<bool> listener,
  ) {
    _listeners[key] = listener;
  }

  /// remove any listener for a specific key
  void clearListenerForKey(KeyType key) {
    _listeners.remove(key);
  }

  /// Free all resources used by this listener.
  /// After disposed, cannot be used.
  void dispose() {
    _listeners.clear();
    _subjectBefore = null;
    _valueNotifier.dispose();
  }
}
