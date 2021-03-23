import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../intents.dart';
import '../internal_scope.dart';

/// A [Shortcuts] widget with the shortcuts used for the default Swayze
/// interactions behavior.
///
/// This default behavior can be overridden by placing a [Shortcuts] widget
/// lower in the widget tree than this. See [TableActions] for an example of
/// remapping a Swayze Table [Intent] to  a custom [Action].
class TableShortcuts extends StatefulWidget {
  final Widget child;

  const TableShortcuts({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _TableShortcutsState createState() => _TableShortcutsState();
}

class _TableShortcutsState extends State<TableShortcuts> {
  late final internalScope = InternalScope.of(context);

  late final manager = _CustomShortcutManager({
    const AnyCharacterActivator(): (event) {
      return OpenInlineEditorIntent(
        initialText: event.character,
      );
    }
  });

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      debugLabel: '<Table Shortcuts>',
      shortcuts: _staticShortcuts,
      manager: manager,
      child: widget.child,
    );
  }
}

Map<ShortcutActivator, Intent> get _staticShortcuts {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return _kMacShortcuts;
    default:
      return _kDefaultShortcuts;
  }
}

const _kDefaultShortcuts = <ShortcutActivator, Intent>{
  // Open cell editor
  SingleActivator(LogicalKeyboardKey.enter): OpenInlineEditorIntent(),

  // Select table
  SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectTableIntent(),

  // Move active cell
  SingleActivator(LogicalKeyboardKey.arrowDown):
      MoveActiveCellIntent(AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp):
      MoveActiveCellIntent(AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft):
      MoveActiveCellIntent(AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight):
      MoveActiveCellIntent(AxisDirection.right),
  SingleActivator(LogicalKeyboardKey.tab):
      MoveActiveCellIntent(AxisDirection.right),
  SingleActivator(LogicalKeyboardKey.tab, shift: true):
      MoveActiveCellIntent(AxisDirection.left),

  // Move active cell by block
  SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
      MoveActiveCellByBlockIntent(AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
      MoveActiveCellByBlockIntent(AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
      MoveActiveCellByBlockIntent(AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
      MoveActiveCellByBlockIntent(AxisDirection.right),

  // Expand selection
  SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
      ExpandSelectionIntent(AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
      ExpandSelectionIntent(AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
      ExpandSelectionIntent(AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
      ExpandSelectionIntent(AxisDirection.right),

  // Expand block selection
  SingleActivator(
    LogicalKeyboardKey.arrowDown,
    shift: true,
    control: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.down),
  SingleActivator(
    LogicalKeyboardKey.arrowUp,
    shift: true,
    control: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.up),
  SingleActivator(
    LogicalKeyboardKey.arrowLeft,
    shift: true,
    control: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.left),
  SingleActivator(
    LogicalKeyboardKey.arrowRight,
    shift: true,
    control: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.right),
};

const _kMacShortcuts = <ShortcutActivator, Intent>{
  // Open cell editor
  SingleActivator(LogicalKeyboardKey.enter): OpenInlineEditorIntent(),

  // Select table
  SingleActivator(LogicalKeyboardKey.keyA, meta: true): SelectTableIntent(),

  // Move active cell
  SingleActivator(LogicalKeyboardKey.arrowDown):
      MoveActiveCellIntent(AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp):
      MoveActiveCellIntent(AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft):
      MoveActiveCellIntent(AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight):
      MoveActiveCellIntent(AxisDirection.right),
  SingleActivator(LogicalKeyboardKey.tab):
      MoveActiveCellIntent(AxisDirection.right),
  SingleActivator(LogicalKeyboardKey.tab, shift: true):
      MoveActiveCellIntent(AxisDirection.left),

  // Move active cell by block
  SingleActivator(LogicalKeyboardKey.arrowDown, meta: true):
      MoveActiveCellByBlockIntent(AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp, meta: true):
      MoveActiveCellByBlockIntent(AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true):
      MoveActiveCellByBlockIntent(AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight, meta: true):
      MoveActiveCellByBlockIntent(AxisDirection.right),

  // Expand selection
  SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
      ExpandSelectionIntent(AxisDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
      ExpandSelectionIntent(AxisDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
      ExpandSelectionIntent(AxisDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
      ExpandSelectionIntent(AxisDirection.right),

  // Expand block selection
  SingleActivator(
    LogicalKeyboardKey.arrowDown,
    shift: true,
    meta: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.down),
  SingleActivator(
    LogicalKeyboardKey.arrowUp,
    shift: true,
    meta: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.up),
  SingleActivator(
    LogicalKeyboardKey.arrowLeft,
    shift: true,
    meta: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.left),
  SingleActivator(
    LogicalKeyboardKey.arrowRight,
    shift: true,
    meta: true,
  ): ExpandSelectionByBlockIntent(AxisDirection.right),
};

class _CustomShortcutManager extends ShortcutManager {
  final Map<ShortcutActivator, Intent Function(RawKeyEvent)> customShortcuts;

  _CustomShortcutManager(this.customShortcuts);

  @override
  KeyEventResult handleKeypress(BuildContext context, RawKeyEvent event) {
    final primaryContext = primaryFocus?.context;

    if (primaryContext == null) {
      return super.handleKeypress(context, event);
    }

    for (final entry in customShortcuts.entries) {
      if (entry.key.accepts(event, RawKeyboard.instance)) {
        final matchedIntent = entry.value(event);
        final action = Actions.maybeFind<Intent>(
          primaryContext,
          intent: matchedIntent,
        );

        if (action != null && action.isEnabled(matchedIntent)) {
          Actions.of(primaryContext)
              .invokeAction(action, matchedIntent, primaryContext);
          return action.consumesKey(matchedIntent)
              ? KeyEventResult.handled
              : KeyEventResult.skipRemainingHandlers;
        }
      }
    }

    return super.handleKeypress(context, event);
  }
}

/// A [ShortcutActivator] that triggers intents when any combination of keys
/// that outputs a printable character.
class AnyCharacterActivator extends ShortcutActivator {
  const AnyCharacterActivator();

  @override
  bool accepts(RawKeyEvent e, RawKeyboard state) {
    final event = e;
    if (event is! RawKeyDownEvent) {
      return false;
    }

    final character = event.character;
    // if it has a character associated
    if (character == null || character.isEmpty) {
      return false;
    }

    final keysPressed = LogicalKeyboardKey.collapseSynonyms(
      state.keysPressed,
    );

    if (keysPressed.contains(LogicalKeyboardKey.delete) ||
        keysPressed.contains(LogicalKeyboardKey.backspace)) {
      return false;
    }

    // if it is pressing an arrow
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      return false;
    }

    // if its pressing a modifier key
    if (keysPressed.contains(LogicalKeyboardKey.control) ||
        keysPressed.contains(LogicalKeyboardKey.meta)) {
      return false;
    }

    final firstRune = character.runes.firstOrNull;
    return firstRune != null && firstRune > 0x20;
  }

  @override
  String debugDescribeKeys() {
    return '<any keyset that results in a character>';
  }

  @override
  Iterable<LogicalKeyboardKey>? get triggers => null;
}
