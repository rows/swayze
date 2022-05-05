import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../controller.dart';

const _kMapEquality = MapEquality<int, SwayzeHeaderData>();

/// The value of [SwayzeHeaderController].
///
/// A immutable state that holds information related to header of a table in
/// an axis.
@immutable
class SwayzeHeaderState {
  /// The amount of headers frozen. That is, headers that are fixed on scroll.
  final int _frozenCount;

  /// The amount of headers frozen bound to the actual amount of headers
  /// in the axis.
  int get frozenCount => min(_frozenCount, count);

  /// The default extent of all headers in this axis. Header that are not
  /// indexed on [customSizedHeaders] will assume this extent.
  final double defaultHeaderExtent;

  /// The amount of headers in this axis that exist only due to table's
  /// elastic expansion.
  final int elasticCount;

  /// The amount of headers in this axis.
  final int count;

  /// The collection that stores the custom headers ordered by their indices.
  final SplayTreeMap<int, SwayzeHeaderData> _customSizedHeaders;

  /// The ordered indices of all custom sized header in this index.
  late final orderedCustomSizedIndices = _customSizedHeaders.keys;

  /// `true` if there is any custom sized header in this axis.
  late final hasCustomSizes = _customSizedHeaders.isNotEmpty;

  /// An unmodifiable map that indexes all custom sized headers of this axis.
  late final customSizedHeaders = Map<int, SwayzeHeaderData>.unmodifiable(
    _customSizedHeaders,
  );

  /// The amount of headers in this axis, including real and elastic headers.
  late final totalCount = (() => max(count, elasticCount))();

  /// The total extent of this axis.
  ///
  /// It is the sum of the extents of all headers, custom sized or not.
  late final double extent = (() {
    var customSizesCount = 0;
    final allCustomSizes = _customSizedHeaders.entries.fold<double>(
      0.0,
      (value, entry) {
        if (entry.key >= totalCount) {
          return value;
        }

        customSizesCount++;
        return value + (entry.value.effectiveExtent);
      },
    );
    final allRegularSizes =
        (totalCount - customSizesCount) * defaultHeaderExtent;
    return allCustomSizes + allRegularSizes;
  })();

  /// The total extent of the frozen headers in this axis.
  late final double frozenExtent = (() {
    var result = 0.0;
    for (var i = 0; i < frozenCount; i++) {
      result += getHeaderExtentFor(index: i);
    }
    return result;
  })();

  // TODO: [victor] probably a controller is a better solution
  final bool dragging;
  // TODO: [victor] get from selection
  final int? draggingHeaderIndex;
  final int? draggingCurrentReference;
  final Offset draggingPosition;

  /// Creates a header state from an unsorted list of [SwayzeHeaderData].
  ///
  /// This is axis agnostic.
  SwayzeHeaderState({
    required this.defaultHeaderExtent,
    required this.count,
    required Iterable<SwayzeHeaderData> headerData,
    required int frozenCount,
    int? elasticCount,
    bool? dragging,
    this.draggingPosition = Offset.zero,
    this.draggingHeaderIndex,
    this.draggingCurrentReference,
  })  : _frozenCount = frozenCount,
        elasticCount = elasticCount ?? 0,
        _customSizedHeaders = headerData.fold(
          SplayTreeMap<int, SwayzeHeaderData>(),
          (previousValue, element) {
            previousValue[element.index] = element;
            return previousValue;
          },
        ),
        dragging = dragging ?? false;

  /// Creates a header state from a sorted map of [SwayzeHeaderData]
  SwayzeHeaderState._fromSortedHeaderData({
    required this.defaultHeaderExtent,
    required this.elasticCount,
    required this.count,
    required SplayTreeMap<int, SwayzeHeaderData> sortedHeaderData,
    required int frozenCount,
    bool? dragging,
    this.draggingPosition = Offset.zero,
    this.draggingHeaderIndex,
    this.draggingCurrentReference,
  })  : _frozenCount = frozenCount,
        _customSizedHeaders = sortedHeaderData,
        dragging = dragging ?? false;

  /// Copies the state overriding specific fields.
  ///
  /// If [headerData] is not provided, reuse the current
  /// map of [customSizedHeaders].
  SwayzeHeaderState copyWith({
    int? count,
    int? elasticCount,
    Iterable<SwayzeHeaderData>? headerData,
    int? frozenCount,
    bool? dragging,
    int? draggingHeaderIndex,
    int? draggingCurrentReference,
    Offset? draggingPosition,
  }) {
    if (headerData != null) {
      return SwayzeHeaderState(
        elasticCount: elasticCount ?? this.elasticCount,
        defaultHeaderExtent: defaultHeaderExtent,
        count: count ?? this.count,
        headerData: headerData,
        frozenCount: frozenCount ?? this.frozenCount,
        dragging: dragging ?? this.dragging,
        draggingPosition: draggingPosition ?? this.draggingPosition,
        draggingCurrentReference:
            draggingCurrentReference ?? this.draggingCurrentReference,
        draggingHeaderIndex: draggingHeaderIndex ?? this.draggingHeaderIndex,
      );
    }

    return SwayzeHeaderState._fromSortedHeaderData(
      elasticCount: elasticCount ?? this.elasticCount,
      defaultHeaderExtent: defaultHeaderExtent,
      count: count ?? this.count,
      sortedHeaderData: _customSizedHeaders,
      frozenCount: frozenCount ?? this.frozenCount,
      dragging: dragging ?? this.dragging,
      draggingPosition: draggingPosition ?? this.draggingPosition,
      draggingCurrentReference:
          draggingCurrentReference ?? this.draggingCurrentReference,
      draggingHeaderIndex: draggingHeaderIndex ?? this.draggingHeaderIndex,
    );
  }

  /// Set the extent of a specific header
  SwayzeHeaderState setHeaderExtent(int index, double extent) {
    final currentHeaderData = _customSizedHeaders[index];

    final _newCustomSizedHeaders =
        SplayTreeMap<int, SwayzeHeaderData>.from(_customSizedHeaders);

    if (extent == defaultHeaderExtent) {
      _newCustomSizedHeaders.remove(index);
    } else if (currentHeaderData == null) {
      _newCustomSizedHeaders[index] = SwayzeHeaderData(
        index: index,
        extent: extent,
        hidden: false,
      );
    } else {
      _newCustomSizedHeaders[index] =
          currentHeaderData.copyWith(extent: extent);
    }

    return SwayzeHeaderState._fromSortedHeaderData(
      elasticCount: elasticCount,
      defaultHeaderExtent: defaultHeaderExtent,
      count: count,
      sortedHeaderData: _newCustomSizedHeaders,
      frozenCount: frozenCount,
    );
  }

  /// get the extent of a specific header
  double getHeaderExtentFor({required int index}) {
    return customSizedHeaders[index]?.effectiveExtent ?? defaultHeaderExtent;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeHeaderState &&
          runtimeType == other.runtimeType &&
          _frozenCount == other._frozenCount &&
          defaultHeaderExtent == other.defaultHeaderExtent &&
          count == other.count &&
          elasticCount == other.elasticCount &&
          dragging == other.dragging &&
          draggingHeaderIndex == other.draggingHeaderIndex &&
          draggingCurrentReference == other.draggingCurrentReference &&
          draggingPosition == other.draggingPosition &&
          _kMapEquality.equals(customSizedHeaders, other.customSizedHeaders);

  @override
  int get hashCode =>
      _frozenCount.hashCode ^
      defaultHeaderExtent.hashCode ^
      count.hashCode ^
      elasticCount.hashCode ^
      customSizedHeaders.hashCode ^
      dragging.hashCode ^
      draggingHeaderIndex.hashCode ^
      draggingPosition.hashCode ^
      draggingCurrentReference.hashCode;

  @override
  String toString() {
    return '''
    SwayzeHeaderState(
      defaultHeaderExtent: $defaultHeaderExtent,
      count: $count,
      elasticCount: $elasticCount,
      orderedCustomSizedIndices: $orderedCustomSizedIndices,
      hasCustomSizes: $hasCustomSizes,
      customSizedHeaders: $customSizedHeaders,
      extent: $extent,
      frozenCount: $frozenCount,
    )
    ''';
  }
}

@immutable
class SwayzeHeaderData {
  final int index;
  final double? extent;
  final bool hidden;

  const SwayzeHeaderData({
    required this.index,
    required this.extent,
    required this.hidden,
  }) : assert(
          (hidden == true) || (extent != null),
          'A SwayzeHeaderData either has to be hidden or have a custom extent',
        );

  double get effectiveExtent => hidden ? 0.0 : extent!;

  SwayzeHeaderData copyWith({
    double? extent,
    bool? hidden,
  }) {
    return SwayzeHeaderData(
      index: index,
      extent: extent ?? this.extent,
      hidden: hidden ?? this.hidden,
    );
  }

  @override
  String toString() {
    return 'SwayzeHeaderData($index, $extent, $hidden)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeHeaderData &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          extent == other.extent &&
          hidden == other.hidden;

  @override
  int get hashCode => index.hashCode ^ extent.hashCode ^ hidden.hashCode;
}
