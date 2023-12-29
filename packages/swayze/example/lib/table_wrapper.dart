import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:swayze/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import 'cell_editor.dart';
import 'cells/delegate.dart';
import 'cells/policies/tooltip_policy.dart';
import 'data/cell_data.dart';
import 'data/my_swayze_controller.dart';

class SliverTableWrapper extends StatefulWidget {
  final int tableIndex;
  final ScrollController verticalScrollController;

  const SliverTableWrapper({
    Key? key,
    required this.tableIndex,
    required this.verticalScrollController,
  }) : super(key: key);

  @override
  _SliverTableWrapperState createState() => _SliverTableWrapperState();
}

class _SliverTableWrapperState extends State<SliverTableWrapper> {
  late final FocusNode myFocusNode = FocusNode(
    debugLabel: 'SliverTableWrapper',
  );
  late final swayzeController = MySwayzeController(
    tableIndex: widget.tableIndex,
  );

  @override
  void dispose() {
    swayzeController.dispose();
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverSwayzeTable<MyCellData>(
      key: ValueKey(swayzeController.tableDataController.id),
      cellDelegate: MyCellDelegate<MyCellData>(
        overlayPolicies: [kTooltipCellHover],
      ),
      focusNode: myFocusNode,
      autofocus: widget.tableIndex == 0,
      controller: swayzeController,
      wrapTableBody: (context, viewportContext, child) {
        return TableBodyWrapper(
          viewportContext: viewportContext,
          child: child,
        );
      },
      inlineEditorBuilder: (
        BuildContext context,
        IntVector2 coordinate,
        VoidCallback close, {
        required bool overlapCell,
        required bool overlapTable,
        String? initialText,
      }) {
        return CellEditor(
          cellsController: swayzeController.cellsController,
          cellCoordinate: coordinate,
          close: close,
          originContext: context,
        );
      },
      verticalScrollController: widget.verticalScrollController,
      stickyHeaderSize: 60,
      stickyHeader: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: _TableTitle(
          title: swayzeController.tableDataController.name,
        ),
      ),
    );
  }
}

class _TableTitle extends StatelessWidget {
  final String title;

  const _TableTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class TableBodyWrapper extends StatelessWidget {
  final ViewportContext viewportContext;
  final Widget child;

  const TableBodyWrapper({
    Key? key,
    required this.viewportContext,
    required this.child,
  }) : super(key: key);

  void onHover(PointerHoverEvent event) {
    final x = viewportContext.pixelToPosition(
      event.localPosition.dx,
      Axis.horizontal,
    );

    final y = viewportContext.pixelToPosition(
      event.localPosition.dy,
      Axis.vertical,
    );
    print('Hovering cell: ${IntVector2(x.position, y.position)}');
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: onHover,
      child: child,
    );
  }
}
