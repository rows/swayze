import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../../controller.dart';
import '../../../../core/style/style.dart';
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
      handleStyle: handleStyle,
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
  final SwayzeDragAndFillHandleStyle? handleStyle;
  final Rect activeCellRect;
  final bool isSingleCell;

  const _AnimatedPrimarySelection({
    Key? key,
    required this.offset,
    required this.size,
    required this.decoration,
    required this.handleStyle,
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

  /// Holds the animation value for the handle.
  /// `0.0` - No handle.
  /// `1.0` - Paint handle.
  Tween<double>? _handleValue;

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

    _handleValue = visitor(
      _handleValue,
      widget.handleStyle != null ? 1.0 : 0.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
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
      handleStyle: widget.handleStyle,
      offset: offset,
      size: size,
      activeCellRect: widget.activeCellRect,
      handleValue: _handleValue?.evaluate(animation) ?? 0,
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

  /// Paints the handle depending on the value.
  /// `0.0` - No handle.
  /// `1.0` - Paint handle.
  final double handleValue;
  final SwayzeDragAndFillHandleStyle? handleStyle;

  const PrimarySelectionPainter({
    required this.isSingleCell,
    required this.size,
    required this.offset,
    required this.decoration,
    required this.activeCellRect,
    required this.handleValue,
    this.handleStyle,
  });

  @override
  _RenderPrimarySelectionPainter createRenderObject(BuildContext context) {
    return _RenderPrimarySelectionPainter(
      decoration,
      offset,
      size,
      activeCellRect,
      isSingleCell: isSingleCell,
      handleValue: handleValue,
      handleStyle: handleStyle,
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
      ..activeCellRect = activeCellRect
      ..handleValue = handleValue
      ..handleStyle = handleStyle;
  }
}

class _RenderPrimarySelectionPainter extends RenderBox {
  _RenderPrimarySelectionPainter(
    this._decoration,
    this._offset,
    this._definedSize,
    this._activeCellRect, {
    required bool isSingleCell,
    required double handleValue,
    SwayzeDragAndFillHandleStyle? handleStyle,
  })  : _isSingleCell = isSingleCell,
        _handleValue = handleValue,
        _handleStyle = handleStyle;

  bool _isSingleCell;
  bool get isSingleCell => _isSingleCell;
  set isSingleCell(bool value) {
    if (_isSingleCell != value) {
      _isSingleCell = value;
      markNeedsPaint();
    }
  }

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

  BoxDecoration _decoration;
  BoxDecoration get decoration => _decoration;
  set decoration(BoxDecoration value) {
    if (_decoration != value) {
      _decoration = value;
      markNeedsPaint();
    }
  }

  Rect _activeCellRect;
  Rect get activeCellRect => _activeCellRect;
  set activeCellRect(Rect value) {
    if (_activeCellRect != value) {
      _activeCellRect = value;
      markNeedsPaint();
    }
  }

  double _handleValue;
  double get handleValue => _handleValue;
  set handleValue(double value) {
    if (_handleValue != value) {
      _handleValue = value;
      markNeedsPaint();
    }
  }

  SwayzeDragAndFillHandleStyle? _handleStyle;
  SwayzeDragAndFillHandleStyle? get handleStyle => _handleStyle;
  set handleStyle(SwayzeDragAndFillHandleStyle? value) {
    if (_handleStyle != value) {
      _handleStyle = value;
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

    final selectionRect = _offset & size;
    final selectionPath = Path()..addRect(selectionRect);

    // Prepares the handle rect, if one is to be shown.
    final handleRect = _handleValue > 0.0 && _handleStyle != null
        ? Rect.fromLTWH(
            selectionRect.right -
                (_handleStyle!.size.width / 2.0).ceilToDouble(),
            selectionRect.bottom -
                (_handleStyle!.size.height / 2.0).ceilToDouble(),
            _handleStyle!.size.width,
            _handleStyle!.size.height,
          )
        : null;
    final emptyHandleRect = handleRect != null
        ? Rect.fromCenter(
            center: handleRect.center,
            width: 0.0,
            height: 0.0,
          )
        : null;

    // If a handle is to be shown, we need to first clip the border so that
    // is doesn't paint where the handle will be painted.
    if (handleRect != null) {
      canvas.save();

      final clipRect = Rect.lerp(
        emptyHandleRect!,
        handleRect.inflate(_handleStyle!.borderWidth),
        _handleValue,
      );

      if (clipRect != null) {
        canvas.clipRect(
          clipRect,
          clipOp: ClipOp.difference,
        );
      }
    }

    _decoration.border!.paint(canvas, selectionRect);

    // Restores the saved stack when adding the border clipping.
    if (handleRect != null) {
      canvas.restore();
    }

    if (!_isSingleCell && _decoration.color != null) {
      final activeCellPath = Path()..addRect(_activeCellRect);

      // crop active cell
      final overallPath = Path.combine(
        PathOperation.difference,
        selectionPath,
        activeCellPath,
      );

      canvas.drawPath(
        overallPath,
        Paint()..color = _decoration.color!,
      );
    }

    // Paints the handle, if one is needed.
    if (handleRect != null) {
      canvas.drawRect(
        Rect.lerp(emptyHandleRect!, handleRect, _handleValue) ?? Rect.zero,
        Paint()..color = handleStyle!.color,
      );
    }

    canvas.restore();
  }
}
