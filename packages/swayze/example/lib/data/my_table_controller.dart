import 'package:swayze/controller.dart';

class MyTableController extends SwayzeTableDataController {
  final String name;

  MyTableController._({
    required this.name,
    required SwayzeController parent,
    required String id,
    required int columnCount,
    required int rowCount,
    required Iterable<SwayzeHeaderData> columns,
    required Iterable<SwayzeHeaderData> rows,
  }) : super(
          parent: parent,
          id: id,
          columnCount: columnCount,
          rowCount: rowCount,
          columns: columns,
          rows: rows,
          frozenColumns: 0,
          frozenRows: 0,
        );

  factory MyTableController.fromJson(
    Map<String, dynamic> json, {
    required SwayzeController parent,
  }) {
    final id = json['id'] as String;
    final name = json['name'] as String;

    final columnCount = json['columns'] as int;
    final rowCount = json['rows'] as int;

    final columns =
        (json['columnStyles'] as List<dynamic>).map((dynamic headerJson) {
      return MyHeaderData.fromJson(headerJson as Map<String, dynamic>);
    });

    final rows = (json['rowStyles'] as List<dynamic>).map((dynamic headerJson) {
      return MyHeaderData.fromJson(headerJson as Map<String, dynamic>);
    });

    return MyTableController._(
      parent: parent,
      id: id,
      name: name,
      columnCount: columnCount,
      rowCount: rowCount,
      columns: columns,
      rows: rows,
    );
  }

  // example of custom operation
  void insertRows(int howMany) {
    rows.updateState(
      (previousState) =>
          previousState.copyWith(count: previousState.count + howMany),
    );
  }
}

class MyHeaderData extends SwayzeHeaderData {
  const MyHeaderData({
    required int index,
    required double? extent,
    required bool hidden,
  }) : super(
          index: index,
          extent: extent,
          hidden: hidden,
        );

  factory MyHeaderData.fromJson(Map<String, dynamic> json) {
    final index = json['position'] as int;
    final extent = json['size'] as int?;
    final hidden = (json['hidden'] as bool?) ?? false;
    return MyHeaderData(
      index: index,
      extent: extent?.toDouble(),
      hidden: hidden,
    );
  }
}
