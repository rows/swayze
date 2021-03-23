import 'package:flutter/widgets.dart';

import 'inline_editor.dart';

/// A [ValueNotifier] that manages [RectPositionsState].
///
/// Keeps track in the representations of the physical space occupied by the
/// table and the editing cell on [InlineEditorPlacer].
class RectPositionsNotifier extends ValueNotifier<RectPositionsState> {
  RectPositionsNotifier({
    required Rect tableRect,
    required Rect cellRect,
  }) : super(
          RectPositionsState(
            tableRect: tableRect,
            cellRect: cellRect,
          ),
        );

  Rect get cellRect => value.cellRect;

  Rect get tableRect => value.tableRect;

  void setRect({
    required Rect tableRect,
    required Rect cellRect,
  }) {
    value = RectPositionsState(
      tableRect: tableRect,
      cellRect: cellRect,
    );
  }

  @protected
  @override
  set value(RectPositionsState newValue) {
    super.value = newValue;
  }

  @protected
  @override
  RectPositionsState get value => super.value;
}

/// The content of [RectPositionsNotifier] that includes the representation of
/// the physical position occupied by the table as well as the editing cell in
/// the [InlineEditorPlacer].
@immutable
class RectPositionsState {
  final Rect tableRect;
  final Rect cellRect;

  const RectPositionsState({required this.tableRect, required this.cellRect});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RectPositionsState &&
          runtimeType == other.runtimeType &&
          tableRect == other.tableRect &&
          cellRect == other.cellRect;

  @override
  int get hashCode => tableRect.hashCode ^ cellRect.hashCode;
}
