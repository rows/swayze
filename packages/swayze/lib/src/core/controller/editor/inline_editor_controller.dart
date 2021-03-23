import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../widgets/inline_editor/inline_editor.dart';
import '../../../widgets/inline_editor/overlay.dart';
import '../controller.dart';

/// A [ControllerBase] that keeps track of the state of the inline editor,
///
/// - [SwayzeScrollController]
/// - [InlineEditorPlacer] internal widget that answers to
/// [SwayzeInlineEditorController] and adds an [OverlayEntry] when the editor is
/// open.
/// - [generateOverlayEntryForInlineEditor] that creates the [OverlayEntry]
/// that will contain the widget built here.
/// - [InlineEditorBuilder] the callback passed by to swayze to define what
/// should be rendered in the inline editor position.
class SwayzeInlineEditorController
    extends ValueNotifier<SwayzeInlineEditorState?> {
  SwayzeInlineEditorController() : super(null);

  IntVector2? get coordinate => value?.coordinate;

  String? get initialText => value?.initialText;

  bool get isOpen => coordinate != null;

  void open({
    required IntVector2 onCoordinate,
    String? withInitialText,
  }) {
    value = SwayzeInlineEditorState._(onCoordinate, withInitialText);
  }

  @protected
  @override
  SwayzeInlineEditorState? get value => super.value;

  @protected
  @override
  set value(SwayzeInlineEditorState? newValue) {
    super.value = newValue;
  }

  void close() {
    value = null;
  }
}

@immutable
class SwayzeInlineEditorState {
  final IntVector2 coordinate;
  final String? initialText;

  const SwayzeInlineEditorState._(this.coordinate, this.initialText);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeInlineEditorState &&
          runtimeType == other.runtimeType &&
          coordinate == other.coordinate &&
          initialText == other.initialText;

  @override
  int get hashCode => coordinate.hashCode ^ initialText.hashCode;
}
