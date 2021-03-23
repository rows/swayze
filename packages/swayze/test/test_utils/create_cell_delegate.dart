import 'package:flutter/widgets.dart';
import 'package:swayze/delegates.dart';

import 'create_cells_controller.dart';

class TestCellDelegate extends CellDelegate<TestCellData> {
  @override
  CellLayout getCellLayout(
    TestCellData data,
  ) {
    return TestCellLayout(data);
  }
}

class TestCellLayout extends CellLayout {
  final TestCellData data;

  TestCellLayout(this.data);

  @override
  Widget buildCell(
    BuildContext context, {
    bool isHover = false,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 6.0,
      ),
      child: Align(
        alignment: data.contentAlignment,
        child: Text(
          data.value ?? '',
          textDirection: TextDirection.ltr,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
  }

  @override
  Iterable<Widget> buildOverlayWidgets(
    BuildContext context, {
    bool isHover = false,
    bool isActive = false,
  }) {
    return [];
  }

  @override
  bool get isActiveCellAware => false;

  @override
  bool get isHoverAware => false;
}
