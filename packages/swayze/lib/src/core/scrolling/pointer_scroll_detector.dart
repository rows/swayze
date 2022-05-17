import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sliver_two_axis_scroll.dart';

/// A [StatelessWidget] that wraps a [Listener] and intercepts
/// mousewheel/trackpad events and apply the scrolling deltas to both scroll
/// controllers keeping a non stuttering two axis scroll.
///
/// See also:
/// [SliverTwoAxisScroll] that contains this widget.
class PointerScrollDetector extends StatelessWidget {
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;

  final Widget child;

  const PointerScrollDetector({
    Key? key,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    required this.child,
  }) : super(key: key);

  /// Handle the [PointerScrollEvent] event from a [Listener].
  void handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    final horizontalPosition = horizontalScrollController.position;
    final verticalPosition = verticalScrollController.position;

    final horizontalDelta = _handlePointerSignalAxis(
      event,
      horizontalPosition,
      Axis.horizontal,
    );

    final verticalDelta = _handlePointerSignalAxis(
      event,
      verticalPosition,
      Axis.vertical,
    );

    if (verticalDelta != null || horizontalDelta != null) {
      GestureBinding.instance.pointerSignalResolver
          .register(event, applyScroll);
    }
  }

  /// Compute the delta to be scrolled given an scroll event and a scroll state
  /// in an axis.
  ///
  /// Returns null if should no scroll.
  double? _handlePointerSignalAxis(
    PointerScrollEvent event,
    ScrollPosition position,
    Axis axis,
  ) {
    final shouldAccept = position.pixels != 0.0 ||
        position.minScrollExtent != position.maxScrollExtent;

    if (!shouldAccept) {
      return null;
    }

    final delta = _pointerSignalEventDelta(event, axis);

    final targetScrollOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (targetScrollOffset == position.pixels) {
      return 0.0;
    }

    return delta;
  }

  /// Get a scroll of an [axis] in an [event].
  double _pointerSignalEventDelta(PointerScrollEvent event, Axis axis) {
    final keysPressed = RawKeyboard.instance.keysPressed;

    final containsShift = keysPressed.contains(LogicalKeyboardKey.shift) ||
        keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight);

    /// TODO(renancaraujo): windows doesnt automatically applies shift+scroll
    /// as horizontal scroll. This is a workaround and doesnt work if the app
    /// is not focused. To track: https://github.com/flutter/flutter/issues/75180
    if (Platform.isWindows && containsShift) {
      if (axis == Axis.vertical) {
        return 0.0;
      }
      return event.scrollDelta.dy;
    }

    if (axis == Axis.horizontal) {
      return event.scrollDelta.dx;
    } else {
      return event.scrollDelta.dy;
    }
  }

  /// If the callback on widget wins over [GestureBinding.pointerSignalResolver]
  ///
  /// Apply the given scroll to both scroll controllers.
  void applyScroll(PointerEvent event) {
    assert(event is PointerScrollEvent);

    event as PointerScrollEvent;

    final horizontalDelta = _pointerSignalEventDelta(
      event,
      Axis.horizontal,
    );
    final verticalDelta = _pointerSignalEventDelta(
      event,
      Axis.vertical,
    );

    if (horizontalDelta != 0.0) {
      horizontalScrollController.position.pointerScroll(horizontalDelta);
    }
    if (verticalDelta != 0.0) {
      verticalScrollController.position.pointerScroll(verticalDelta);
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerSignal: handlePointerSignal,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
}
