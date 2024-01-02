import 'package:cached_value/cached_value.dart';
import 'package:flutter/material.dart';

import '../../../controller.dart';
import '../internal_scope.dart';

class HeaderTableSelect extends StatefulWidget {
  const HeaderTableSelect({
    super.key,
  });

  @override
  State<HeaderTableSelect> createState() => _HeaderTableSelectState();
}

class _HeaderTableSelectState extends State<HeaderTableSelect> {
  late final internalScope = InternalScope.of(context);
  late final style = internalScope.style;
  late final controller = internalScope.controller;
  late final selectionController = controller.selection;

  bool _isTableSelected = false;
  bool _isHover = false;

  @override
  void initState() {
    super.initState();
    selectionController.userSelectionsListenable.addListener(
      onSelectionsChange,
    );
  }

  @override
  void dispose() {
    selectionController.userSelectionsListenable.removeListener(
      onSelectionsChange,
    );
    super.dispose();
  }

  void onSelectionsChange() {
    final selections = selectionController.userSelectionState.selections;
    final isTableSelected = selections.first is TableUserSelectionModel;
    if (isTableSelected != _isTableSelected) {
      setState(() {
        _isTableSelected = isTableSelected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => setState(() => _isHover = false),
      onEnter: (_) => setState(() => _isHover = true),
      child: GestureDetector(
        onTap: () {
          Focus.of(context).requestFocus();
          selectionController.updateUserSelections(
            (state) => state.resetSelectionsToTableSelection(),
          );
        },
        child: ColoredBox(
          color: style.tableSelectStyle.backgroundFillColor,
          child: CustomPaint(
            painter: _TrianglePainter(
              color: (_isTableSelected || _isHover)
                  ? style.tableSelectStyle.selectedForegroundColor
                  : style.tableSelectStyle.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  CachedValue<Paint> paintCache(Color color) => CachedValue(
        () {
          return Paint()
            ..color = color
            ..strokeWidth = 0
            ..style = PaintingStyle.fill;
        },
      ).withDependency<Color?>(() => color);

  _TrianglePainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = paintCache(color);
    final right = size.width - 1;
    final bottom = size.height - 1;
    final triangle = Path()
      ..moveTo(right, 3)
      ..lineTo(right, bottom)
      ..lineTo(2, bottom)
      ..lineTo(right, 2);

    canvas.save();
    canvas.drawPath(triangle, paint.value);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
