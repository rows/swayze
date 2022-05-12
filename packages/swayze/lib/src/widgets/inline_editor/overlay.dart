import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../core/controller/editor/inline_editor_controller.dart';
import '../../core/internal_state/table_focus/table_focus_provider.dart';
import '../internal_scope.dart';
import 'inline_editor.dart';
import 'rect_positions.dart';

/// A function that generates an [OverlayEntry] for [InlineEditorPlacer].
///
/// The content of the overlay is defined by [_InlineEditorOverlayContent] and
/// [InlineEditorBuilder] passed to swayze by the package user.
///
/// See also:
/// - [SwayzeInlineEditorController] that defines if the inline editor is open
/// or not.
/// - [InlineEditorBuilder] the callback passed by to swayze to define what
/// should be rendered in the inline editor position.
OverlayEntry generateOverlayEntryForInlineEditor({
  required IntVector2 cellCoordinate,
  required String? initialText,
  required BuildContext originContext,
  required RectPositionsNotifier rectNotifier,
  required InlineEditorBuilder inlineEditorBuilder,
  required VoidCallback requestClose,
}) {
  Widget buildOverlay(BuildContext context) {
    return ValueListenableBuilder<RectPositionsState>(
      valueListenable: rectNotifier,
      builder: (context, rectState, _) {
        return _InlineEditorOverlayContent(
          cellCoordinate: cellCoordinate,
          initialText: initialText,
          originContext: originContext,
          cellRect: rectState.cellRect,
          tableRect: rectState.tableRect,
          inlineEditorBuilder: inlineEditorBuilder,
          requestClose: requestClose,
        );
      },
    );
  }

  return OverlayEntry(builder: buildOverlay);
}

/// A [Widget] that wraps the content built by [InlineEditorBuilder].
///
/// It positions the editor in the appropriate place, aligns it according to
/// the cell aligment.
class _InlineEditorOverlayContent extends StatefulWidget {
  final IntVector2 cellCoordinate;
  final String? initialText;
  final BuildContext originContext;
  final Rect cellRect;
  final Rect tableRect;
  final InlineEditorBuilder inlineEditorBuilder;
  final VoidCallback requestClose;

  const _InlineEditorOverlayContent({
    Key? key,
    required this.cellCoordinate,
    required this.initialText,
    required this.originContext,
    required this.cellRect,
    required this.tableRect,
    required this.inlineEditorBuilder,
    required this.requestClose,
  }) : super(key: key);

  @override
  State<_InlineEditorOverlayContent> createState() =>
      _InlineEditorOverlayContentState();
}

class _InlineEditorOverlayContentState
    extends State<_InlineEditorOverlayContent> {
  late final internalScope = InternalScope.of(widget.originContext);
  late final style = internalScope.style;
  late final tableFocus = TableFocus.of(context);

  late final cell = internalScope
      .controller.cellsController.cellMatrixReadOnly[widget.cellCoordinate];

  /// The position od the editor in the screen, starts equals to
  /// [widget.cellRect] on init.
  late Rect editorRect;

  /// The minimal size to be assumed by the inline editor.Equals to the last
  /// visible size of [widget.cellRect],
  late Size editorMinSize;

  @override
  void initState() {
    super.initState();

    editorRect = widget.cellRect;
    editorMinSize = widget.cellRect.size;
  }

  void handleRequestClose() {
    widget.requestClose();
  }

  @override
  Widget build(BuildContext context) {
    final borderSide =
        style.userSelectionStyle.borderSide.toFlutterBorderSide();
    final borderSideWidth = borderSide.width;
    final border = Border.fromBorderSide(borderSide);
    final contentAlignment = cell?.contentAlignment ?? Alignment.centerLeft;

    if (widget.cellRect != Rect.zero) {
      // when the cell goes offscreen, do not update the
      // editor min size with it.
      editorMinSize = widget.cellRect.size;
    }

    return CustomSingleChildLayout(
      delegate: _PositionOverlayDelegate(
        editorRect: editorRect,
        contentAlignment: contentAlignment,
      ),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: border,
              boxShadow: style.inlineEditorShadow,
            ),
            child: Padding(
              padding: EdgeInsets.all(borderSideWidth),
              child: Align(
                alignment: contentAlignment,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: editorMinSize.width - borderSideWidth * 2,
                    minHeight: editorMinSize.height - borderSideWidth * 2,
                  ),
                  child: _TableOverlapCalculator(
                    tableRect: widget.tableRect,
                    cellRect: widget.cellRect,
                    builder: (
                      context,
                      overlapsTableRect,
                      overlapsCellRect,
                    ) {
                      return widget.inlineEditorBuilder(
                        widget.originContext,
                        widget.cellCoordinate,
                        handleRequestClose,
                        overlapCell: overlapsCellRect,
                        overlapTable: overlapsTableRect,
                        initialText: widget.initialText,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [SingleChildLayoutDelegate] responsible to align the inline editor content
/// to the [editorRect].
class _PositionOverlayDelegate extends SingleChildLayoutDelegate {
  final Rect editorRect;
  final Alignment contentAlignment;

  _PositionOverlayDelegate({
    required this.editorRect,
    required this.contentAlignment,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return super.getConstraintsForChild(constraints.loosen());
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final alignRight = contentAlignment.x > 0;

    final aligmentLeft =
        alignRight ? editorRect.right - childSize.width : editorRect.left;

    final effectiveLeft = aligmentLeft.clamp(0.0, size.width - childSize.width);
    final effectiveTop =
        editorRect.top.clamp(0.0, size.height - childSize.height);
    return Offset(effectiveLeft, effectiveTop);
  }

  @override
  bool shouldRelayout(_PositionOverlayDelegate oldDelegate) {
    return oldDelegate.editorRect != editorRect ||
        oldDelegate.contentAlignment != contentAlignment;
  }
}

/// A [Widget] that calculates if the inline editor
/// (in whatever size it is rendered) is overlapping [tableRect] or [cellRect].
class _TableOverlapCalculator extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    bool overlapTable,
    bool overlapCell,
  ) builder;

  final Rect tableRect;
  final Rect cellRect;

  const _TableOverlapCalculator({
    Key? key,
    required this.builder,
    required this.tableRect,
    required this.cellRect,
  }) : super(key: key);

  @override
  State<_TableOverlapCalculator> createState() =>
      _TableOverlapCalculatorState();
}

class _TableOverlapCalculatorState extends State<_TableOverlapCalculator> {
  bool overlapsTableRect = true;
  bool overlapsCellRect = true;

  @override
  void didUpdateWidget(_TableOverlapCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {
      updateRectPositioning();
    });
  }

  void updateRectPositioning() {
    final contextRenderObjectRect = context.findRenderObject();
    if (contextRenderObjectRect == null) {
      setState(() {
        overlapsTableRect = false;
        overlapsCellRect = false;
      });
      return;
    }

    final overlay = Overlay.of(context)!.context.findRenderObject()!;

    final translation =
        contextRenderObjectRect.getTransformTo(overlay).getTranslation();

    final contextRect = contextRenderObjectRect.paintBounds
        .shift(Offset(translation.x, translation.y));

    setState(() {
      overlapsTableRect = widget.tableRect != Rect.zero
          ? widget.tableRect.overlaps(contextRect)
          : false;
      overlapsCellRect = widget.cellRect != Rect.zero
          ? widget.cellRect.overlaps(contextRect)
          : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      overlapsTableRect,
      overlapsCellRect,
    );
  }
}
