import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';

class TestSwayzeSelectionController extends SwayzeSelectionController {
  TestSwayzeSelectionController(
    this.dataSelectionsValueListenable,
  ) : super();

  @override
  final ValueNotifier<BuiltList<Selection>> dataSelectionsValueListenable;
}

TestSwayzeSelectionController createSelectionsController({
  ValueNotifier<BuiltList<Selection>>? dataSelectionsValueListenable,
}) {
  return TestSwayzeSelectionController(
    dataSelectionsValueListenable ??
        ValueNotifier(
          BuiltList.from(<Selection>[]),
        ),
  );
}

class TestDataSelection extends Selection {
  @override
  final int? left;
  @override
  final int? top;
  @override
  final int? right;
  @override
  final int? bottom;
  @override
  final SelectionStyle style;

  @override
  IntVector2 get focusCoordinate => IntVector2(left ?? 0, top ?? 0);

  @override
  IntVector2 get anchorCoordinate => IntVector2(right ?? 10, bottom ?? 10);

  TestDataSelection({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required Color color,
  }) : style = SelectionStyle.dashedBorderOnly(color: color);
}

class TestDataSelectionNotifier extends ValueNotifier<BuiltList<Selection>> {
  TestDataSelectionNotifier(List<Selection> initial)
      : super(BuiltList.from(initial));
}
