import 'dart:collection';

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Defines a continuous range of integers from [start] to [end].
///
/// [end] is non inclusive
@immutable
class Range {
  final int start;
  final int end;

  const Range(this.start, this.end)
      : assert(start <= end, 'Start: $start End: $end');

  static const Range zero = Range(0, 0);

  /// If this is a range with no elements
  bool get isNil => start == end;

  /// If this is a range with any element
  bool get isNotNil => !isNil;

  Iterable<int> get iterable => RangeIterable._(this);

  /// Create a identical range
  Range clone() {
    return Range(start, end);
  }

  /// Return all the elements on the this range that is not present
  /// on the [otherRange].
  ///
  /// Getting a diff of ranges is good to identify specific changes on ranges.
  RangeCompactList operator -(Range otherRange) {
    final coll = RangeCompactList();

    // leading edge
    if (end <= otherRange.start) {
      coll.add(clone());
      return coll;
    }
    if (start < otherRange.start) {
      final diffStart = start;
      final diffEnd = otherRange.start;
      coll.add(Range(diffStart, diffEnd));
    }

    // trailing edge
    if (otherRange.end <= start) {
      coll.add(clone());
      return coll;
    }
    if (otherRange.end < end) {
      final diffStart = otherRange.end;
      final diffEnd = end;
      coll.add(Range(diffStart, diffEnd));
    }
    return coll;
  }

  /// Performs a union with another range
  /// merge if overlaps
  RangeCompactList operator +(Range otherRange) {
    return RangeCompactList()
      ..add(this)
      ..add(otherRange);
  }

  /// Stretches and merges two ranges including all possible non covered spaces
  /// between them
  Range operator |(Range otherRange) {
    return Range(
      min(start, otherRange.start),
      max(end, otherRange.end),
    );
  }

  /// Gets the intersection between two ranges,
  /// range nil if they don't intersect
  Range operator &(Range otherRange) {
    final start = max(this.start, otherRange.start);
    final end = min(this.end, otherRange.end);
    if (start >= end) {
      return Range(end, end);
    }
    return Range(start, end);
  }

  /// Defines if this range overlaps [otherRange]
  bool overlaps(Range otherRange) {
    if (start > otherRange.start) {
      return otherRange.end >= start;
    }
    if (end < otherRange.end) {
      return otherRange.start <= end;
    }
    return containsRange(otherRange);
  }

  /// Verifies if a given position is contained within the range
  bool contains(Object? position) {
    if (position is! int) {
      return false;
    }

    return start <= position && end > position;
  }

  /// Defines if this range contains [otherRange] entirely
  bool containsRange(Range otherRange) {
    return start <= otherRange.start && end >= otherRange.end;
  }

  @override
  String toString() {
    return 'Range: $start -> $end';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Range &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// traditional equals doesn't work on lists.
const _kListEquality = ListEquality<Range>();

/// A list of ranges that keeps with the smallest possible size (no overlaps
/// between its members)
@immutable
class RangeCompactList extends IterableMixin<Range> implements Iterable<Range> {
  final List<Range> _ranges;

  RangeCompactList() : _ranges = [];

  RangeCompactList._(this._ranges);

  /// Adds an [newItem] to the list by merging with existing items that overlaps
  /// with it
  void add(Range newItem) {
    if (newItem.isNil) {
      return;
    }

    final flushedList = _ranges.reversed.fold<List<Range>>(
      <Range>[newItem],
      (accumulator, range) {
        final newAcc = <Range>[];

        var hasOverlapped = false;
        for (final accumulatedRange in accumulator) {
          if (range.containsRange(accumulatedRange)) {
            continue;
          }
          if (!hasOverlapped && range.overlaps(accumulatedRange)) {
            newAcc.add(accumulatedRange | range);
            hasOverlapped = true;
          } else {
            // it is guaranteed that wwe wont have two overlaps since the
            // internal collection is supposed to never have overlaps
            newAcc.add(accumulatedRange);
          }
        }
        if (!hasOverlapped) {
          newAcc.insert(0, range);
        }
        return newAcc;
      },
    );

    _ranges
      ..clear()
      ..addAll(flushedList);
  }

  RangeCompactList clone() {
    return RangeCompactList._(List.from(_ranges));
  }

  /// Union this RangeList with another range
  ///
  /// Differently from [add] this creates a new RangeList
  RangeCompactList operator +(Range otherRange) {
    return clone()..add(otherRange);
  }

  RangeCompactList operator &(Range otherRange) {
    final clampedRanges = _ranges.fold<List<Range>>(
      <Range>[],
      (acc, Range range) {
        if (!range.overlaps(range)) {
          return acc;
        }
        final intersection = otherRange & range;

        if (intersection.isNotNil) {
          acc.add(intersection);
        }

        return acc;
      },
    );
    return RangeCompactList._(clampedRanges);
  }

  @override
  int get length => _ranges.length;

  @override
  String toString() {
    return 'RangeList: ${_ranges.toString()}';
  }

  @override
  Iterator<Range> get iterator => _ranges.iterator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeCompactList &&
          runtimeType == other.runtimeType &&
          _kListEquality.equals(_ranges, other._ranges);

  @override
  int get hashCode => _ranges.hashCode;
}

@immutable
class RangeIterable with IterableMixin<int> implements Iterable<int> {
  final Range _range;

  const RangeIterable._(this._range);

  @override
  Iterator<int> get iterator => RangeIterator._(_range);

  @override
  int get length => _range.end - _range.start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeIterable &&
          runtimeType == other.runtimeType &&
          _range == other._range;

  @override
  int get hashCode => _range.hashCode;
}

/// An [int] [Iterator] that allows getting elements of a [Range] one at a time.
///
/// The default behavior of a iterator is expected:
///  - [Range.end] is not inclusive
///  - [current] will return [Range.start] when [moveNext] is not yet called
///  - After  reaching the end of the iteration [current] will return the last
///  element, one  before [Range.end]
class RangeIterator extends Iterator<int> {
  final Range _range;
  int _position = -1;

  RangeIterator._(this._range);

  @override
  int get current {
    if (_position == -1) {
      return _range.start;
    }
    if (_range.start + _position >= _range.end - 1) {
      return _range.end - 1;
    }
    return _range.start + _position;
  }

  @override
  bool moveNext() {
    if (_range.start + _position >= _range.end - 1) {
      return false;
    }
    _position++;
    return true;
  }
}
