import 'package:flutter/widgets.dart';

@immutable
abstract class CellDelegate<CellDataType> {
  CellLayout getCellLayout(CellDataType data);
}

@immutable
abstract class CellLayout {
  bool get isActiveCellAware;

  bool get isHoverAware;

  Widget buildCell(
    BuildContext context, {
    bool isHover = false,
    bool isActive = false,
  });

  Iterable<Widget> buildOverlayWidgets(
    BuildContext context, {
    bool isHover = false,
    bool isActive = false,
  });

  // TODO(renancaraujo): implement shouldRebuild
  // bool shouldRebuild(covariant CellLayout oldLayout);
}
