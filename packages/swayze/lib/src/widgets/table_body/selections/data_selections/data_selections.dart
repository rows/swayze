import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../../controller.dart';
import '../../../../core/viewport_context/viewport_context_provider.dart';
import '../../../internal_scope.dart';
import '../../../shared/expand_all.dart';
import '../selection_rendering_helpers.dart';
import 'single_selection_painter.dart';

class DataSelections extends StatefulWidget {
  final Iterable<Selection> dataSelections;

  final Range xRange;
  final Range yRange;

  final bool isOnFrozenColumns;

  final bool isOnFrozenRows;

  const DataSelections({
    Key? key,
    required this.dataSelections,
    required this.xRange,
    required this.yRange,
    required this.isOnFrozenColumns,
    required this.isOnFrozenRows,
  }) : super(key: key);

  @override
  State<DataSelections> createState() => _DataSelectionsState();
}

class _DataSelectionsState extends State<DataSelections>
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

  late final tableDataController =
      InternalScope.of(context).controller.tableDataController;

  @override
  Widget build(BuildContext context) {
    final tableRange = tableDataController.tableRange;

    final children = <Widget>[];

    for (final dataSelection in widget.dataSelections) {
      final bounded = dataSelection.bound(to: tableRange);

      if (bounded.isNil) {
        continue;
      }
      final leftTop = getLeftTopOffset(bounded.leftTop);
      final rightBottom = getRightBottomOffset(bounded.rightBottom);

      final defaultBorderSide =
          dataSelection.style?.borderSide ?? const SelectionBorderSide.none();
      final backgroundColor = dataSelection.style?.backgroundColor;

      final renderData = SelectionRenderData(
        rect: Rect.fromPoints(leftTop, rightBottom),
        border: getVisibleBorder(bounded, defaultBorderSide),
        backgroundColor: backgroundColor,
      );

      children.add(SingleSelectionPainter(renderData: renderData));
    }
    return ExpandAll(
      children: children,
    );
  }
}
