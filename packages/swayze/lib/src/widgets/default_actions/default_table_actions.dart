import 'package:flutter/widgets.dart';

import '../../core/intents/intents.dart';
import '../../core/viewport_context/viewport_context_provider.dart';
import '../internal_scope.dart';
import 'drag_n_drop_actions.dart';
import 'inline_editor_actions.dart';
import 'selection_actions.dart';

/// An [Actions] widget that handles the default Swayze table behavior on the
/// current platform.
///
/// This default behavior can be overridden by placing an [Actions] widget
/// in the widget tree with mapping for the same intents.
///
/// Actions mapped here should be made overridable via [Action.overridable]
/// otherwise is not possible to override these actions outside swayze.
///
/// See also:
/// - [TableShortcuts] for an example of remapping keyboard keys to an
/// existing Swayze Table [Intent].
/// - [DefaultSwayzeAction] that superclasses the actions mapped here.
class DefaultActions extends StatefulWidget {
  final Widget child;

  const DefaultActions({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<DefaultActions> createState() => _DefaultActionsState();
}

class _DefaultActionsState extends State<DefaultActions> {
  late final internalScope = InternalScope.of(context);
  late final viewportContext = ViewportContextProvider.of(context);

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        OpenInlineEditorIntent: OpenInlineEditorAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        SelectTableIntent: SelectTableAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        MoveActiveCellIntent: MoveActiveCellAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        MoveActiveCellByBlockIntent: MoveActiveCellByBlockAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        ExpandSelectionIntent: ExpandSelectionAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        ExpandSelectionByBlockIntent: ExpandSelectionByBlockAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        TableBodySelectionStartIntent: CellSelectionStartAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        HeaderSelectionStartIntent: HeaderSelectionStartAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        TableBodySelectionUpdateIntent: CellSelectionUpdateAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        TableBodySelectionEndIntent: CellSelectionEndAction(
          internalScope,
          viewportContext,
        ),
        TableBodySelectionCancelIntent: CellSelectionCancelAction(
          internalScope,
          viewportContext,
        ),
        HeaderSelectionUpdateIntent: HeaderSelectionUpdateAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        HeaderDragStartIntent: HeaderDragStartAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        HeaderDragEndIntent: HeaderDragEndAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        HeaderDragUpdateIntent: HeaderDragUpdateAction(
          internalScope,
          viewportContext,
        ).overridable(context),
        HeaderDragCancelIntent: HeaderDragCancelAction(
          internalScope,
          viewportContext,
        ).overridable(context),
      },
      child: widget.child,
    );
  }
}
