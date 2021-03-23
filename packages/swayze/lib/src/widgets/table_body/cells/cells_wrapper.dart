import 'package:flutter/widgets.dart';

import '../../../core/viewport_context/viewport_context.dart';
import '../../../core/viewport_context/viewport_context_provider.dart';
import '../../internal_scope.dart';
import 'cells.dart';

/// A [Widget] responsible for filtering information from [ViewportContext]
/// and [InternalScope] and pass the relevant data to [Cells].
///
/// The data passed to [Cells] may refer to frozen instances depending on the
/// value of [isOnAFrozenColumnsArea] and [isOnAFrozenRowsArea].
class CellsWrapper extends StatefulWidget {
  /// Defines if the cells to be rendered are located in a area
  /// horizontally frozen, that is, it does not scroll in that axis.
  final bool isOnAFrozenColumnsArea;

  /// Defines if the cells to be rendered are located in a area
  /// vertically frozen, that is, it does not scroll in that axis.
  final bool isOnAFrozenRowsArea;

  const CellsWrapper({
    Key? key,
    this.isOnAFrozenColumnsArea = false,
    this.isOnAFrozenRowsArea = false,
  }) : super(key: key);

  @override
  _CellsWrapperState createState() => _CellsWrapperState();
}

class _CellsWrapperState extends State<CellsWrapper> {
  late final viewportContext = ViewportContextProvider.of(context);
  late final internalScope = InternalScope.of(context);
  late ViewportAxisContextState columnsState;
  late ViewportAxisContextState rowsState;

  @override
  void initState() {
    super.initState();
    viewportContext.columns.addListener(onRangesChanged);
    viewportContext.rows.addListener(onRangesChanged);

    onRangesChanged();
  }

  @override
  void dispose() {
    viewportContext.columns.removeListener(onRangesChanged);
    viewportContext.rows.removeListener(onRangesChanged);

    super.dispose();
  }

  void onRangesChanged() {
    setState(() {
      columnsState = viewportContext.columns.value;
      rowsState = viewportContext.rows.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnFrozenColumns = widget.isOnAFrozenColumnsArea;
    final isOnFrozenRows = widget.isOnAFrozenRowsArea;

    // Ranges
    final horizontalRange = isOnFrozenColumns
        ? columnsState.frozenRange
        : columnsState.scrollableRange;
    final verticalRange =
        isOnFrozenRows ? rowsState.frozenRange : rowsState.scrollableRange;

    // Offsets
    final columnOffsets =
        isOnFrozenColumns ? columnsState.frozenOffsets : columnsState.offsets;
    final rowOffsets =
        isOnFrozenRows ? rowsState.frozenOffsets : rowsState.offsets;

    final columnSizes =
        isOnFrozenColumns ? columnsState.frozenSizes : columnsState.sizes;
    final rowSizes = isOnFrozenRows ? rowsState.frozenSizes : rowsState.sizes;

    // Visible indices
    final visibleColumnsIndices = isOnFrozenColumns
        ? columnsState.visibleFrozenIndices
        : columnsState.visibleIndices;
    final visibleRowsIndices = isOnFrozenRows
        ? rowsState.visibleFrozenIndices
        : rowsState.visibleIndices;

    return Cells(
      key: ValueKey('${columnsState.frozenExtent}:${rowsState.frozenExtent}'),
      swayzeController: internalScope.controller,
      swayzeStyle: internalScope.style,
      cellDelegate: internalScope.cellDelegate,
      horizontalRange: horizontalRange,
      verticalRange: verticalRange,
      columnOffsets: columnOffsets,
      rowOffsets: rowOffsets,
      columnSizes: columnSizes,
      rowSizes: rowSizes,
      visibleColumnsIndices: visibleColumnsIndices,
      visibleRowsIndices: visibleRowsIndices,
    );
  }
}
