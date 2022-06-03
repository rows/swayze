import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../config.dart';
import '../core/config/config.dart';
import '../core/controller/controller.dart';
import '../core/delegates/cell_delegate.dart';
import '../core/internal_state/table_focus/table_focus_provider.dart';
import '../core/scrolling/sliver_two_axis_scroll.dart';
import '../core/style/style.dart';
import 'default_actions/default_table_actions.dart';
import 'inline_editor/inline_editor.dart';
import 'internal_scope.dart';
import 'shortcuts/shortcuts.dart';
import 'table_scaffold.dart';
import 'wrappers.dart';

export '../config.dart';
export 'inline_editor/inline_editor.dart' show InlineEditorBuilder;

/// A callback invoked when the extent of an header has changed.
///
/// It gives back the header's index, axis, the old and new extent.
typedef OnHeaderExtentChanged = Function(
  int index,
  Axis axis,
  double oldExtent,
  double newExtent,
);

/// Padding to add to the right side of the sticky header when the sticky header
/// is occupying the full available width.
const _kStickyHeaderRightPadding = 24;

/// A sliver [StatefulWidget] that represents one single table on a
/// scroll view.
///
/// See also:
/// * [SliverTwoAxisScroll] the sliver that adds horizontal scroll in addition
///   to the vertical scroll given by [SwayzeEditorMain]
class SliverSwayzeTable<CellDataType extends SwayzeCellData>
    extends StatefulWidget {
  /// Controls focus of this table.
  final FocusNode focusNode;

  /// Defines if the widget should autofocus on build
  final bool autofocus;

  /// Defines the controller for the internal state of this table.
  ///
  /// This controls behaviors such as selection.
  final SwayzeController controller;

  /// The style of the table, defaults to [SwayzeStyle.defaultSwayzeStyle].
  final SwayzeStyle style;

  /// Configuration for swayze interactions.
  final SwayzeConfig config;

  /// The [ScrollController] that manages the external vertical scroll view.
  final ScrollController verticalScrollController;

  /// A widget to be rendered on the before the table in the scroll view.
  /// Its height is defined by [SwayzeStyle.stickyHeaderSize].
  final Widget? stickyHeader;

  /// The height of the [stickyHeaderSize]. Cannot be null if
  /// [stickyHeader] is defined.
  final double? stickyHeaderSize;

  /// Builder to wrap the box part of the table with box widgets that
  /// cannot wrap [SliverSwayzeTable] directly because it is a sliver, like a
  /// [FocusTrapArea] for example.
  ///
  /// See also:
  ///  - [WrapBoxBuilder]
  final WrapBoxBuilder? wrapBox;

  /// Builder to wrap the table body of the table.
  ///
  /// The table body is where the cells and the lines separating the cells are
  /// rendered.
  ///
  /// See also:
  /// - [WrapTableBodyBuilder]
  final WrapTableBodyBuilder? wrapTableBody;

  /// Builder to wrap the headers of the table.
  ///
  /// The header is where the identifier for columns and rows are rendered
  ///
  /// See also:
  /// - [WrapHeaderBuilder]
  final WrapHeaderBuilder? wrapHeader;

  /// The Builder that generates the widget that will be rendered when the user
  /// will edit a particular cell inline, that is, in the same physical spot
  /// occupied by the cell in the screen.
  ///
  /// The inline editor will be added to the closest [Overlay]. If you haven't
  /// defined one, it will default to the [Navigator]'s [Overlay].
  ///
  /// See also:
  /// - [InlineEditorBuilder] for more details
  /// - [InlineEditorController] that controls the overall state of the
  /// inline editor.
  final InlineEditorBuilder inlineEditorBuilder;

  final CellDelegate<CellDataType> cellDelegate;

  /// Callback invoked every time an header is resized.
  ///
  /// See also:
  ///   - [OnHeaderExtentChanged].
  final OnHeaderExtentChanged? onHeaderExtentChanged;

  SliverSwayzeTable({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.verticalScrollController,
    bool? autofocus,
    this.stickyHeader,
    this.stickyHeaderSize,
    SwayzeStyle? style,
    required this.inlineEditorBuilder,
    required this.cellDelegate,
    this.wrapBox,
    this.wrapTableBody,
    this.wrapHeader,
    SwayzeConfig? config,
    this.onHeaderExtentChanged,
  })  : autofocus = autofocus ?? false,
        style = style ?? SwayzeStyle.defaultSwayzeStyle,
        config = config ?? const SwayzeConfig(),
        assert(
          stickyHeader == null || stickyHeaderSize != null,
          'if stickyHeader is not null, stickyHeaderSize must be also not null',
        ),
        super(key: key);

  @override
  SliverSwayzeTableState createState() => SliverSwayzeTableState();
}

/// This class is stateful due to its access via
/// [SwayzeScrollController.ensureTableVisibility].
class SliverSwayzeTableState extends State<SliverSwayzeTable> {
  @override
  Widget build(BuildContext context) {
    final effectiveHeaderHeight =
        widget.stickyHeader == null ? 0.0 : widget.stickyHeaderSize!;

    final focusScopeNode = FocusScope.of(context);

    Widget child = SliverTwoAxisScroll(
      paddingTop:
          effectiveHeaderHeight, // the size of the header is compensated
      // in the sliver
      verticalScrollController: widget.verticalScrollController,
      wrapBox: widget.wrapBox,
      twoAxisScrollBuilder: (
        context,
        verticalDisplacement,
        horizontalDisplacement,
        isOffscreen,
      ) {
        final child = isOffscreen
            ? const SizedBox.shrink()
            : TableScaffold(
                verticalDisplacement: verticalDisplacement,
                horizontalDisplacement: horizontalDisplacement,
                wrapTableBody: widget.wrapTableBody,
                wrapHeader: widget.wrapHeader,
                onHeaderExtentChanged: widget.onHeaderExtentChanged,
              );

        return TableShortcuts(
          child: TableFocusProvider(
            focusNode: widget.focusNode,
            focusScopeNode: focusScopeNode,
            child: DefaultActions(
              child: Focus(
                autofocus: widget.autofocus,
                focusNode: widget.focusNode,
                child: InlineEditorPlacer(
                  inlineEditorBuilder: widget.inlineEditorBuilder,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.stickyHeader != null) {
      child = SliverStickyHeader(
        header: _StickHeaderWrapper(
          headerState: widget.controller.tableDataController.columns,
          headerHeight: effectiveHeaderHeight,
          child: widget.stickyHeader,
        ),
        overlapsContent: true,
        sliver: child,
      );
    }

    return InternalScopeProvider(
      cellDelegate: widget.cellDelegate,
      controller: widget.controller,
      style: widget.style,
      config: widget.config,
      child: child,
    );
  }
}

class _StickHeaderWrapper extends StatelessWidget {
  final double headerHeight;
  final Widget? child;
  final ValueListenable<SwayzeHeaderState> headerState;

  const _StickHeaderWrapper({
    Key? key,
    required this.headerHeight,
    required this.child,
    required this.headerState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<SwayzeHeaderState>(
          valueListenable: headerState,
          builder: (context, value, _) {
            final headerWidth = value.extent + kRowHeaderWidth;
            return UnconstrainedBox(
              alignment: Alignment.centerLeft,
              constrainedAxis: Axis.vertical,
              child: SizedBox(
                width: min(
                  constraints.maxWidth - _kStickyHeaderRightPadding,
                  headerWidth,
                ),
                height: headerHeight,
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
