import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../core/internal_state/table_focus/table_focus_provider.dart';
import '../../../core/viewport_context/viewport_context_provider.dart';
import '../../../helpers/keyed_notifier/keyed_notifier.dart';

const _kMouseHoverDebounceMilliseconds = 35;

class MouseHoverTableBody extends StatefulWidget {
  final Widget child;

  const MouseHoverTableBody({
    Key? key,
    required this.child,
  }) : super(key: key);

  static KeyedNotifier<IntVector2> of(BuildContext context) {
    return context
        .findAncestorWidgetOfExactType<_TableBodyMouseHoverProvider>()!
        .hoverNotifier;
  }

  @override
  _MouseHoverTableBodyState createState() => _MouseHoverTableBodyState();
}

class _MouseHoverTableBodyState extends State<MouseHoverTableBody> {
  final mouseHoverNotifier = KeyedNotifier<IntVector2>();
  late final viewportContext = ViewportContextProvider.of(context);

  Timer? _debounce;

  MouseCursor _cursor = MouseCursor.defer;
  MouseCursor get cursor => _cursor;
  set cursor(MouseCursor value) {
    if (mounted && _cursor != value) {
      setState(() => _cursor = value);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _resetCursor() => cursor = MouseCursor.defer;

  void onPointerHover(PointerHoverEvent event) {
    final localPosition = event.localPosition;

    if (_debounce?.isActive ?? false) {
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: _kMouseHoverDebounceMilliseconds),
      () => updateMouseHoverNotifier(localPosition),
    );
  }

  void updateMouseHoverNotifier(Offset localPosition) {
    final hoverResult = viewportContext.evaluateHover(localPosition);

    mouseHoverNotifier.setKey(hoverResult.cell);

    hoverResult.canFillCell && TableFocus.of(context).value.isActive
        ? cursor = SystemMouseCursors.precise
        : _resetCursor();
  }

  void onPointerExit(PointerExitEvent event) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    mouseHoverNotifier.setKey(null);
    _resetCursor();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onHover: onPointerHover,
        onExit: onPointerExit,
        opaque: false,
        cursor: _cursor,
        child: _TableBodyMouseHoverProvider(
          hoverNotifier: mouseHoverNotifier,
          child: widget.child,
        ),
      );
}

class _TableBodyMouseHoverProvider extends InheritedWidget {
  final KeyedNotifier<IntVector2> hoverNotifier;

  const _TableBodyMouseHoverProvider({
    Key? key,
    required this.hoverNotifier,
    required Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  bool updateShouldNotify(_TableBodyMouseHoverProvider oldWidget) {
    return false;
  }
}
