import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../../controller.dart';
import '../../../../core/viewport_context/viewport_context_provider.dart';
import '../../../internal_scope.dart';
import '../selection_rendering_helpers.dart';

/// A [StatefulWidget] to render the a fill selection.
///
/// It is implicitly animated, it means that changes on the size and position
/// of the selection should reflect in an animation.
class FillSelection extends StatefulWidget {
  /// The [FillSelectionModel] to be rendered.
  final FillSelectionModel selectionModel;

  final Range xRange;
  final Range yRange;

  final bool isOnFrozenColumns;

  final bool isOnFrozenRows;

  const FillSelection({
    Key? key,
    required this.selectionModel,
    required this.xRange,
    required this.yRange,
    required this.isOnFrozenColumns,
    required this.isOnFrozenRows,
  }) : super(key: key);

  @override
  State<FillSelection> createState() => _FillSelectionState();
}

class _FillSelectionState extends State<FillSelection>
    with SelectionRenderingHelpers {
  late final styleContext = InternalScope.of(context).style;

  @override
  Range get xRange => widget.xRange;

  @override
  Range get yRange => widget.yRange;

  @override
  bool get isOnFrozenColumns => widget.isOnFrozenColumns;

  @override
  bool get isOnFrozenRows => widget.isOnFrozenRows;

  /// Holds the handle style, if the configuration says we should use one.
  late final handleStyle = InternalScope.of(context).config.isDragFillEnabled
      ? InternalScope.of(context).style.dragAndFillStyle.handle
      : null;

  @override
  late final viewportContext = ViewportContextProvider.of(context);

  late final tableDataController =
      InternalScope.of(context).controller.tableDataController;

  @override
  Widget build(BuildContext context) {
    final selectionModel = widget.selectionModel;
    final range = selectionModel.bound(to: tableDataController.tableRange);
    final leftTopPixelOffset = getLeftTopOffset(range.leftTop);

    final rightBottomPixelOffset = getRightBottomOffset(range.rightBottom);
    final sizeOffset = rightBottomPixelOffset - leftTopPixelOffset;

    final effectiveStyle = widget.selectionModel.toSelectionStyle(context);

    return _AnimatedFillSelection(
      size: Size(sizeOffset.dx, sizeOffset.dy),
      offset: leftTopPixelOffset,
      border: getVisibleBorder(
        range,
        effectiveStyle.borderSide,
      ),
      duration: styleContext.selectionAnimationDuration,
    );
  }
}

/// An [ImplicitlyAnimatedWidget] that swiftly animates when [offset] and [size]
/// changes.
class _AnimatedFillSelection extends ImplicitlyAnimatedWidget {
  final SelectionBorder border;
  final Size size;
  final Offset offset;

  const _AnimatedFillSelection({
    Key? key,
    required this.border,
    required this.size,
    required this.offset,
    required Duration duration,
  }) : super(key: key, duration: duration);

  @override
  _AnimatedSelectionState createState() => _AnimatedSelectionState();
}

class _AnimatedSelectionState
    extends AnimatedWidgetBaseState<_AnimatedFillSelection> {
  late final viewportContext = ViewportContextProvider.of(context);

  Tween<double>? _left;
  Tween<double>? _top;
  SizeTween? _size;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _left = visitor(
      _left,
      widget.offset.dx,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;

    _top = visitor(
      _top,
      widget.offset.dy,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;

    _size = visitor(
      _size,
      widget.size,
      (dynamic value) => SizeTween(begin: value as Size),
    ) as SizeTween?;
  }

  @override
  Widget build(BuildContext context) {
    final animation = this.animation;
    final left = _left?.evaluate(animation) ?? 0;
    final top = _top?.evaluate(animation) ?? 0;
    final size = _size?.evaluate(animation) ?? Size.zero;

    return FillSelectionPainter(
      border: widget.border,
      offset: Offset(left, top),
      size: size,
    );
  }
}

/// A [LeafRenderObjectWidget] that render a fill selection.
@visibleForTesting
class FillSelectionPainter extends LeafRenderObjectWidget {
  final SelectionBorder border;
  final Offset offset;
  final Size size;

  const FillSelectionPainter({
    required this.border,
    required this.offset,
    required this.size,
  });

  @override
  _RenderFillSelectionPainter createRenderObject(BuildContext context) {
    return _RenderFillSelectionPainter(
      border,
      offset,
      size,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFillSelectionPainter renderObject,
  ) {
    renderObject
      ..border = border
      ..offset = offset
      ..definedSize = size;
  }
}

class _RenderFillSelectionPainter extends RenderBox {
  _RenderFillSelectionPainter(
    this._border,
    this._offset,
    this._definedSize,
  );

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset != value) {
      _offset = value;
      markNeedsPaint();
    }
  }

  Size _definedSize;
  Size get definedSize => _definedSize;
  set definedSize(Size value) {
    if (_definedSize != value) {
      _definedSize = value;
      markNeedsLayout();
    }
  }

  SelectionBorder _border;
  SelectionBorder get border => _border;
  set border(SelectionBorder value) {
    if (_border != value) {
      _border = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    size = constraints.constrain(_definedSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    paintSelectionBorder(
      canvas,
      _offset & size,
      border,
    );

    canvas.restore();
  }
}

extension on FillSelectionModel {
  SelectionStyle toSelectionStyle(BuildContext context) {
    if (style != null) {
      return style!;
    }

    final effectiveStyle = InternalScope.of(context).style;

    return SelectionStyle.dashedBorderOnly(
      color: effectiveStyle.dragAndFillStyle.color,
      borderWidth: effectiveStyle.dragAndFillStyle.borderWidth,
    );
  }
}
