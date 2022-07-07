import 'package:flutter/material.dart';

import 'table_wrapper.dart';

class DummyIntent extends Intent {
  const DummyIntent();
}

void main() {
  runApp(EditorTableTestBedApp());
}

class EditorTableTestBedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MultiViewPage(),
      ),
    );
  }
}

class MultiViewPage extends StatefulWidget {
  @override
  _MultiViewPageState createState() => _MultiViewPageState();
}

class _MultiViewPageState extends State<MultiViewPage> {
  late final verticalScrollController = ScrollController();

  @override
  void dispose() {
    verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: verticalScrollController,
      slivers: [
        SliverTableWrapper(
          tableIndex: 0,
          verticalScrollController: verticalScrollController,
        ),
        SliverTableWrapper(
          tableIndex: 1,
          verticalScrollController: verticalScrollController,
        ),
      ],
    );
  }
}
