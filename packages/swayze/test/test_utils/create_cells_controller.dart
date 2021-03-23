import 'package:flutter/src/painting/alignment.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class _MockSwayzeController extends Mock implements SwayzeController {}

class TestCellData extends SwayzeCellData {
  final String? value;

  @override
  final Alignment contentAlignment;

  TestCellData({
    String? id,
    required IntVector2 position,
    this.value,
    this.contentAlignment = Alignment.centerLeft,
  }) : super(
          id: id ?? _uuid.v4(),
          position: position,
        );

  @override
  bool get hasVisibleContent => value?.isNotEmpty == true;
}

class TestCellController extends SwayzeCellsController<TestCellData> {
  TestCellController(
    Iterable<TestCellData> initialRawCells, {
    SwayzeController? parent,
  }) : super(
          parent: parent ?? _MockSwayzeController(),
          cellParser: (dynamic cell) => cell as TestCellData,
          initialRawCells: initialRawCells,
        );
}

SwayzeCellsController createCellsController({
  SwayzeController? parent,
  List<TestCellData>? cells,
}) =>
    TestCellController(
      cells ?? [],
      parent: parent,
    );
