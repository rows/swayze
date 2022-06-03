import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../internal_scope.dart';
import 'resize_header_details_notifier.dart';
import 'resize_header_line.dart';

/// An overlay manager that creates a backdrop overlay entry to disable scroll
/// when resizing an header and another overlay entry for the resize line.
class ResizeLineOverlayManager {
  final InternalScope internalScope;
  final ValueNotifier<ResizeHeaderDetails?> resizeNotifier;

  OverlayEntry? line;

  ResizeLineOverlayManager({
    required this.internalScope,
    required this.resizeNotifier,
  });

  void insertResizeLine(BuildContext context) {
    final overlayState = Overlay.of(context);

    if (overlayState == null) {
      return;
    }

    final box = context.findRenderObject()! as RenderBox;
    final target = box.localToGlobal(
      Offset.zero,
      ancestor: overlayState.context.findRenderObject(),
    );

    line ??= OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<ResizeHeaderDetails?>(
          valueListenable: resizeNotifier,
          builder: (context, resizeDetails, child) {
            if (resizeDetails == null) {
              return const SizedBox.shrink();
            }

            final axis = resizeDetails.axis;

            double left;
            double top;

            final offset = resizeDetails.offset!;
            final minOffset = resizeDetails.minOffset!;

            if (axis == Axis.horizontal) {
              left = max(offset, minOffset) + target.dx;
              top = target.dy;
            } else {
              left = target.dx;
              top = max(offset, minOffset) + target.dy;
            }

            return Positioned(
              left: left,
              top: top,
              width: box.size.width,
              height: box.size.height,
              child: child!,
            );
          },
          child: ResizeHeaderLine(
            style: internalScope.style,
            axis: resizeNotifier.value!.axis,
          ),
        );
      },
    );

    _insertBackdrop(context);

    overlayState.insert(line!);
  }

  /// Pushes a new route to disable keyboard interaction when resizing.
  void _insertBackdrop(BuildContext context) {
    Navigator.of(context).push<void>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: ColoredBox(
            color: Color(0x00000000),
          ),
        ),
      ),
    );
  }

  void _removeBackdrop(BuildContext context) {
    Navigator.of(context).pop();
  }

  void removeResizeLine(BuildContext context) {
    _removeBackdrop(context);

    line?.remove();
    line = null;
  }
}
