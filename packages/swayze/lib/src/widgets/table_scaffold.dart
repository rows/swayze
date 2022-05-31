import 'package:flutter/widgets.dart';

import '../config.dart' as config;
import '../core/scrolling/sliver_scrolling_data_builder.dart';
import '../core/viewport_context/viewport_context_provider.dart';
import '../core/virtualization/virtualization_calculator.dart';
import 'headers/gestures/resize_header/header_edge_mouse_listener.dart';
import 'headers/header.dart';
import 'internal_scope.dart';
import 'table.dart';
import 'table_body/table_body.dart';
import 'wrappers.dart';

/// A [Widget] that layouts all the three main Table elements:
/// Vertical header, horizontal header and finally the main area.
///
/// For that it uses [CustomMultiChildLayout].
///
/// It is the first visual widget in the tree under the horizontal and vertical
/// scroll views. The widget itself is not scrolled since the custom sliver
/// [SliverScrollingDataBuilder] does not displace its children directly.
///
/// The scroll effect is performed by its direct children: [Header] and
/// [TableBody] by listening to range changes and applying the displacement
/// correction.
///
/// The layout is sensitive to the vertical virtualization state, since the row
/// header width expands as far as we scroll in the table.
class TableScaffold extends StatefulWidget {
  /// The offset to translate children to achieve pixel scrolling.
  ///
  /// See also:
  /// - [VirtualizationState.displacement].
  final double horizontalDisplacement;

  /// The offset to translate children to achieve pixel scrolling.
  ///
  /// See also:
  /// - [VirtualizationState.displacement].
  final double verticalDisplacement;

  /// See [SliverSwayzeTable.wrapTableBody]
  final WrapTableBodyBuilder? wrapTableBody;

  /// See [SliverSwayzeTable.wrapHeader]
  final WrapHeaderBuilder? wrapHeader;

  /// See [SliverSwayzeTable.onHeaderExtentChanged].
  final OnHeaderExtentChanged? onHeaderExtentChanged;

  const TableScaffold({
    Key? key,
    required this.horizontalDisplacement,
    required this.verticalDisplacement,
    this.wrapTableBody,
    this.wrapHeader,
    this.onHeaderExtentChanged,
  }) : super(key: key);

  @override
  _TableScaffoldState createState() => _TableScaffoldState();
}

enum _TableScaffoldSlot { columnHeaders, rowsHeaders, tableBody }

class _TableScaffoldState extends State<TableScaffold> {
  late final viewportContext = ViewportContextProvider.of(context);
  late final verticalRangeNotifier =
      viewportContext.rows.virtualizationState.rangeNotifier;
  late final internalScope = InternalScope.of(context);

  // The state for sizes of headers
  final double columnHeaderHeight = config.kColumnHeaderHeight;
  late double rowHeaderWidth = config.headerWidthForRange(
    verticalRangeNotifier.value,
  );

  @override
  void initState() {
    super.initState();

    verticalRangeNotifier.addListener(didChangeVerticalRange);
    didChangeVerticalRange();
  }

  /// The scaffold adapts to changes in the width of the row headers for large
  /// numbers.
  /// For this is subscribe to changes in the vertical visible range and save
  /// the width into the state.
  void didChangeVerticalRange() {
    final newRowHeaderWidth = config.headerWidthForRange(
      verticalRangeNotifier.value,
    );
    if (newRowHeaderWidth == rowHeaderWidth) {
      return;
    }
    setState(() {
      rowHeaderWidth = newRowHeaderWidth;
    });
  }

  @override
  void dispose() {
    verticalRangeNotifier.removeListener(didChangeVerticalRange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = CustomMultiChildLayout(
      delegate: _TableScaffoldDelegate(rowHeaderWidth, columnHeaderHeight),
      children: [
        LayoutId(
          id: _TableScaffoldSlot.columnHeaders,
          child: Header(
            axis: Axis.horizontal,
            displacement: widget.horizontalDisplacement,
            wrapHeader: widget.wrapHeader,
          ),
        ),
        LayoutId(
          id: _TableScaffoldSlot.rowsHeaders,
          child: Header(
            axis: Axis.vertical,
            displacement: widget.verticalDisplacement,
            wrapHeader: widget.wrapHeader,
          ),
        ),
        LayoutId(
          id: _TableScaffoldSlot.tableBody,
          child: TableBody(
            horizontalDisplacement: widget.horizontalDisplacement,
            verticalDisplacement: widget.verticalDisplacement,
            wrapTableBody: widget.wrapTableBody,
          ),
        ),
      ],
    );

    if (internalScope.config.isResizingHeadersEnabled) {
      return HeaderEdgeMouseListener(
        onHeaderExtentChanged: widget.onHeaderExtentChanged,
        child: child,
      );
    }

    return child;
  }
}

/// A [MultiChildLayoutDelegate] that describe the layout rules for the three
/// main table elements: Vertical header, horizontal header and finally the main
/// table area.
class _TableScaffoldDelegate extends MultiChildLayoutDelegate {
  final double headerWidth;
  final double headerHeight;

  _TableScaffoldDelegate(this.headerWidth, this.headerHeight);

  @override
  void performLayout(Size size) {
    // The dimensions of the table area excluding the space covered by headers
    final remainingHeight =
        (size.height - headerHeight).clamp(0.0, size.height);
    final remainingWidth = (size.width - headerWidth).clamp(0.0, size.width);

    if (hasChild(_TableScaffoldSlot.columnHeaders)) {
      final columnsSize = Size(remainingWidth, headerHeight);
      layoutChild(
        _TableScaffoldSlot.columnHeaders,
        BoxConstraints.tight(columnsSize),
      );
      positionChild(
        _TableScaffoldSlot.columnHeaders,
        Offset(headerWidth, 0.0),
      );
    }

    if (hasChild(_TableScaffoldSlot.rowsHeaders)) {
      final rowSize = Size(headerWidth, remainingHeight);

      layoutChild(
        _TableScaffoldSlot.rowsHeaders,
        BoxConstraints.tight(rowSize),
      );
      positionChild(
        _TableScaffoldSlot.rowsHeaders,
        Offset(0, headerHeight),
      );
    }

    if (hasChild(_TableScaffoldSlot.tableBody)) {
      final tableSize = Size(remainingWidth, remainingHeight);
      layoutChild(
        _TableScaffoldSlot.tableBody,
        BoxConstraints.tight(tableSize),
      );
      positionChild(
        _TableScaffoldSlot.tableBody,
        Offset(
          headerWidth,
          headerHeight,
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_TableScaffoldDelegate oldDelegate) {
    return oldDelegate.headerWidth != headerWidth;
  }
}
