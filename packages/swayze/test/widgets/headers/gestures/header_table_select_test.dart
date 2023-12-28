import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/controller.dart';

import '../../../test_utils/create_swayze_controller.dart';
import '../../../test_utils/create_table_data.dart';
import '../../../test_utils/create_test_victim.dart';
import '../../../test_utils/fonts.dart';
import '../../../test_utils/get_cell_offset.dart';

void main() async {
  await loadFonts();

  group('Header gesture detector', () {
    group('table select button', () {
      testWidgets('default behavior', (tester) async {
        final verticalScrollController = ScrollController();
        final controller = createSwayzeController(
          tableDataController: createTableController(
            tableColumnCount: 5,
            tableRowCount: 5,
          ),
        );

        await tester.pumpWidget(
          TestSwayzeVictim(
            verticalScrollController: verticalScrollController,
            tables: [
              TestTableWrapper(
                verticalScrollController: verticalScrollController,
                swayzeController: controller,
              ),
            ],
          ),
        );

        await tester.tapAt(getCellOffset(tester, column: 1, row: 1));
        await tester.pumpAndSettle();

        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        expect(
          controller.selection.userSelectionState.selections.first,
          isA<TableUserSelectionModel>(),
        );
      });
    });
  });
}
