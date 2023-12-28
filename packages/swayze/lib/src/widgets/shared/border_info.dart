import 'package:flutter/material.dart';

class BorderInfo {
  final BorderSide cellBorderSide;
  final BorderSide frozenBorderSide;
  bool isOnAFrozenRowsArea;
  bool isOnAFrozenColumnsArea;

  BorderInfo({
    required this.cellBorderSide,
    required this.frozenBorderSide,
    this.isOnAFrozenRowsArea = false,
    this.isOnAFrozenColumnsArea = false,
  });
}
