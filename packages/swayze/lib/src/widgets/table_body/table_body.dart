import 'package:flutter/widgets.dart';

import '../../core/style/style.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../../core/viewport_context/viewport_context_provider.dart';
import '../headers/header_drag_and_drop_preview.dart';
import '../internal_scope.dart';
import '../shared/expand_all.dart';
import '../wrappers.dart';
import 'cells/cells_wrapper.dart';
import 'gestures/table_body_gesture_detector.dart';
import 'mouse_hover/mouse_hover.dart';
import 'selections/selections.dart';
import 'table_lines.dart';

/// The main area of the spreadsheet layout.
///
/// It contains the lines separating cells and the actual cell widgets.
/// Different from the headers, it has to list for changes in the ranges of both
/// axis instead of only one.
///
/// It contains a [CustomSingleChildLayout] that applies the displacements
/// [horizontalDisplacement] and [verticalDisplacement]. Everything under that
/// is agnostic of displacement.
class TableBody extends StatelessWidget {
  final double horizontalDisplacement;
  final double verticalDisplacement;

  final WrapTableBodyBuilder? wrapTableBody;

  const TableBody({
    Key? key,
    required this.horizontalDisplacement,
    required this.verticalDisplacement,
    required this.wrapTableBody,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewportContext = ViewportContextProvider.of(context);
    final style = InternalScope.of(context).style;

    final viewportColumnsState = viewportContext.columns.value;
    final viewportRowsState = viewportContext.rows.value;

    final areaSize = Size(
      viewportColumnsState.extent + viewportColumnsState.frozenExtent,
      viewportRowsState.extent + viewportRowsState.frozenExtent,
    );

    final hasFrozenRows = viewportRowsState.frozenOffsets.isNotEmpty;
    final hasFrozenColumns = viewportColumnsState.frozenOffsets.isNotEmpty;

    Widget tableBody = MouseHoverTableBody(
      child: ExpandAll(
        children: [
          // There are 5 possible areas of content in the table body.

          // There is the always present scrollable area
          _TableBodyScrollableArea(
            style: style,
            viewportContext: viewportContext,
          ),

          // If there is any frozen rows, add the area responsible for
          // them.
          // Fixed vertically, scrollable horizontally
          if (hasFrozenRows)
            _TableBodyFrozenArea(
              style: style,
              horizontalDisplacement: horizontalDisplacement,
              verticalDisplacement: verticalDisplacement,
              viewportContext: viewportContext,
              isOnAFrozenRowsArea: true,
            ),

          // If there is any frozen columns, add the area responsible for
          // them.
          // Fixed horizontally, scrollable vertically
          if (hasFrozenColumns)
            _TableBodyFrozenArea(
              style: style,
              horizontalDisplacement: horizontalDisplacement,
              verticalDisplacement: verticalDisplacement,
              viewportContext: viewportContext,
              isOnAFrozenColumnsArea: true,
            ),

          // If there is any frozen columns and rows,
          // add the area responsible for them.
          // Fixed horizontally and vertically
          if (hasFrozenColumns && hasFrozenRows)
            _TableBodyFrozenArea(
              style: style,
              horizontalDisplacement: horizontalDisplacement,
              verticalDisplacement: verticalDisplacement,
              viewportContext: viewportContext,
              isOnAFrozenColumnsArea: true,
              isOnAFrozenRowsArea: true,
            ),

          // If columns or rows are being dragged, add the preview on top
          // of other table layers.
          if (viewportContext.columns.value.isDragging ||
              viewportContext.rows.value.isDragging)
            RepaintBoundary(
              key: const ValueKey('RepaintBoundaryHeaderDragAndDropPreview'),
              child: HeaderDragAndDropPreview(
                axis: viewportContext.columns.value.isDragging
                    ? Axis.horizontal
                    : Axis.vertical,
                swayzeStyle: style,
              ),
            ),

          // All areas respond to only one gesture detector
          TableBodyGestureDetector(
            horizontalDisplacement: horizontalDisplacement,
            verticalDisplacement: verticalDisplacement,
          ),
        ],
      ),
    );

    final wrapTableBody = this.wrapTableBody;

    if (wrapTableBody != null) {
      tableBody = wrapTableBody(context, viewportContext, tableBody);
    }

    return ClipRect(
      child: CustomSingleChildLayout(
        delegate: _TableBodyLayoutDelegate(
          horizontalDisplacement,
          verticalDisplacement,
          areaSize,
        ),
        child: tableBody,
      ),
    );
  }
}

/// The part of [TableBody] that renders the elements in the scrollable part:
/// - Selections
/// - Cells
/// - Lines
class _TableBodyScrollableArea extends StatelessWidget {
  final SwayzeStyle style;
  final ViewportContext viewportContext;

  const _TableBodyScrollableArea({
    Key? key,
    required this.style,
    required this.viewportContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final offset = Offset(
      viewportContext.columns.value.frozenExtent,
      viewportContext.rows.value.frozenExtent,
    );

    return ExpandAll(
      children: [
        const RepaintBoundary(
          key: ValueKey('RepaintBoundaryCells'),
          child: CellsWrapper(),
        ),
        RepaintBoundary(
          key: const ValueKey('RepaintBoundaryTableLines'),
          child: TableLines(
            columnSizes: viewportContext.columns.value.sizes,
            rowSizes: viewportContext.rows.value.sizes,
            swayzeStyle: style,
            translateOffset: offset,
          ),
        ),
        const ClipRect(child: TableBodySelections()),
      ],
    );
  }
}

/// The part of [TableBody] that renders the elements in the frozen parts:
/// - Selections
/// - Cells
/// - Lines
class _TableBodyFrozenArea extends StatelessWidget {
  final double horizontalDisplacement;
  final double verticalDisplacement;
  final SwayzeStyle style;
  final bool isOnAFrozenColumnsArea;
  final bool isOnAFrozenRowsArea;
  final ViewportContext viewportContext;

  const _TableBodyFrozenArea({
    Key? key,
    required this.horizontalDisplacement,
    required this.verticalDisplacement,
    required this.style,
    this.isOnAFrozenColumnsArea = false,
    this.isOnAFrozenRowsArea = false,
    required this.viewportContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewportColumnsState = viewportContext.columns.value;
    final viewportRowsState = viewportContext.rows.value;

    // Displacement correction
    final horizontalDisplacement =
        isOnAFrozenColumnsArea ? this.horizontalDisplacement.abs() : 0.0;

    final verticalDisplacement =
        isOnAFrozenRowsArea ? this.verticalDisplacement.abs() : 0.0;

    // Extent
    final horizontalExtent = isOnAFrozenColumnsArea
        ? viewportColumnsState.frozenExtent
        : viewportColumnsState.extent;

    final verticalExtent = isOnAFrozenRowsArea
        ? viewportRowsState.frozenExtent
        : viewportRowsState.extent;

    // Sizes
    final horizontalSizes = isOnAFrozenColumnsArea
        ? viewportColumnsState.frozenSizes
        : viewportColumnsState.sizes;

    final verticalSizes = isOnAFrozenRowsArea
        ? viewportRowsState.frozenSizes
        : viewportRowsState.sizes;

    // Lines offset
    final offset = Offset(
      isOnAFrozenColumnsArea ? 0.0 : viewportColumnsState.frozenExtent,
      isOnAFrozenRowsArea ? 0.0 : viewportRowsState.frozenExtent,
    );

    return CustomSingleChildLayout(
      delegate: _TableBodyLayoutDelegate(
        horizontalDisplacement,
        verticalDisplacement,
        Size(horizontalExtent, verticalExtent),
      ),
      child: ExpandAll(
        children: [
          ColoredBox(
            color: style.defaultCellBackground,
          ),
          RepaintBoundary(
            key: const ValueKey('RepaintBoundaryCells'),
            child: CellsWrapper(
              isOnAFrozenRowsArea: isOnAFrozenRowsArea,
              isOnAFrozenColumnsArea: isOnAFrozenColumnsArea,
            ),
          ),
          RepaintBoundary(
            key: const ValueKey('RepaintBoundaryTableLines'),
            child: TableLines(
              columnSizes: horizontalSizes,
              rowSizes: verticalSizes,
              swayzeStyle: style,
              translateOffset: offset,
            ),
          ),
          ClipRect(
            child: TableBodySelections(
              isOnAFrozenRowsArea: isOnAFrozenRowsArea,
              isOnAFrozenColumnsArea: isOnAFrozenColumnsArea,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _TableBodyLayoutDelegate extends SingleChildLayoutDelegate {
  final double horizontalDisplacement;
  final double verticalDisplacement;
  final Size areaSize;

  const _TableBodyLayoutDelegate(
    this.horizontalDisplacement,
    this.verticalDisplacement,
    this.areaSize,
  );

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    /// Makes child get the exact size of the viewport
    return constraints.enforce(BoxConstraints.tight(areaSize));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    /// Make child retract the displacement
    return Offset(horizontalDisplacement, verticalDisplacement);
  }

  @override
  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TableBodyLayoutDelegate &&
          runtimeType == other.runtimeType &&
          verticalDisplacement == other.verticalDisplacement &&
          horizontalDisplacement == other.horizontalDisplacement &&
          areaSize == other.areaSize;

  @override
  int get hashCode =>
      verticalDisplacement.hashCode ^
      horizontalDisplacement.hashCode ^
      areaSize.hashCode;
}
