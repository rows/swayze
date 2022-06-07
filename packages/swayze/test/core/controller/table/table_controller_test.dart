import 'package:flutter/rendering.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

import '../../../test_utils/create_swayze_controller.dart';

class _MockSwayzeSelectionController extends Mock
    implements SwayzeSelectionController {
  @override
  UserSelectionState get userSelectionState => UserSelectionState.initial;

  @override
  Iterable<Selection> get dataSelections => [];
}

class _MockSwayzeController extends Mock implements SwayzeController {
  @override
  final selection = _MockSwayzeSelectionController();
}

Future<void> addUserSelection(
  SwayzeSelectionController selectionController,
  UserSelectionModel selection,
) async {
  selectionController.updateUserSelections((previousState) {
    return previousState.addSelection(selection);
  });

  await Future<void>.delayed(const Duration());
}

void main() {
  test('table controller initial data', () {
    final tableDataController = SwayzeTableDataController(
      parent: _MockSwayzeController(),
      id: 'dada',
      columnCount: 3,
      rowCount: 4,
      frozenColumns: 1,
      frozenRows: 2,
      columns: [
        const SwayzeHeaderData(
          index: 1,
          extent: 44,
          hidden: false,
        ),
        const SwayzeHeaderData(
          index: 2,
          extent: 33,
          hidden: false,
        ),
      ],
      rows: [
        const SwayzeHeaderData(
          index: 2,
          extent: 44,
          hidden: false,
        ),
        const SwayzeHeaderData(
          index: 3,
          extent: 33,
          hidden: false,
        ),
      ],
    );

    expect(tableDataController.id, equals('dada'));
    expect(tableDataController.columns.value.count, equals(3));
    expect(tableDataController.columns.value.frozenCount, equals(1));
    expect(
      tableDataController.columns.value.defaultHeaderExtent,
      equals(120.0),
    );
    expect(tableDataController.rows.value.count, equals(4));
    expect(tableDataController.rows.value.frozenCount, equals(2));
    expect(tableDataController.rows.value.defaultHeaderExtent, equals(33.0));
    expect(
      tableDataController.tableRange,
      Range2D.fromLTWH(
        const IntVector2.symmetric(0),
        const IntVector2(3, 4),
      ),
    );
  });

  group('header controller', () {
    test('update state', () {
      final tableDataController = SwayzeTableDataController(
        parent: _MockSwayzeController(),
        id: 'dada',
        columnCount: 3,
        rowCount: 4,
        frozenColumns: 1,
        frozenRows: 2,
        columns: [
          const SwayzeHeaderData(
            index: 1,
            extent: 44,
            hidden: false,
          ),
          const SwayzeHeaderData(
            index: 2,
            extent: 33,
            hidden: false,
          ),
        ],
        rows: [
          const SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
          const SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
        ],
      );

      var countColumnsUpdates = 0;
      tableDataController.columns.addListener(() => countColumnsUpdates++);

      var countRowsUpdates = 0;
      tableDataController.rows.addListener(() => countRowsUpdates++);

      var countBothUpdates = 0;
      tableDataController.addListener(() => countBothUpdates++);

      tableDataController.columns.updateState(
        (previousState) => previousState.copyWith(count: 12),
      );
      tableDataController.rows.updateState(
        (previousState) => previousState.copyWith(count: 14),
      );

      expect(countColumnsUpdates, 1);
      expect(countRowsUpdates, 1);
      expect(countBothUpdates, 2);
    });
  });

  group('when selection changes and table size should be updated', () {
    final _kTestDefaultTableRange = Range2D.fromLTWH(
      const IntVector2.symmetric(0),
      const IntVector2(5, 5),
    );

    test('should expand table due to CellUserSelectionModel', () async {
      final parent = createSwayzeController();
      final tableDataController = SwayzeTableDataController(
        parent: parent,
        id: 'dada',
        columnCount: 5,
        rowCount: 5,
        frozenColumns: 1,
        frozenRows: 2,
        columns: [],
        rows: [],
      );

      expect(tableDataController.tableRange, _kTestDefaultTableRange);

      await addUserSelection(
        parent.selection,
        CellUserSelectionModel.fromAnchorFocus(
          anchor: const IntVector2(15, 16),
          focus: const IntVector2(17, 18),
        ),
      );

      expect(
        tableDataController.tableRange,
        Range2D.fromLTWH(
          const IntVector2.symmetric(0),
          const IntVector2(18, 19),
        ),
      );
    });

    test('should expand table due to HeaderUserSelectionModel', () async {
      final parent = createSwayzeController();
      final tableDataController = SwayzeTableDataController(
        parent: parent,
        id: 'dada',
        columnCount: 5,
        rowCount: 5,
        frozenColumns: 1,
        frozenRows: 2,
        columns: [],
        rows: [],
      );

      expect(tableDataController.tableRange, _kTestDefaultTableRange);

      await addUserSelection(
        parent.selection,
        HeaderUserSelectionModel.fromAnchorFocus(
          axis: Axis.horizontal,
          anchor: 14,
          focus: 18,
        ),
      );

      expect(
        tableDataController.tableRange,
        Range2D.fromLTWH(
          const IntVector2.symmetric(0),
          const IntVector2(19, 5),
        ),
      );

      await addUserSelection(
        parent.selection,
        HeaderUserSelectionModel.fromAnchorFocus(
          axis: Axis.vertical,
          anchor: 7,
          focus: 9,
        ),
      );

      expect(
        tableDataController.tableRange,
        Range2D.fromLTWH(
          const IntVector2.symmetric(0),
          const IntVector2(19, 10),
        ),
      );
    });

    test(
      'should not expand for TableUserSelectionModel with anchor within bounds',
      () async {
        final parent = createSwayzeController();
        final tableDataController = SwayzeTableDataController(
          parent: parent,
          id: 'dada',
          columnCount: 5,
          rowCount: 5,
          frozenColumns: 1,
          frozenRows: 2,
          columns: [],
          rows: [],
        );

        expect(tableDataController.tableRange, _kTestDefaultTableRange);

        await addUserSelection(
          parent.selection,
          TableUserSelectionModel.fromSelectionModel(
            CellUserSelectionModel.fromAnchorFocus(
              anchor: const IntVector2(1, 1),
              focus: const IntVector2(2, 2),
            ),
          ),
        );

        expect(tableDataController.tableRange, _kTestDefaultTableRange);
      },
    );

    group('elastic grid', () {
      test('should not expand table beyond elastic limits', () async {
        final parent = createSwayzeController();
        final tableDataController = SwayzeTableDataController(
          parent: parent,
          id: 'id',
          columnCount: 5,
          rowCount: 5,
          frozenColumns: 1,
          frozenRows: 2,
          columns: [],
          rows: [],
          maxElasticColumns: 10,
          maxElasticRows: 10,
        );

        expect(tableDataController.tableRange, _kTestDefaultTableRange);

        await addUserSelection(
          parent.selection,
          CellUserSelectionModel.fromAnchorFocus(
            anchor: const IntVector2(15, 16),
            focus: const IntVector2(17, 18),
          ),
        );

        expect(
          tableDataController.tableRange,
          Range2D.fromLTWH(
            const IntVector2.symmetric(0),
            const IntVector2(10, 10),
          ),
        );
      });

      test(
          'should be able to select any cell of the table when elastic limits '
          'are lower than table size', () async {
        final parent = createSwayzeController();
        final tableDataController = SwayzeTableDataController(
          parent: parent,
          id: 'id',
          columnCount: 5,
          rowCount: 5,
          frozenColumns: 1,
          frozenRows: 2,
          columns: [],
          rows: [],
          maxElasticColumns: 3,
          maxElasticRows: 3,
        );

        expect(tableDataController.tableRange, _kTestDefaultTableRange);

        await addUserSelection(
          parent.selection,
          CellUserSelectionModel.fromAnchorFocus(
            anchor: const IntVector2(15, 16),
            focus: const IntVector2(17, 18),
          ),
        );

        expect(
          tableDataController.tableRange,
          Range2D.fromLTWH(
            const IntVector2.symmetric(0),
            const IntVector2(5, 5),
          ),
        );
      });
    });
  });
}
