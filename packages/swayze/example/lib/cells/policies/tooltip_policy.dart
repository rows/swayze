import 'package:flutter/material.dart';

import '../../../data/cell_data.dart';
import 'painting_policies.dart';

final kTooltipCellHover = CellOverlayPolicy<MyCellData>(
  checkEligibility: (cellData) => true,
  builder: (
    context,
    data, {
    bool? isHover,
    bool? isActive,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Tooltip(
          message: '''
There is content on cell ${data.position.dx}:${data.position.dy}''',
          preferBelow: true,
          verticalOffset: constraints.minHeight / 2,
          child: const SizedBox.shrink(),
        );
      },
    );
  },
);
