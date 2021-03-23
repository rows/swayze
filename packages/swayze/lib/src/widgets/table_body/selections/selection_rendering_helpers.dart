import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../core/controller/selection/model/selection.dart';
import '../../../core/controller/selection/model/selection_style.dart';
import '../../../core/controller/selection/user_selections/model.dart';
import '../../../core/viewport_context/viewport_context.dart';

/// Information necessary to render the border of a [Selection] in the canvas.
///
/// See also:
/// - [SelectionRenderData]
@immutable
class SelectionBorder {
  final SelectionBorderSide borderSide;

  final bool hasLeft;
  final bool hasTop;
  final bool hasRight;
  final bool hasBottom;

  const SelectionBorder({
    required this.borderSide,
    required this.hasLeft,
    required this.hasTop,
    required this.hasRight,
    required this.hasBottom,
  });

  Border toFlutterBorder() {
    final side = borderSide.toFlutterBorderSide();
    return Border(
      left: hasLeft ? side : BorderSide.none,
      top: hasTop ? side : BorderSide.none,
      right: hasRight ? side : BorderSide.none,
      bottom: hasBottom ? side : BorderSide.none,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionBorder &&
          runtimeType == other.runtimeType &&
          borderSide == other.borderSide &&
          hasLeft == other.hasLeft &&
          hasTop == other.hasTop &&
          hasRight == other.hasRight &&
          hasBottom == other.hasBottom;

  @override
  int get hashCode =>
      borderSide.hashCode ^
      hasLeft.hashCode ^
      hasTop.hashCode ^
      hasRight.hashCode ^
      hasBottom.hashCode;
}

/// Information necessary to render a selection in the table body derived from
/// a [SelectionStyle]
@immutable
class SelectionRenderData {
  final Rect rect;
  final SelectionBorder border;
  final Color? backgroundColor;

  const SelectionRenderData({
    required this.rect,
    required this.border,
    this.backgroundColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionRenderData &&
          runtimeType == other.runtimeType &&
          rect == other.rect &&
          border == other.border;

  @override
  int get hashCode => rect.hashCode ^ border.hashCode;
}

/// Reunites a couple of helper functions that convert the information available
/// in a [UserSelectionModel] to actual pixels in the viewport using
/// [ViewportContext].
mixin SelectionRenderingHelpers {
  ViewportContext get viewportContext;

  /// The range that defines the visual limits of the selection in the viewport
  /// in the horizontal axis.
  Range get xRange;

  /// The range that defines the visual limits of the selection in the viewport
  /// in the vertical axis.
  Range get yRange;

  bool get isOnFrozenColumns;

  bool get isOnFrozenRows;

  /// Given the selection range it returns a [BoxDecoration] with the borders
  /// that are actually in the viewport and should be painted.
  SelectionBorder getVisibleBorder(
    Range2D range,
    SelectionBorderSide borderSide,
  ) {
    final hasLeft = xRange.contains(range.leftTop.dx);
    final hasTop = yRange.contains(range.leftTop.dy);
    final hasRight = xRange.contains(range.rightBottom.dx) ||
        xRange.end == range.rightBottom.dx;
    final hasBottom = yRange.contains(range.rightBottom.dy) ||
        yRange.end == range.rightBottom.dy;

    return SelectionBorder(
      borderSide: borderSide,
      hasLeft: hasLeft,
      hasTop: hasTop,
      hasRight: hasRight,
      hasBottom: hasBottom,
    );
  }

  Offset getLeftTopOffset(IntVector2 coordinate) {
    final x = viewportContext
        .positionToPixel(
          coordinate.dx,
          Axis.horizontal,
          isForFrozenPanes: isOnFrozenColumns,
        )
        .pixel;
    final y = viewportContext
        .positionToPixel(
          coordinate.dy,
          Axis.vertical,
          isForFrozenPanes: isOnFrozenRows,
        )
        .pixel;

    return Offset(x, y);
  }

  Offset getRightBottomOffset(IntVector2 coordinate) {
    final x = viewportContext
        .positionToPixel(
          coordinate.dx,
          Axis.horizontal,
          isForFrozenPanes: isOnFrozenColumns,
        )
        .pixel;
    final y = viewportContext
        .positionToPixel(
          coordinate.dy,
          Axis.vertical,
          isForFrozenPanes: isOnFrozenRows,
        )
        .pixel;

    return Offset(x, y);
  }
}

/// Paints a [SelectionBorder] into a [canvas].
void paintSelectionBorder(
  Canvas canvas,
  Rect selectionRect,
  SelectionBorder border,
) {
  final color = border.borderSide.color;
  final width = border.borderSide.width;
  if (width == 0 || color == null || color.alpha == 0) {
    return;
  }

  var path = Path();

  final rect = selectionRect.deflate(border.borderSide.width / 2);

  path.moveTo(rect.left, rect.top);

  if (border.hasTop) {
    path.lineTo(rect.right, rect.top);
  } else {
    path.moveTo(rect.right, rect.top);
  }

  if (border.hasRight) {
    path.lineTo(rect.right, rect.bottom);
  } else {
    path.moveTo(rect.right, rect.bottom);
  }

  if (border.hasBottom) {
    path.lineTo(rect.left, rect.bottom);
  } else {
    path.moveTo(rect.left, rect.bottom);
  }

  if (border.hasLeft) {
    path.lineTo(rect.left, rect.top);
  } else {
    path.moveTo(rect.left, rect.top);
  }

  if (border.borderSide.dashed) {
    path = dashPath(
      path,
      dashArray: CircularIntervalList(border.borderSide.dashIntervals),
    );
  }

  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  canvas.drawPath(path, paint);
}
