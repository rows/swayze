import 'dart:convert';

final map = <int, String>{
  0: '''
[
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-0-0",
      "position":{ "x":0, "y":0 },
      "value":"Bold",
      "type":"TEXT",
      "style":{
         "isBold":true
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-0-1",
      "position":{ "x":0, "y":1 },
      "value":"Italic",
      "type":"TEXT",
      "style":{
         "isItalic":true
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-0-2",
      "position":{ "x":0, "y":2 },
      "value":"Underline",
      "type":"TEXT",
      "style":{
         "isUnderline":true
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-0-3",
      "position":{ "x":0, "y":3 },
      "value":"Background color",
      "type":"TEXT",
      "style":{
         "fontColor":"#2c2c2c",
         "backgroundColor":"#ab5cb3"
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-1-0",
      "position":{ "x":1, "y":0 },
      "value":"Align left",
      "type":"TEXT",
      "style":{
         "alignment":"LEFT"
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-1-1",
      "position":{ "x":1, "y":1 },
      "value":"Align right",
      "type":"TEXT",
      "style":{
         "alignment":"RIGHT"
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-1-2",
      "position":{ "x":1, "y":2 },
      "value":"Align center",
      "type":"TEXT",
      "style":{
         "alignment":"CENTER"
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-1-3",
      "position":{ "x":1, "y":3 },
      "value":"Align left Align left Align left Align left Align left",
      "type":"TEXT",
      "style":{
         "alignment":"LEFT"
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-1-4",
      "position":{ "x":1, "y":4 },
      "value":"Align right Align right Align right Align right",
      "type":"TEXT",
      "style":{
         "alignment":"RIGHT"
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-1-5",
      "position":{ "x":1, "y":5 },
      "value":"Align center Align center Align center Align center Align center Align center ",
      "type":"TEXT",
      "style":{
         "alignment":"CENTER"
      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-2-0",
      "position":{ "x":2, "y":0 },
      "value":"✅ ",
      "type":"TEXT",
      "style":{

      }
   },
   {
      "id":"b49a32df-3605-4397-9984-d7ab62afd143-2-1",
      "position":{ "x":2, "y":1 },
      "value":"❌",
      "type":"TEXT",
      "style":{
         "alignment":"RIGHT"
      }
   }
]''',
  1: '''
[
  {
      "id":"2b45b403-caf9-4fb5-83b7-0dae2b7f6228-0-0",
      "position":{ "x":0, "y":0 },
      "value":"Red",
      "type":"TEXT",
      "style":{
        "backgroundColor":"#D12229",
        "fontColor": "#FFFFFF"
      }
  },
  {
      "id":"2b45b403-caf9-4fb5-83b7-0dae2b7f6228-0-1",
      "position":{ "x":0, "y":1 },
      "value":"Orange",
      "type":"TEXT",
      "style":{
        "backgroundColor":"#F68A1E",
        "fontColor": "#FFFFFF"
      }
  },
  {
      "id":"2b45b403-caf9-4fb5-83b7-0dae2b7f6228-0-2",
      "position":{ "x":0, "y":2 },
      "value":"Yellow",
      "type":"TEXT",
      "style":{
        "isBold":false,
        "backgroundColor":"#FDE01A",
        "fontColor": "#FFFFFF"
      }
  },
  {
      "id":"2b45b403-caf9-4fb5-83b7-0dae2b7f6228-0-3",
      "position":{ "x":0, "y":3 },
      "value":"Green",
      "type":"TEXT",
      "style":{
        "isBold":false,
        "backgroundColor":"#007940",
        "fontColor": "#FFFFFF"
      }
  },
  {
      "id":"2b45b403-caf9-4fb5-83b7-0dae2b7f6228-0-3",
      "position":{ "x":0, "y":4 },
      "value":"Indigo",
      "type":"TEXT",
      "style":{
        "isBold":false,
        "backgroundColor":"#24408E",
        "fontColor": "#FFFFFF"
      }
  },
  {
      "id":"2b45b403-caf9-4fb5-83b7-0dae2b7f6228-0-3",
      "position":{ "x":0, "y":5 },
      "value":"Violet",
      "type":"TEXT",
      "style":{
        "isBold":false,
        "backgroundColor":"#732982",
        "fontColor": "#FFFFFF"
      }
  }
]
  ''',
};

const decoder = JsonDecoder();

/// Don't take this function seriously
List<dynamic> getCellsData(int index) {
  final data = map[index]!;
  final dynamic dec = decoder.convert(data);
  return dec as List<dynamic>;
}
