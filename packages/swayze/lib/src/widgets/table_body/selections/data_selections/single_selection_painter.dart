import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';

import '../../../../../controller.dart';
import '../selection_rendering_helpers.dart';

/// A [LeafRenderObjectWidget] that renders a specific [Selection]
/// into the viewport.
class SingleSelectionPainter extends LeafRenderObjectWidget {
  final SelectionRenderData renderData;

  const SingleSelectionPainter({
    Key? key,
    required this.renderData,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDataSelection(renderData);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDataSelection renderObject,
  ) {
    renderObject.renderData = renderData;
  }
}

class _RenderDataSelection extends RenderBox {
  _RenderDataSelection(this._renderData);

  SelectionRenderData _renderData;

  SelectionRenderData get renderData {
    return _renderData;
  }

  set renderData(SelectionRenderData value) {
    _renderData = value;
    markNeedsPaint();
  }

  late final backgroundPaint = CachedValue(
    () =>
        Paint()..color = _renderData.backgroundColor ?? const Color(0x00000000),
  ).withDependency(() => _renderData.backgroundColor);

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();

    final selectionRect = renderData.rect;

    if (_renderData.backgroundColor != null) {
      canvas.drawRect(selectionRect, backgroundPaint.value);
    }

    canvas.translate(offset.dx, offset.dy);
    paintSelectionBorder(canvas, selectionRect, _renderData.border);

    canvas.restore();
  }
}
