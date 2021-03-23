import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/src/widgets/headers/header.dart';
import 'package:swayze/src/widgets/headers/header_item.dart';
import 'package:swayze/src/widgets/table.dart';

import 'create_cells_controller.dart';
import 'type_of.dart';

Offset getCellOffset(
  WidgetTester tester, {
  int tableIndex = 0,
  required int column,
  required int row,
}) {
  final tableHeaders = find.descendant(
    of: find.byType(typeOf<SliverSwayzeTable<TestCellData>>()).at(tableIndex),
    matching: find.byType(Header),
  );
  final columnHeaders = find.descendant(
    of: tableHeaders.at(0),
    matching: find.byType(HeaderItem),
  );
  final rowHeaders = find.descendant(
    of: tableHeaders.at(1),
    matching: find.byType(HeaderItem),
  );
  return Offset(
    tester.getCenter(columnHeaders.at(column)).dx,
    tester.getCenter(rowHeaders.at(row)).dy,
  );
}
