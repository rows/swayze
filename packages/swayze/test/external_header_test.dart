import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze_math/swayze_math.dart';

import 'test_utils/create_cells_controller.dart';
import 'test_utils/create_swayze_controller.dart';
import 'test_utils/create_table_data.dart';
import 'test_utils/create_test_victim.dart';
import 'test_utils/fonts.dart';

void main() async {
  await loadFonts();

  testWidgets('External headers', (tester) async {
    final table = TestTableWrapper(
      key: const ValueKey('TestTableKey1'),
      swayzeController: createSwayzeController(
        cellsController: createCellsController(
          cells: [
            TestCellData(
              position: const IntVector2(0, 0),
              value: 'Table1 Cell 0,0',
            ),
          ],
        ),
        tableDataController: createTableController(
          id: 'TestTableKey1',
          tableRowCount: 12,
        ),
      ),
      header: Container(
        color: const Color(0xFF00FF00),
        child: const Text('I am a header'),
      ),
    );
    await tester.pumpWidget(
      TestSwayzeVictim(
        tables: [table],
      ),
    );
    await expectLater(
      find.byType(TestSwayzeVictim),
      matchesGoldenFile('goldens/external-headers-1.png'),
    );
  });
}
