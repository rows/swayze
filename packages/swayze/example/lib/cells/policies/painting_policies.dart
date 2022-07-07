import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze/delegates.dart';

import '../../data/cell_data.dart';

/// Build the widgets to be shown inside eligible cells on a
/// [CellPaintingPolicy].
///
/// See also:
/// - [CellPaintingPolicy.builder]
/// - [CellBadgePolicy]
/// - [CellOverlayPolicy]
typedef CellPolicyBuilder<CellDataType extends MyCellData> = Widget Function(
  BuildContext context,
  CellDataType cellData, {
  bool? isHover,
  bool? isActive,
});

/// From a [cellData] define if a cell should comply to a specific
/// [CellPaintingPolicy]
///
/// ⚠️ It should only depend on the cell model and only that.
/// Since it is called before each cell build, it is very performance critical.
/// Make it as declarative as possible.
///
/// See also:
/// - [CellPaintingPolicy.checkEligibility]
typedef CellPolicyDecider<CellDataType extends MyCellData> = bool Function(
  CellDataType cellData,
);

/// Semantic class to encapsulate the eligibility for special rendering widgets
/// on cells ion certain conditions.
///
/// Should not be subclassed directly. Instead, instantiate or subclass
/// [CellOverlayPolicy] or [CellBadgePolicy].
///
/// See also:
/// - [CellOverlayPolicy] that defines rules to show any widget over a cell on
///   mouse hover.
@immutable
abstract class CellPaintingPolicy<CellDataType extends MyCellData>
    extends Equatable {
  /// For a particular cell, defines if the [builder] will
  final CellPolicyDecider<CellDataType> checkEligibility;

  /// Build the widgets to be shown inside eligible cells.
  final CellPolicyBuilder<CellDataType> builder;

  const CellPaintingPolicy(this.checkEligibility, this.builder);

  @override
  List<Object?> get props => [checkEligibility, builder];
}

/// Describes the if a cell should include widgets to be built over it when
/// the mouse is hover.
///
/// The widget returned by [builder] will be rendered with
/// [BoxConstraints.loose] to the size of the cell in which it is covering with.
///
/// It will render the widget over cells that are declared eligible via
/// [checkEligibility].
///
/// See also:
/// - [CellPaintingPolicy] the superclass for all painting policies.
class CellOverlayPolicy<CellDataType extends MyCellData>
    extends CellPaintingPolicy<CellDataType> {
  const CellOverlayPolicy({
    required CellPolicyDecider<CellDataType> checkEligibility,
    required CellPolicyBuilder<CellDataType> builder,
  }) : super(checkEligibility, builder);
}

/// To be mixed on a [CellDelegate], it contains the logics to define which
/// [CellPaintingPolicy]s are eligible for a cell.
mixin Overlays<CellDataType extends MyCellData> on CellDelegate<CellDataType> {
  /// The [CellOverlayPolicy]s to be evaluated by the [CellDelegate] to be
  /// applied to its cells.
  Iterable<CellOverlayPolicy<CellDataType>>? get overlayPolicies;

  /// Define which overlays are applicable to a specific cell with [cellData].
  CellOverlays<CellDataType> getOverlaysOfACell(CellDataType cellData) {
    final overlays = overlayPolicies?.where((badge) {
      return badge.checkEligibility(cellData);
    });
    return CellOverlays(overlays);
  }
}

@immutable
class CellOverlays<CellDataType extends MyCellData> extends Equatable {
  final Iterable<CellOverlayPolicy<CellDataType>>? overlayPolicies;

  const CellOverlays(this.overlayPolicies);

  bool get hasAnyOverlay =>
      overlayPolicies != null && overlayPolicies!.isNotEmpty;

  @override
  List<Object?> get props => [overlayPolicies];
}
