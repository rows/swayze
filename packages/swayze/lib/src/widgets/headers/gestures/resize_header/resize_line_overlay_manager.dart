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

  OverlayEntry? backdrop;
  OverlayEntry? line;

  ResizeLineOverlayManager({
    required this.internalScope,
    required this.resizeNotifier,
  });

  void insertEntries(BuildContext context) {
    final rootOverlay = Overlay.of(context, rootOverlay: true);
    final overlayState = Overlay.of(context);

    if (overlayState == null || rootOverlay == null) {
      return;
    }

    final box = context.findRenderObject()! as RenderBox;
    final target = box.localToGlobal(
      Offset.zero,
      ancestor: overlayState.context.findRenderObject(),
    );

    backdrop ??= OverlayEntry(builder: (context) => const _Backdrop());

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

    rootOverlay.insert(backdrop!);
    overlayState.insert(line!);
  }

  void removeEntries() {
    backdrop?.remove();
    line?.remove();

    backdrop = null;
    line = null;
  }
}

class _Backdrop extends StatefulWidget {
  const _Backdrop({Key? key}) : super(key: key);

  @override
  State<_Backdrop> createState() => __BackdropState();
}

class __BackdropState extends State<_Backdrop> {
  late final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: const MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: ColoredBox(color: Color(0x00000000)),
      ),
    );
  }
}
