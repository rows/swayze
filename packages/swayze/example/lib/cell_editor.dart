import 'package:flutter/material.dart';
import 'package:swayze_math/swayze_math.dart';

import 'data/my_cells_controller.dart';

class CellEditor extends StatefulWidget {
  final MyCellsController cellsController;
  final IntVector2 cellCoordinate;
  final VoidCallback close;
  final BuildContext originContext;

  const CellEditor({
    Key? key,
    required this.cellCoordinate,
    required this.close,
    required this.cellsController,
    required this.originContext,
  }) : super(key: key);

  @override
  State<CellEditor> createState() => _CellEditorState();
}

class _CellEditorState extends State<CellEditor> {
  late final cell =
      widget.cellsController.cellMatrixReadOnly[widget.cellCoordinate];

  late final TextEditingController textController = TextEditingController(
    text: cell?.value ?? '',
  );
  late final FocusNode focusNode = FocusNode(
    debugLabel: 'CellEditor',
  )..requestFocus();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(checkFocus);
  }

  @override
  void dispose() {
    focusNode.removeListener(checkFocus);
    super.dispose();
  }

  void checkFocus() {
    if (!focusNode.hasFocus) {
      widget.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: EditableText(
        onSubmitted: (value) {},
        controller: textController,
        focusNode: focusNode,
        cursorColor: Colors.black,
        backgroundCursorColor: Colors.grey.shade200,
        style: DefaultTextStyle.of(context).style,
      ),
    );
  }
}
