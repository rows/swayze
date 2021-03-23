import 'package:swayze/controller.dart';

import 'create_cells_controller.dart';
import 'create_selection_controller.dart';
import 'create_table_data.dart';

class TestSwayzeController extends SwayzeController {
  @override
  late final SwayzeCellsController cellsController;

  @override
  final SwayzeTableDataController tableDataController;

  @override
  final SwayzeSelectionController selection;

  @override
  late final SwayzeScrollController scroll;

  TestSwayzeController({
    SwayzeCellsController? cellsController,
    required this.tableDataController,
    required this.selection,
    SwayzeScrollController? scroll,
  }) {
    this.cellsController = cellsController ??
        createCellsController(
          parent: this,
          cells: [],
        );
    this.scroll = scroll ?? SwayzeScrollController(this);
  }
}

TestSwayzeController createSwayzeController({
  SwayzeCellsController? cellsController,
  SwayzeTableDataController? tableDataController,
  SwayzeSelectionController? selectionController,
  SwayzeScrollController? scrollController,
}) {
  final controller = TestSwayzeController(
    tableDataController: tableDataController ?? createTableController(),
    cellsController: cellsController,
    selection: selectionController ?? createSelectionsController(),
    scroll: scrollController,
  );

  return controller;
}
