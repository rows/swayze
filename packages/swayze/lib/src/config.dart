import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:swayze_math/swayze_math.dart';

/// The height of the column headers.
const kColumnHeaderHeight = 24.0;

/// The starting width of row headers.
///
/// This is incremented by [headerWidthForRange] in order to show large numbers
const kRowHeaderWidth = 24.0;

/// Get the width of the rows headers given the actual [range], this adjusts the
/// size of the header to show larger numbers.
///
/// The starting value is [kRowHeaderWidth].
double headerWidthForRange(Range range) {
  final length = range.end.toString().length;
  final digitOverflow = math.max(length - 3, 0);
  return kRowHeaderWidth + digitOverflow * 8;
}

const kDefaultCellWidth = 120.0;
const kDefaultCellHeight = 33.0;

const kMinCellWidth = 30.0;

const kDefaultScrollAnimationDuration = Duration(milliseconds: 50);
const kDefaultScrollAnimationCurve = Curves.easeOut;
