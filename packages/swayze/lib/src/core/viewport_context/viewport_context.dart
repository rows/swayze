import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../virtualization/virtualization_calculator.dart';
import 'viewport_context_provider.dart';

const _kDoubleListEquality = ListEquality<double>();
const _kIntIterableEquality = IterableEquality<int>();

/// Interface that provides information about the visible rows and columns:
/// Their sizes, which space in the viewport each one occupies and their
/// respective offset.
///
/// It is a container for two states that are sectioned by axis.
///
///
/// Useful to transform a particular pixel offset into a
/// cell coordinate and vice versa.
///
/// See also:
///- [ViewportAxisContext] the state of each axis.
abstract class ViewportContext extends Listenable {
  /// Store specific information about sizes, offsets and extent of columns.
  ViewportAxisContext get columns;

  /// Store specific information about sizes, offsets and extent of rows.
  ViewportAxisContext get rows;

  /// Get either [columns] or [rows] based on [axis].
  ViewportAxisContext getAxisContextFor({required Axis axis});

  /// Converts a point in the table into a column/row index.
  ///
  /// The [pixelOffset] is the offset from the leading edge of the table in a
  /// given [axis].
  ///
  /// Returns [PositionResult] with details in case the given pixel exceeds
  /// the viewport.
  PositionResult pixelToPosition(double pixelOffset, Axis axis);

  /// Converts a global column/row index into a pixel coordinate ([Offset]) of
  /// the top/left edge of that position in the viewport on the axis [axis].
  ///
  /// Use [isForFrozenPanes] to consider frozen dimension instead of the
  /// scrollable ones.
  PixelResult positionToPixel(
    int globalPosition,
    Axis axis, {
    required bool isForFrozenPanes,
  });

  /// Given a cell's coordinates it returns it's [CellPositionResult] which
  /// contains info about it's [Offset] in pixels and it's [Size].
  CellPositionResult getCellPosition(IntVector2 globalPosition);
}

/// A [ChangeNotifier] that manages has [ViewportAxisContextState]
/// as subject.
///
/// It controls some meta information of headers depending on [axis] to define
/// if it is about columns or rows.
///
/// See also:
/// - [ViewportContext] the interface in which this state will be accessed in
/// the widget tree. It contains one of this class for each axis.
/// - [ViewportContextProvider] the widget in which the state calculates the
///   value of this state.
class ViewportAxisContext extends ChangeNotifier
    implements ValueListenable<ViewportAxisContextState> {
  final Axis axis;

  /// The [VirtualizationState] that causes the computation of the
  /// [ViewportAxisContextState].
  final VirtualizationState virtualizationState;

  late ViewportAxisContextState _value = const ViewportAxisContextState(
    extent: 0.0,
    frozenExtent: 0.0,
    offsets: [],
    frozenOffsets: [],
    sizes: [],
    frozenSizes: [],
    scrollableRange: Range.zero,
    frozenRange: Range.zero,
    visibleIndices: [],
    visibleFrozenIndices: [],
    isDragging: false,
    draggingHeaders: Range.zero,
    draggingCurrentReference: 0,
    draggingPosition: Offset.zero,
    draggingHeaderExtent: 0,
  );

  ViewportAxisContext(this.axis, this.virtualizationState);

  @override
  ViewportAxisContextState get value => _value;

  @protected
  void setState(ViewportAxisContextState newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }
}

/// A immutable value that is the subject of [ViewportAxisContext].
///
/// It stores the information about the visible columns or rows in a defined
/// moment given the visible [scrollableRange] of columns and rows.
///
/// The range is the one defined by [VirtualizationCalculator] and defines the
/// scrollable part of an axis.
///
/// It also stores information about the frozen columns or rows derived from
/// [frozenRange].
@immutable
class ViewportAxisContextState {
  /// The range of visible columns or rows that was used to compute the
  /// other fields in this state that are about the scrollable area of the axis.
  ///
  /// Scrollable, does not include the frozen columns/rows.
  ///
  /// See also:
  /// - [frozenRange] that describes the frozen part of the axis.
  final Range scrollableRange;

  /// The range representing the frozen columns or rows in the axis.
  /// Used to compute other fields in this state that are about the frozen area
  /// of the axis.
  ///
  /// See also:
  /// - [scrollableRange] that describes the scrollable part of the axis.
  final Range frozenRange;

  /// The sum of the sizes of the visible columns or rows in the
  /// [scrollableRange].
  final double extent;

  /// The sum of the sizes of the visible frozen columns or rows in the
  /// [frozenRange].
  final double frozenExtent;

  /// The offset of each visible column or row in relation to the leading edge
  /// of the visible [scrollableRange].
  ///
  /// This does not take displacement in notice.
  final List<double> offsets;

  /// Just like [offsets] but for the [frozenRange]
  final List<double> frozenOffsets;

  /// The size of each visible column or row in the [scrollableRange]
  final List<double> sizes;

  /// The size of each visible frozen column or row in the [frozenRange]
  final List<double> frozenSizes;

  /// The indices of the headers in the [scrollableRange] that occupies at least
  /// 1px.
  final Iterable<int> visibleIndices;

  /// Just like [visibleIndices] but for the [frozenRange]
  final Iterable<int> visibleFrozenIndices;

  /// Wetter or not the header is being dragged.
  final bool isDragging;

  /// Headers that are being dragged.
  final Range draggingHeaders;

  /// Current dragging reference, eg, the current header that [draggingPosition]
  /// is hovering.
  final int draggingCurrentReference;

  /// Current dragging position.
  final Offset draggingPosition;

  /// Extent of all headers being dragged.
  final double draggingHeaderExtent;

  const ViewportAxisContextState({
    required this.scrollableRange,
    required this.frozenRange,
    required this.extent,
    required this.frozenExtent,
    required this.offsets,
    required this.frozenOffsets,
    required this.sizes,
    required this.frozenSizes,
    required this.visibleIndices,
    required this.visibleFrozenIndices,
    required this.isDragging,
    required this.draggingHeaders,
    required this.draggingCurrentReference,
    required this.draggingPosition,
    required this.draggingHeaderExtent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewportAxisContextState &&
          runtimeType == other.runtimeType &&
          scrollableRange == other.scrollableRange &&
          frozenRange == other.frozenRange &&
          extent == other.extent &&
          frozenExtent == other.frozenExtent &&
          isDragging == other.isDragging &&
          draggingHeaders == other.draggingHeaders &&
          draggingCurrentReference == other.draggingCurrentReference &&
          draggingPosition == other.draggingPosition &&
          draggingHeaderExtent == other.draggingHeaderExtent &&
          _kDoubleListEquality.equals(offsets, other.offsets) &&
          _kDoubleListEquality.equals(frozenOffsets, other.frozenOffsets) &&
          _kDoubleListEquality.equals(sizes, other.sizes) &&
          _kDoubleListEquality.equals(frozenSizes, other.frozenSizes) &&
          _kIntIterableEquality.equals(visibleIndices, other.visibleIndices) &&
          _kIntIterableEquality.equals(
            visibleFrozenIndices,
            other.visibleFrozenIndices,
          );

  @override
  int get hashCode =>
      scrollableRange.hashCode ^
      frozenRange.hashCode ^
      extent.hashCode ^
      frozenExtent.hashCode ^
      offsets.hashCode ^
      frozenOffsets.hashCode ^
      sizes.hashCode ^
      frozenSizes.hashCode ^
      visibleIndices.hashCode ^
      visibleFrozenIndices.hashCode ^
      isDragging.hashCode ^
      draggingHeaders.hashCode ^
      draggingPosition.hashCode ^
      draggingHeaderExtent.hashCode ^
      draggingCurrentReference.hashCode;
}

/// A result of a conversion of a pixel offset into column/row index.
///
/// See also:
/// - [ViewportContext.positionToPixel] that generates this result.
@immutable
class PositionResult {
  /// Defines if the retuning position is either of a column or of a row.
  final Axis axis;

  /// Defines if the original pixel is outside the viewport.
  final OffscreenDetails overflow;

  /// Is column/row index that contains the original the pixel. Bound to the visible range.
  final int position;

  /// Defines if the given cell is in a frozen area of the grid.
  final bool isFrozen;

  const PositionResult({
    required this.axis,
    required this.overflow,
    required this.position,
    required this.isFrozen,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionResult &&
          runtimeType == other.runtimeType &&
          axis == other.axis &&
          overflow == other.overflow &&
          position == other.position &&
          isFrozen == other.isFrozen;

  @override
  int get hashCode =>
      axis.hashCode ^ overflow.hashCode ^ position.hashCode ^ isFrozen.hashCode;
}

/// A result of a conversion of a column/row index into a pixel offset.
///
/// See also:
/// - [ViewportContext.positionToPixel] that generates this result.
@immutable
class PixelResult {
  /// Defines if the original index is either of a column or of a row.
  final Axis axis;

  /// Defines if this column/row is outside the viewport.
  final OffscreenDetails offscreenDetails;

  /// Is the pixel offset of the leading edge of the column/row bound to the
  /// viewport dimensions.
  final double pixel;

  const PixelResult({
    required this.axis,
    required this.offscreenDetails,
    required this.pixel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PixelResult &&
          runtimeType == other.runtimeType &&
          pixel == other.pixel &&
          offscreenDetails == other.offscreenDetails &&
          axis == other.axis;

  @override
  int get hashCode =>
      pixel.hashCode ^ offscreenDetails.hashCode ^ axis.hashCode;
}

/// A result of a conversion of a cell's coordinates into it's offset and size
///
/// See also:
/// - [ViewportContext.getCellPosition] that generates this result.
@immutable
class CellPositionResult {
  final bool isOffscreenX;
  final bool isOffscreenY;
  final Offset leftTop;
  final Size cellSize;

  const CellPositionResult({
    this.isOffscreenY = false,
    this.isOffscreenX = false,
    required this.leftTop,
    required this.cellSize,
  });

  factory CellPositionResult.offscreen({
    required bool isOffscreenY,
    required bool isOffscreenX,
  }) {
    return CellPositionResult(
      leftTop: const Offset(0, 0),
      isOffscreenX: isOffscreenX,
      isOffscreenY: isOffscreenY,
      cellSize: Size.zero,
    );
  }

  bool get isOffscreen => isOffscreenX || isOffscreenY;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPositionResult &&
          runtimeType == other.runtimeType &&
          isOffscreenX == other.isOffscreenX &&
          isOffscreenY == other.isOffscreenY &&
          leftTop == other.leftTop &&
          cellSize == other.cellSize;

  @override
  int get hashCode =>
      isOffscreenX.hashCode ^
      isOffscreenY.hashCode ^
      leftTop.hashCode ^
      cellSize.hashCode;
}

/// Used by [PixelResult] and [PositionResult] to describe if the result
/// is off the viewport.
enum OffscreenDetails { noOverflow, leading, trailing }

extension OverflowViewportMethods on OffscreenDetails {
  /// Defines if a [OffscreenDetails] describes a overflow situation.
  bool get isOffscreen => this != OffscreenDetails.noOverflow;
}
