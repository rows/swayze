import 'package:flutter/material.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/src/core/config/config.dart';
import 'package:swayze/src/core/style/style.dart';
import 'package:swayze/src/widgets/internal_scope.dart';

import 'create_cell_delegate.dart';
import 'create_cells_controller.dart';
import 'create_selection_controller.dart';
import 'create_swayze_controller.dart';
import 'create_table_data.dart';

final testStyle = SwayzeStyle.defaultSwayzeStyle.copyWith(
  userSelectionStyle: SelectionStyle.semiTransparent(color: Colors.amberAccent),
  headerTextStyle: const TextStyle(
    fontSize: 12,
    fontFamily: 'normal',
  ),
);

Widget wrapWithScope(
  Widget widget, {
  FocusNode? focusNode,
  SwayzeController? controller,
  SwayzeTableDataController? tableDataController,
  SwayzeCellsController? cellsController,
}) {
  return DefaultTextStyle(
    style: const TextStyle(
      fontSize: 12,
      color: Color(0xFF000000),
      fontFamily: 'normal',
    ),
    child: InternalScopeProvider(
      style: testStyle,
      child: widget,
      controller: controller ??
          TestSwayzeController(
            tableDataController: tableDataController ?? createTableController(),
            cellsController: cellsController ?? createCellsController(),
            selection: createSelectionsController(),
          ),
      cellDelegate: TestCellDelegate(),
      config: const SwayzeConfig(),
    ),
  );
}
