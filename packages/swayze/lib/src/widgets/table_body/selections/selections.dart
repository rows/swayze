import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../controller.dart';
import '../../../core/internal_state/table_focus/table_focus_provider.dart';
import '../../../core/internal_state/table_focus/table_focus_state.dart';
import '../../../core/viewport_context/viewport_context_provider.dart';
import '../../../helpers/range_pair_key.dart';
import '../../internal_scope.dart';
import 'data_selections/data_selections.dart';
import 'fill_selections/fill_selection.dart';
import 'primary_selection/primary_selection.dart';
import 'secondary_selections/secondary_selections.dart';

/// A [StatelessWidget] that wraps [TableBodySelections] with a
/// [ValueListenableBuilder] biding it to the contexts
/// [SwayzeSelectionController] state changes.
class TableBodySelections extends StatelessWidget {
  /// Defines if the selections to be rendered are located in a area
  /// horizontally frozen, that is, it does not scroll in that axis.
  final bool isOnAFrozenColumnsArea;

  /// Defines if the selections to be rendered are located in a area
  /// vertically frozen, that is, it does not scroll in that axis.
  final bool isOnAFrozenRowsArea;

  const TableBodySelections({
    Key? key,
    this.isOnAFrozenColumnsArea = false,
    this.isOnAFrozenRowsArea = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectionController = InternalScope.of(context).controller.selection;

    return AnimatedBuilder(
      animation: selectionController,
      builder: (BuildContext context, Widget? child) {
        return _TableBodySelections(
          selectionController: selectionController,
          isOnAFrozenColumnsArea: isOnAFrozenColumnsArea,
          isOnAFrozenRowsArea: isOnAFrozenRowsArea,
        );
      },
    );
  }
}

/// A [StatelessWidget] responsible to render all selections on
/// [userSelectionState] using [TableBodySelection] and all selections on
/// [dataSelections] using [DataSelections].
class _TableBodySelections extends StatefulWidget {
  final SwayzeSelectionController selectionController;
  final bool isOnAFrozenColumnsArea;
  final bool isOnAFrozenRowsArea;

  const _TableBodySelections({
    Key? key,
    required this.selectionController,
    required this.isOnAFrozenColumnsArea,
    required this.isOnAFrozenRowsArea,
  }) : super(key: key);

  @override
  _TableBodySelectionsState createState() => _TableBodySelectionsState();
}

class _TableBodySelectionsState extends State<_TableBodySelections> {
  late Range xRange;
  late Range yRange;
  late final viewportContext = ViewportContextProvider.of(context);
  late final tableFocus = TableFocus.of(context);

  @override
  void initState() {
    super.initState();
    // Kepp track fo changes in the viewport to move selections without any
    // animations
    viewportContext.addListener(onRangesChanged);
    tableFocus.addListener(handleFocusChanged);

    onRangesChanged();
  }

  @override
  void dispose() {
    viewportContext.removeListener(onRangesChanged);
    tableFocus.removeListener(handleFocusChanged);

    super.dispose();
  }

  void onRangesChanged() {
    // Ranges on frozen areas respect the  amount of frozen headers rather
    // than the range.
    setState(() {
      xRange = widget.isOnAFrozenColumnsArea
          ? Range(0, viewportContext.columns.value.frozenOffsets.length)
          : viewportContext.columns.value.scrollableRange;
      yRange = widget.isOnAFrozenRowsArea
          ? Range(0, viewportContext.rows.value.frozenOffsets.length)
          : viewportContext.rows.value.scrollableRange;
    });
  }

  /// Keep track of focus/active state.
  ///
  /// When a user moves to another element, the user selections should be
  /// reseted which will trigger a reaction to make sure that the elastic state
  /// of the table is also reseted.
  void handleFocusChanged() {
    if (!tableFocus.value.isActive) {
      widget.selectionController.updateUserSelections(
        (state) => state.reset(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TableFocusState>(
      valueListenable: tableFocus,
      builder: (context, focusState, _) {
        final userSelectionState =
            widget.selectionController.userSelectionState;
        final dataSelections = widget.selectionController.dataSelections;

        final primary = userSelectionState.primarySelection;
        final fill = widget.selectionController.fillSelectionState.selection;

        final positionActiveCell = viewportContext.getCellPosition(
          userSelectionState.activeCellCoordinate,
        );

        final activeCellRect =
            positionActiveCell.leftTop & positionActiveCell.cellSize;

        final children = <Widget>[];

        if (dataSelections.isNotEmpty) {
          children.add(
            DataSelections(
              xRange: xRange,
              yRange: yRange,
              dataSelections: dataSelections,
              isOnFrozenColumns: widget.isOnAFrozenColumnsArea,
              isOnFrozenRows: widget.isOnAFrozenRowsArea,
            ),
          );
        }

        // User selections are only visible when the table is focused
        if (focusState.isActive) {
          if (userSelectionState.selections.length > 1) {
            children.add(
              SecondarySelections(
                selectionState: userSelectionState,
                activeCellRect: activeCellRect,
                xRange: xRange,
                yRange: yRange,
                isOnFrozenColumns: widget.isOnAFrozenColumnsArea,
                isOnFrozenRows: widget.isOnAFrozenRowsArea,
              ),
            );
          }

          if (fill != null) {
            children.add(
              FillSelection(
                key: ValueKey(fill),
                selectionModel: fill,
                xRange: xRange,
                yRange: yRange,
                isOnFrozenColumns: widget.isOnAFrozenColumnsArea,
                isOnFrozenRows: widget.isOnAFrozenRowsArea,
              ),
            );
          }

          children.add(
            PrimarySelection(
              key: ValueKey(primary),
              selectionModel: primary,
              activeCellRect: activeCellRect,
              xRange: xRange,
              yRange: yRange,
              isOnFrozenColumns: widget.isOnAFrozenColumnsArea,
              isOnFrozenRows: widget.isOnAFrozenRowsArea,
            ),
          );
        }

        if (children.isEmpty) {
          return const SizedBox();
        }

        return IgnorePointer(
          // Avoid animations in the primary selections by breaking the key
          // when the visible range of cells changes.
          key: RangePairKey(xRange, yRange),
          child: Stack(
            children: children,
          ),
        );
      },
    );
  }
}
