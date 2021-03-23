import 'package:flutter/widgets.dart';

@immutable
class TableFocusState {
  /// Keep track if the current table is focused.
  final bool hasFocus;

  /// Keep track if the current table is active, ie. if it is the last
  /// focused child in the given [FocusScope].
  ///
  /// [isActive] ensures that selections are displayed even if we
  /// move focus to the FormulaBar or a SidePanel.
  final bool isActive;

  const TableFocusState({
    required this.hasFocus,
    required this.isActive,
  });

  @override
  String toString() {
    return 'hasFocus: $hasFocus, isActive: $isActive';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableFocusState &&
          runtimeType == other.runtimeType &&
          hasFocus == other.hasFocus &&
          isActive == other.isActive;

  @override
  int get hashCode => hasFocus.hashCode ^ isActive.hashCode;
}
