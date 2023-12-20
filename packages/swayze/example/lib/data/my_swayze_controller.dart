import 'package:swayze/controller.dart';

import '../backend/fake_cells_backend.dart' as cells_backend;
import '../backend/fake_table_backend.dart' as table_backend;
import 'my_cells_controller.dart';
import 'my_table_controller.dart';

class MySwayzeController extends SwayzeController {
  @override
  late final MyTableController tableDataController;

  @override
  late final MyCellsController cellsController;

  MySwayzeController({
    required int tableIndex,
  }) {
    tableDataController = MyTableController.fromJson(
      table_backend.getTableData(tableIndex),
      parent: this,
    );
    cellsController = MyCellsController(
      initialCells: cells_backend.getCellsData(tableIndex),
      parent: this,
    );
  }
}
