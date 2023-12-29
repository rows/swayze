import 'dart:convert';

final map = <int, String>{
  0: '''
{
  "id":"274d2509-a651-49d8-88b0-e72e0aaa63b3",
  "name":"Styles",
  "columns":6,
  "rows":6,
  "columnStyles":[{"position":1,"size":162,"__typename":"DimensionStyle"},{"position":4,"size":283,"__typename":"DimensionStyle"}],
  "rowStyles":[]
}''',
  1: '''
{
  "id":"26163cb0-7c0e-11eb-b54b-d161845548b6",
  "name":"Longer table",
  "index":1,
  "columns":36,
  "rows":1060,
  "columnStyles":[{"position":0,"size":167,"__typename":"DimensionStyle"}],
  "rowStyles":[{"position":190,"size":54,"hidden":false,"__typename":"DimensionStyle"}]
}''',
};

const decoder = JsonDecoder();

/// Don't take this function seriously
Map<String, dynamic> getTableData(int index) {
  final data = map[index]!;
  final dynamic dec = decoder.convert(data);
  return dec as Map<String, dynamic>;
}
