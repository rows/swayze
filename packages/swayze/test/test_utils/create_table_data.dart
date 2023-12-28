import 'package:mocktail/mocktail.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/widgets.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class _MockSwayzeSelectionController extends Mock
    implements SwayzeSelectionController {}

class _MockSwayzeController extends Mock implements SwayzeController {
  @override
  final selection = _MockSwayzeSelectionController();
}

SwayzeTableDataController createTableController({
  String? id,
  int tableRowCount = 3,
  int tableColumnCount = 3,
  Map<int, double> customColumnSizes = const {},
  Map<int, double> customRowSizes = const {},
  int frozenColumns = 0,
  int frozenRows = 0,
  double startingCellWidth = kDefaultCellWidth,
  double startingCellHeight = kDefaultCellHeight,
  double Function() columnHeaderHeight =
      SwayzeTableDataController.defaultColumnHeaderHeight,
  double Function(Range) rowHeaderWidthForRange =
      SwayzeTableDataController.defaultRowHeaderWidthForRange,
}) {
  final columns = <SwayzeHeaderData>[];

  customColumnSizes.forEach((key, value) {
    columns.add(SwayzeHeaderData(index: key, extent: value, hidden: false));
  });

  final rows = <SwayzeHeaderData>[];

  customRowSizes.forEach((key, value) {
    rows.add(SwayzeHeaderData(index: key, extent: value, hidden: false));
  });

  return SwayzeTableDataController(
    parent: _MockSwayzeController(),
    id: id ?? _uuid.v4(),
    columnCount: tableColumnCount,
    rowCount: tableRowCount,
    columns: columns,
    rows: rows,
    frozenColumns: frozenColumns,
    frozenRows: frozenRows,
    startingCellHeight: startingCellHeight,
    startingCellWidth: startingCellWidth,
    columnHeaderHeight: columnHeaderHeight,
    rowHeaderWidthForRange: rowHeaderWidthForRange,
  );
}
