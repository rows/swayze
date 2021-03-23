import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';
import '../../../../../controller.dart';

import '../../../../core/viewport_context/viewport_context_provider.dart';
import '../../../internal_scope.dart';
import '../../../shared/expand_all.dart';
import '../primary_selection/primary_selection.dart';
import '../selection_rendering_helpers.dart';
import 'secondary_selection_group.dart';

/// A [StatefulWidget] that render all selections except the primary selection.
///
/// It filters out the primary selection and any selection with no
/// representation in the current viewport.
///
/// To avoid selection overlap performance issues, it combines selections shapes
/// into one if there is more selections with  single [UserSelectionStyle] than
/// specified by [kOverlapThreshold].
///
/// See also:
/// - [PrimarySelection] that render the primary selection
class SecondarySelections extends StatefulWidget {
  final UserSelectionState selectionState;
  final Rect activeCellRect;

  final Range xRange;
  final Range yRange;

  final bool isOnFrozenColumns;
  final bool isOnFrozenRows;

  const SecondarySelections({
    Key? key,
    required this.selectionState,
    required this.activeCellRect,
    required this.xRange,
    required this.yRange,
    required this.isOnFrozenColumns,
    required this.isOnFrozenRows,
  }) : super(key: key);

  @override
  State<SecondarySelections> createState() => _SecondarySelectionsState();
}

class _SecondarySelectionsState extends State<SecondarySelections>
    with SelectionRenderingHelpers {
  @override
  Range get xRange => widget.xRange;

  @override
  Range get yRange => widget.yRange;

  @override
  bool get isOnFrozenColumns => widget.isOnFrozenColumns;

  @override
  bool get isOnFrozenRows => widget.isOnFrozenRows;

  @override
  late final viewportContext = ViewportContextProvider.of(context);

  late final styleContext = InternalScope.of(context).style;

  late final tableController =
      InternalScope.of(context).controller.tableDataController;

  late Map<SelectionStyle, Iterable<SelectionRenderData>>
      selectionsGroupedByStyle;

  @override
  void initState() {
    super.initState();
    groupSelectionModelsByStyle();
  }

  @override
  void didUpdateWidget(SecondarySelections oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectionState == widget.selectionState) {
      return;
    }
    groupSelectionModelsByStyle();
  }

  void groupSelectionModelsByStyle() {
    final viewportRange2D = Range2D.fromSides(xRange, yRange);

    final selectionsGrouped = <SelectionStyle, List<SelectionRenderData>>{};
    final secondarySelections = widget.selectionState.secondarySelections;
    final tableRange = tableController.tableRange;

    for (final userSelectionModel in secondarySelections) {
      // filter out selections with no representation in the current viewport
      if (userSelectionModel is CellUserSelectionModel &&
          !viewportRange2D.overlaps(userSelectionModel)) {
        continue;
      }

      if (userSelectionModel is HeaderUserSelectionModel) {
        final rangeAxis =
            userSelectionModel.axis == Axis.horizontal ? xRange : yRange;

        if (!rangeAxis.overlaps(userSelectionModel)) {
          continue;
        }
      }
      final range = userSelectionModel.bound(to: tableRange);
      final leftTopPixelOffset = getLeftTopOffset(range.leftTop);
      final rightBottomPixelOffset = getRightBottomOffset(range.rightBottom);
      final sizeOffset = rightBottomPixelOffset - leftTopPixelOffset;
      final size = Size(sizeOffset.dx, sizeOffset.dy);

      final style = userSelectionModel.style ?? styleContext.userSelectionStyle;

      final selectionList = selectionsGrouped[style] ?? [];

      final borderSide = style.borderSide;

      selectionList.add(
        SelectionRenderData(
          rect: leftTopPixelOffset & size,
          border: getVisibleBorder(range, borderSide),
        ),
      );

      selectionsGrouped[style] = selectionList;
    }

    setState(() {
      selectionsGroupedByStyle = selectionsGrouped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    selectionsGroupedByStyle.forEach((selectionStyle, selectionRenderData) {
      children.add(
        SecondarySelectionGroup(
          selectionStyle: selectionStyle,
          selectionGroup: selectionRenderData,
          activeCellRect: widget.activeCellRect,
        ),
      );
    });

    return ExpandAll(
      children: children,
    );
  }
}
