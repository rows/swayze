import 'package:flutter/widgets.dart';

import '../../core/intents/inline_editor_intents.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../internal_scope.dart';
import 'default_swayze_action.dart';

/// Given the [OpenInlineEditorIntent]'s cellPosition and initialText, call
/// open on the current scope's inlineEditor.
class OpenInlineEditorAction
    extends DefaultSwayzeAction<OpenInlineEditorIntent> {
  OpenInlineEditorAction(
    InternalScope internalScope,
    ViewportContext viewportContext,
  ) : super(internalScope, viewportContext);

  @override
  void invokeAction(OpenInlineEditorIntent intent, BuildContext context) {
    final inlineEditor = internalScope.controller.inlineEditor;
    final selectionController = internalScope.controller.selection;
    final position = intent.cellPosition ??
        selectionController.userSelectionState.activeCellCoordinate;

    inlineEditor.open(
      onCoordinate: position,
      withInitialText: intent.initialText,
    );
  }
}
