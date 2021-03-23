import 'package:flutter/widgets.dart';

import '../core/scrolling/sliver_two_axis_scroll.dart';
import '../core/viewport_context/viewport_context.dart';
import 'headers/header.dart';
import 'table.dart';
import 'table_body/table_body.dart';

/// A builder that builds a widget that wraps the box parts of a
/// [SliverSwayzeTable].
///
/// The result widget should contain the passed [child] which is the box parts
/// of the table.
///
/// See also:
/// - [SliverSwayzeTable.wrapBox]
/// - [SliverTwoAxisScroll] that contains the caller for this builder.
typedef WrapBoxBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

/// A builder that builds a widget that wraps the main area of
/// [SliverSwayzeTable].
///
/// The table body is where the cells and the lines separating the cells are
/// rendered.
///
/// The result widget should contain the passed [child] which is the table body
/// content of the table.
///
/// Use [viewportContext] to transform a pixel position into a cell coordinate
/// and vice versa.
///
/// See also:
/// - [SliverSwayzeTable.wrapTableBody]
/// - [TableBody] that contains the caller for this builder.
typedef WrapTableBodyBuilder = Widget Function(
  BuildContext context,
  ViewportContext viewportContext,
  Widget child,
);

/// A builder that builds a widget that wraps the headers of
/// [SliverSwayzeTable].
///
/// The header is where the identifier for columns and rows are rendered.
///
/// The result widget should contain the passed [child] which is the actual
/// header widgets.
///
/// Use [viewportContext] to transform a pixel position into a cell coordinate
/// and vice versa.
///
/// Use [axis] to define if this is wrapping the columns header (horizontal)
/// or rows header (vertical).
///
/// See also:
/// - [SliverSwayzeTable.wrapHeader]
/// - [Header] that contains the caller for this builder.
typedef WrapHeaderBuilder = Widget Function(
  BuildContext context,
  ViewportContext viewportContext,
  Axis axis,
  Widget child,
);
