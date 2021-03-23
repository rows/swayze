import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../../controller.dart';
import '../../../../core/viewport_context/viewport_context_provider.dart';
import '../../../internal_scope.dart';
import '../selection_rendering_helpers.dart';

/// A [StatefulWidget] to render the primary selection of the
/// [UserSelectionState].
///
/// Differently from [SecondarySelections] it render just a single
/// [UserSelectionModel].
///
/// It is implicitly animated, it means that changes on the size and position
/// of the selection should reflect in an animation.
class PrimarySelection extends StatefulWidget {
  /// The [UserSelectionModel] to be rendered.
  final UserSelectionModel selectionModel;

  final Rect activeCellRect;

  final Range xRange;
  final Range yRange;

  final bool isOnFrozenColumns;

  final bool isOnFrozenRows;

  const PrimarySelection({
    Key? key,
    required this.selectionModel,
    required this.activeCellRect,
    required this.xRange,
    required this.yRange,
    required this.isOnFrozenColumns,
    required this.isOnFrozenRows,
  }) : super(key: key);

  @override
  State<PrimarySelection> createState() => _PrimarySelectionState();
}

class _PrimarySelectionState extends State<PrimarySelection>
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

  /// The actual decoration of this particular selection resolved from
  /// [SwayzeStyle].
  late final selectionStyle = widget.selectionModel.style ??
      InternalScope.of(context).style.userSelectionStyle;

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
    final size = Size(sizeOffset.dx, sizeOffset.dy);

    final isSingleCell =
        selectionModel is CellUserSelectionModel && selectionModel.isSingleCell;

    final borderSide = selectionStyle.borderSide;

    return _AnimatedPrimarySelection(
      size: size,
      offset: leftTopPixelOffset,
      decoration: BoxDecoration(
        color: selectionStyle.backgroundColor,
        border: getVisibleBorder(range, borderSide).toFlutterBorder(),
      ),
      duration: styleContext.selectionAnimationDuration,
      activeCellRect: widget.activeCellRect,
      isSingleCell: isSingleCell,
    );
  }
}

/// An [ImplicitlyAnimatedWidget] that swiftly animates when [offset] and [size]
/// changes.
class _AnimatedPrimarySelection extends ImplicitlyAnimatedWidget {
  final Offset offset;
  final Size size;
  final BoxDecoration decoration;
  final Rect activeCellRect;
  final bool isSingleCell;

  const _AnimatedPrimarySelection({
    Key? key,
    required this.offset,
    required this.size,
    required this.decoration,
    required Duration duration,
    required this.activeCellRect,
    required this.isSingleCell,
  }) : super(key: key, duration: duration);

  @override
  _AnimatedSelectionState createState() => _AnimatedSelectionState();
}

class _AnimatedSelectionState
    extends AnimatedWidgetBaseState<_AnimatedPrimarySelection> {
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

    final offset = Offset(left, top);

    return PrimarySelectionPainter(
      isSingleCell: widget.isSingleCell,
      decoration: widget.decoration,
      offset: offset,
      size: size,
      activeCellRect: widget.activeCellRect,
    );
  }
}

/// A [LeafRenderObjectWidget] that render a primary selection.
///
/// When [isSingleCell] is set to true, it doesn't paint background.
@visibleForTesting
class PrimarySelectionPainter extends LeafRenderObjectWidget {
  final Size size;
  final Offset offset;
  final BoxDecoration decoration;
  final Rect activeCellRect;
  final bool isSingleCell;

  const PrimarySelectionPainter({
    required this.isSingleCell,
    required this.size,
    required this.offset,
    required this.decoration,
    required this.activeCellRect,
  });

  @override
  _RenderPrimarySelectionPainter createRenderObject(BuildContext context) {
    return _RenderPrimarySelectionPainter(
      decoration,
      offset,
      size,
      activeCellRect,
      isSingleCell: isSingleCell,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPrimarySelectionPainter renderObject,
  ) {
    renderObject
      ..isSingleCell = isSingleCell
      ..decoration = decoration
      ..offset = offset
      ..definedSize = size
      ..activeCellRect = activeCellRect;
  }
}

class _RenderPrimarySelectionPainter extends RenderBox {
  _RenderPrimarySelectionPainter(
    this._decoration,
    this._offset,
    this._definedSize,
    this._activeCellRect, {
    required bool isSingleCell,
  }) : _isSingleCell = isSingleCell;

  bool _isSingleCell;

  bool get isSingleCell {
    return _isSingleCell;
  }

  set isSingleCell(bool value) {
    _isSingleCell = value;
    markNeedsPaint();
  }

  Offset _offset;

  Offset get offset {
    return _offset;
  }

  set offset(Offset value) {
    _offset = value;
    markNeedsPaint();
  }

  Size _definedSize;

  Size get definedSize {
    return _definedSize;
  }

  set definedSize(Size value) {
    _definedSize = value;
    markNeedsLayout();
  }

  BoxDecoration _decoration;

  BoxDecoration get decoration {
    return _decoration;
  }

  set decoration(BoxDecoration value) {
    _decoration = value;
    markNeedsPaint();
  }

  Rect _activeCellRect;

  Rect get activeCellRect {
    return _activeCellRect;
  }

  set activeCellRect(Rect value) {
    _activeCellRect = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = constraints.constrain(_definedSize);
  }

  late final backgroundPaint = CachedValue(
    () => Paint()..color = _decoration.color!,
  ).withDependency(() => _decoration);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.save();

    canvas.translate(offset.dx, offset.dy);

    final selectionRect = _offset & size;
    final selectionPath = Path()..addRect(selectionRect);

    // paint border
    _decoration.border!.paint(canvas, selectionRect);

    if (!_isSingleCell) {
      final activeCellPath = Path()..addRect(_activeCellRect);

      // crop active cell
      final overallPath = Path.combine(
        PathOperation.difference,
        selectionPath,
        activeCellPath,
      );

      canvas.drawPath(overallPath, backgroundPaint.value);
    }

    canvas.restore();
  }
}
