import 'package:flutter/material.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import 'create_cell_delegate.dart';
import 'create_swayze_controller.dart';

final myStyle = SwayzeStyle.defaultSwayzeStyle.copyWith(
  userSelectionStyle: SelectionStyle.semiTransparent(color: Colors.amberAccent),
  headerTextStyle: const TextStyle(
    fontSize: 12,
    fontFamily: 'normal',
  ),
);

Widget defaultCellEditorBuilder(
  BuildContext context,
  IntVector2 coordinate,
  VoidCallback close, {
  required bool overlapCell,
  required bool overlapTable,
  String? initialText,
}) {
  return const SizedBox.shrink();
}

class TestTableWrapper extends StatefulWidget {
  final bool autofocus;

  final ScrollController verticalScrollController;

  final SwayzeController? swayzeController;
  final InlineEditorBuilder? editorBuilder;
  final SwayzeConfig? config;

  final Widget? header;

  TestTableWrapper({
    Key? key,
    ScrollController? verticalScrollController,
    bool? autofocus,
    this.header,
    this.swayzeController,
    this.editorBuilder,
    this.config,
  })  : verticalScrollController =
            verticalScrollController ?? ScrollController(),
        autofocus = autofocus ?? false,
        super(key: key);

  @override
  _TestTableWrapperState createState() => _TestTableWrapperState();
}

class _TestTableWrapperState extends State<TestTableWrapper> {
  late final SwayzeController controller =
      widget.swayzeController ?? createSwayzeController();
  late FocusNode myFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return SliverSwayzeTable(
      cellDelegate: TestCellDelegate(),
      focusNode: myFocusNode,
      autofocus: widget.autofocus,
      controller: controller,
      style: myStyle,
      stickyHeader: widget.header,
      stickyHeaderSize: 70.0,
      inlineEditorBuilder: widget.editorBuilder ?? defaultCellEditorBuilder,
      verticalScrollController: widget.verticalScrollController,
      config: widget.config,
    );
  }
}

class TestSwayzeVictim extends StatelessWidget {
  final List<TestTableWrapper> tables;
  final ScrollController verticalScrollController;

  TestSwayzeVictim({
    Key? key,
    required this.tables,
    ScrollController? verticalScrollController,
  })  : verticalScrollController =
            verticalScrollController ?? ScrollController(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'normal',
      ),
      home: Scaffold(
        body: Container(
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF000000),
              fontFamily: 'normal',
            ),
            child: CustomScrollView(
              controller: verticalScrollController,
              slivers: tables,
            ),
          ),
          color: const Color(0xffffffff),
        ),
      ),
    );
  }
}
