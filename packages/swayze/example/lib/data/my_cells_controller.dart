import 'package:swayze/controller.dart';

import 'cell_data.dart';

MyCellData cellParser(dynamic json) => MyCellData.fromJson(
      json as Map<String, dynamic>,
    );

class MyCellsController extends SwayzeCellsController<MyCellData> {
  MyCellsController({
    required Iterable<dynamic> initialCells,
    required SwayzeController parent,
  }) : super(
          parent: parent,
          initialRawCells: initialCells,
          cellParser: cellParser,
        );
}
