import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../helpers/wrapped.dart';
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

  /// The maximum amount allowed of headers in this axis that exist only due to
  /// table's elastic expansion.
  final int? maxElasticCount;

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

  /// Current state of a drag and drop action.
  ///
  /// null if no drag is being performed.
  final SwayzeHeaderDragState? dragState;

  /// Creates a header state from an unsorted list of [SwayzeHeaderData].
  ///
  /// This is axis agnostic.
  SwayzeHeaderState({
    required this.defaultHeaderExtent,
    required this.count,
    required Iterable<SwayzeHeaderData> headerData,
    required int frozenCount,
    int? elasticCount,
    this.maxElasticCount,
    this.dragState,
  })  : _frozenCount = frozenCount,
        elasticCount = elasticCount ?? 0,
        _customSizedHeaders = headerData.fold(
          SplayTreeMap<int, SwayzeHeaderData>(),
          (previousValue, element) {
            previousValue[element.index] = element;
            return previousValue;
          },
        );

  /// Creates a header state from a sorted map of [SwayzeHeaderData]
  SwayzeHeaderState._fromSortedHeaderData({
    required this.defaultHeaderExtent,
    required this.elasticCount,
    required this.count,
    required SplayTreeMap<int, SwayzeHeaderData> sortedHeaderData,
    required int frozenCount,
    this.dragState,
    this.maxElasticCount,
  })  : _frozenCount = frozenCount,
        _customSizedHeaders = sortedHeaderData;

  /// Copies the state overriding specific fields.
  ///
  /// If [headerData] is not provided, reuse the current
  /// map of [customSizedHeaders].
  SwayzeHeaderState copyWith({
    int? count,
    int? elasticCount,
    Wrapped<int?>? maxElasticCount,
    Iterable<SwayzeHeaderData>? headerData,
    int? frozenCount,
    Wrapped<SwayzeHeaderDragState?>? dragState,
  }) {
    if (headerData != null) {
      return SwayzeHeaderState(
        elasticCount: elasticCount ?? this.elasticCount,
        maxElasticCount: maxElasticCount?.value ?? this.maxElasticCount,
        defaultHeaderExtent: defaultHeaderExtent,
        count: count ?? this.count,
        headerData: headerData,
        frozenCount: frozenCount ?? this.frozenCount,
        dragState: dragState != null ? dragState.value : this.dragState,
      );
    }

    return SwayzeHeaderState._fromSortedHeaderData(
      elasticCount: elasticCount ?? this.elasticCount,
      maxElasticCount: maxElasticCount?.value ?? this.maxElasticCount,
      defaultHeaderExtent: defaultHeaderExtent,
      count: count ?? this.count,
      sortedHeaderData: _customSizedHeaders,
      frozenCount: frozenCount ?? this.frozenCount,
      dragState: dragState != null ? dragState.value : this.dragState,
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
      maxElasticCount: maxElasticCount,
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
          maxElasticCount == other.maxElasticCount &&
          dragState == other.dragState &&
          _kMapEquality.equals(customSizedHeaders, other.customSizedHeaders);

  @override
  int get hashCode =>
      _frozenCount.hashCode ^
      defaultHeaderExtent.hashCode ^
      count.hashCode ^
      elasticCount.hashCode ^
      maxElasticCount.hashCode ^
      customSizedHeaders.hashCode ^
      dragState.hashCode;

  @override
  String toString() {
    return '''
    SwayzeHeaderState(
      defaultHeaderExtent: $defaultHeaderExtent,
      count: $count,
      elasticCount: $elasticCount,
      maxElasticCount: $maxElasticCount,
      orderedCustomSizedIndices: $orderedCustomSizedIndices,
      hasCustomSizes: $hasCustomSizes,
      customSizedHeaders: $customSizedHeaders,
      extent: $extent,
      frozenCount: $frozenCount,
      dragState: $dragState,
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

/// Holds the state of a header drag and drop action.
@immutable
class SwayzeHeaderDragState {
  /// Headers being dragged.
  final Range headers;

  /// Current dropping position.
  final int dropAtIndex;

  /// Current drag global position.
  final Offset position;

  const SwayzeHeaderDragState({
    required this.headers,
    required this.dropAtIndex,
    required this.position,
  });

  /// Checks if the current [headers] can be dropped at the [dropAtIndex]
  /// position.
  ///
  /// The headers can only be dropped outside its own range.
  bool get isDropAllowed => !headers.contains(dropAtIndex);

  SwayzeHeaderDragState copyWith({
    Range? headers,
    int? dropAtIndex,
    Offset? position,
  }) {
    return SwayzeHeaderDragState(
      headers: headers ?? this.headers,
      dropAtIndex: dropAtIndex ?? this.dropAtIndex,
      position: position ?? this.position,
    );
  }

  @override
  String toString() =>
      'SwayzeHeaderDragState($headers, $dropAtIndex, $position)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeHeaderDragState &&
          runtimeType == other.runtimeType &&
          headers == other.headers &&
          dropAtIndex == other.dropAtIndex &&
          position == other.position;

  @override
  int get hashCode =>
      headers.hashCode ^ dropAtIndex.hashCode ^ position.hashCode;
}
