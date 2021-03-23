import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../../controller.dart';
import '../../../../core/delegates/cell_delegate.dart';
import '../../../../core/style/style.dart';
import '../../../../helpers/keyed_notifier/keyed_notifier_builder.dart';
import '../../mouse_hover/mouse_hover.dart';
import 'cell_root_painter.dart';

class Cell<CellDataType extends SwayzeCellData> extends StatefulWidget {
  final CellDataType data;
  final SwayzeStyle swayzeStyle;
  final TextDirection textDirection;
  final SwayzeSelectionController selectionsController;
  final CellDelegate<CellDataType> cellDelegate;

  const Cell({
    Key? key,
    required this.data,
    required this.swayzeStyle,
    required this.textDirection,
    required this.selectionsController,
    required this.cellDelegate,
  }) : super(key: key);

  @override
  State<Cell> createState() => _CellState<CellDataType>();
}

class _CellState<CellDataType extends SwayzeCellData>
    extends State<Cell<CellDataType>> {
  late final mouseHover = MouseHoverTableBody.of(context);

  late bool isActive =
      widget.selectionsController.userSelectionState.activeCellCoordinate ==
          widget.data.position;

  late CellLayout cellLayout;

  @override
  void initState() {
    super.initState();
    cellLayout = getCellLayout();
    final isActiveCellAware = cellLayout.isActiveCellAware;
    if (isActiveCellAware) {
      widget.selectionsController.userSelectionsListenable
          .addListener(handleSelectionChanged);
    }
  }

  @override
  void didUpdateWidget(Cell<CellDataType> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldLayout = cellLayout;
    final currentLayout = getCellLayout();
    cellLayout = currentLayout;

    final wasActiveCellAware = oldLayout.isActiveCellAware;
    final isActiveCellAware = currentLayout.isActiveCellAware;

    if (wasActiveCellAware == isActiveCellAware) {
      return;
    }

    if (wasActiveCellAware) {
      oldWidget.selectionsController.userSelectionsListenable
          .removeListener(handleSelectionChanged);
    }

    if (isActiveCellAware) {
      widget.selectionsController.userSelectionsListenable
          .addListener(handleSelectionChanged);
    }
  }

  @override
  void dispose() {
    final isActiveCellAware = cellLayout.isActiveCellAware;
    if (isActiveCellAware) {
      widget.selectionsController.userSelectionsListenable
          .removeListener(handleSelectionChanged);
    }

    super.dispose();
  }

  void handleSelectionChanged() {
    final activeCellCoordinate =
        widget.selectionsController.userSelectionState.activeCellCoordinate;
    final isActivePosition = activeCellCoordinate == widget.data.position;

    if (isActivePosition != isActive) {
      setState(() {
        isActive = isActivePosition;
      });
    }
  }

  CellLayout getCellLayout() {
    return widget.cellDelegate.getCellLayout(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    final isHoverAware = cellLayout.isHoverAware;
    final isActiveCellAware = cellLayout.isActiveCellAware;
    if (isHoverAware || isActiveCellAware) {
      return KeyedNotifierBuilder<IntVector2>(
        keyedNotifier: mouseHover,
        keyToListenTo: widget.data.position,
        builder: (context, isHover) {
          return CellRootPainter(
            cellSeparatorStrokeWidth:
                widget.swayzeStyle.cellSeparatorStrokeWidth,
            cellContent: cellLayout.buildCell(
              context,
              isHover: isHover,
              isActive: isActive,
            ),
            cellHoverWidgets: cellLayout.buildOverlayWidgets(
              context,
              isHover: isHover,
              isActive: isActive,
            ),
          );
        },
      );
    }

    return CellRootPainter(
      cellSeparatorStrokeWidth: widget.swayzeStyle.cellSeparatorStrokeWidth,
      cellContent: cellLayout.buildCell(context),
      cellHoverWidgets: cellLayout.buildOverlayWidgets(context),
    );
  }
}
