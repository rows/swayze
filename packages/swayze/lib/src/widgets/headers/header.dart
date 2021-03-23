import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../core/controller/selection/selection_controller.dart';
import '../../core/internal_state/table_focus/table_focus_provider.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../../core/viewport_context/viewport_context_provider.dart';
import '../internal_scope.dart';
import '../shared/expand_all.dart';
import '../wrappers.dart';
import 'gestures/header_gesture_detector.dart';
import 'header_displacer.dart';
import 'header_item.dart';

/// A [StatelessWidget] that wraps widgets of a header on an axis.
///
/// This includes header background, separators, gesture detectors and labels.
///
/// It adds the default header background, clips overflow, and position the
/// headers according to the specified displacement.
///
/// Headers are axis agnostic, to specify if its will render either in a
/// vertical or horizontal disposition, it checks the
/// [virtualizationState.axis].
class Header extends StatelessWidget {
  final Axis axis;
  final double displacement;
  final WrapHeaderBuilder? wrapHeader;

  const Header({
    Key? key,
    required this.axis,
    required this.displacement,
    required this.wrapHeader,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewportContext = ViewportContextProvider.of(context);

    final rangeNotifier = viewportContext.getAxisContextFor(axis: axis);

    final pixelExtent =
        viewportContext.getAxisContextFor(axis: axis).value.extent;

    final style = InternalScope.of(context).style;

    final wrapHeader = this.wrapHeader;

    Widget headerContent = _HeaderRangeSubscriber(
      axis: axis,
      rangeNotifier: rangeNotifier,
      displacement: displacement,
      background: style.defaultHeaderPalette.background,
    );

    if (wrapHeader != null) {
      headerContent = wrapHeader(context, viewportContext, axis, headerContent);
    }

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(color: style.defaultHeaderPalette.background),
        child: CustomSingleChildLayout(
          delegate: _HeaderLayoutDelegate(axis, displacement, pixelExtent),
          child: headerContent,
        ),
      ),
    );
  }
}

/// A [SingleChildLayoutDelegate] that translates a child according to the
/// [axis] displacement.
///
/// This enables pixel scrolling on headers.
@immutable
class _HeaderLayoutDelegate extends SingleChildLayoutDelegate {
  final Axis axis;
  final double displacement;
  final double pixelExtent;

  const _HeaderLayoutDelegate(this.axis, this.displacement, this.pixelExtent);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Make children have enough size to fit all visible header items.
    final maxWidth = axis == Axis.vertical ? constraints.maxWidth : pixelExtent;
    final maxHeight =
        axis == Axis.vertical ? pixelExtent : constraints.maxHeight;

    return BoxConstraints.tight(
      constraints.constrain(Size(maxWidth, maxHeight)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = axis == Axis.vertical ? 0.0 : displacement;
    final y = axis == Axis.vertical ? displacement : 0.0;

    // Translate the child widget according to the specified displacement
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _HeaderLayoutDelegate oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HeaderLayoutDelegate &&
          runtimeType == other.runtimeType &&
          axis == other.axis &&
          displacement == other.displacement &&
          pixelExtent == other.pixelExtent;

  @override
  int get hashCode =>
      axis.hashCode ^ displacement.hashCode ^ pixelExtent.hashCode;
}

/// Data structure to hold the [RangeCompactList]s of headers that are selected
/// or which cells contain a selection and therefore should be highlighted.
class _HeaderModeRangeLists {
  RangeCompactList selectedRangeList;
  RangeCompactList highlightedRangeList;

  _HeaderModeRangeLists({
    required this.selectedRangeList,
    required this.highlightedRangeList,
  });
}

/// Collapse the given [selections] into the minimum amount of ranges possible
/// within the given [Range] for the provided [Axis] grouped
/// by [HeaderStyleState]
_HeaderModeRangeLists _getHeaderModeRangeLists(
  Iterable<UserSelectionModel> selections,
  Axis axis,
  Range target,
) {
  final selectedRangeList = RangeCompactList();
  final highlightedRangeList = RangeCompactList();

  for (final selection in selections) {
    if (selection is CellUserSelectionModel) {
      highlightedRangeList
          .add(axis == Axis.horizontal ? selection.xRange : selection.yRange);
    }

    if (selection is TableUserSelectionModel ||
        (selection is HeaderUserSelectionModel && selection.axis != axis)) {
      highlightedRangeList.add(target.clone());
    }

    if (selection is HeaderUserSelectionModel && selection.axis == axis) {
      selectedRangeList.add(Range(selection.start, selection.end));
    }
  }

  return _HeaderModeRangeLists(
    selectedRangeList: selectedRangeList & target,
    highlightedRangeList: highlightedRangeList & target,
  );
}

/// A [StatefulWidget] that listen for changes in the range and displays the
/// headers accordingly.
class _HeaderRangeSubscriber extends StatefulWidget {
  final Axis axis;
  final double displacement;
  final ValueListenable<ViewportAxisContextState> rangeNotifier;
  final Color background;

  const _HeaderRangeSubscriber({
    Key? key,
    required this.axis,
    required this.rangeNotifier,
    required this.displacement,
    required this.background,
  }) : super(key: key);

  @override
  _HeaderRangeSubscriberState createState() => _HeaderRangeSubscriberState();
}

class _HeaderRangeSubscriberState extends State<_HeaderRangeSubscriber> {
  late final internalScope = InternalScope.of(context);
  late final style = internalScope.style;
  late final SwayzeSelectionController selectionController =
      internalScope.controller.selection;
  late final tableFocus = TableFocus.of(context);
  late ViewportAxisContextState viewportAxisContextState;
  late List<HeaderStyleState> headerStyleStates;

  @override
  void initState() {
    super.initState();

    // Set initial values
    viewportAxisContextState = widget.rangeNotifier.value;
    headerStyleStates = _getHeadersHeaderStyleState();

    // Listen for changes in ranges and selections
    widget.rangeNotifier.addListener(onRangeChange);
    selectionController.userSelectionsListenable.addListener(
      onSelectionsChange,
    );
    tableFocus.addListener(onFocusChanged);
  }

  @override
  void dispose() {
    widget.rangeNotifier.removeListener(onRangeChange);
    selectionController.userSelectionsListenable.removeListener(
      onSelectionsChange,
    );
    tableFocus.removeListener(onFocusChanged);
    super.dispose();
  }

  /// Sets the list of [HeaderStyleState] for all header positions in the
  /// given [Axis] for the current [Range].
  ///
  /// If the current node is not focused, then we don't render any
  /// selections cue.
  List<HeaderStyleState> _getHeadersHeaderStyleState() {
    final frozenCount = viewportAxisContextState.frozenOffsets.length;
    final range = viewportAxisContextState.scrollableRange;

    // When not active, just assume all headers have "normal" style
    if (!tableFocus.value.isActive) {
      return List.filled(
        range.iterable.length + frozenCount,
        HeaderStyleState.normal,
      );
    }

    final selections = selectionController.userSelectionState.selections;
    final result = <HeaderStyleState>[];

    // Add styles for frozen headers
    if (frozenCount > 0) {
      final frozenRangeLists = _getHeaderModeRangeLists(
        selections,
        widget.axis,
        Range(0, frozenCount),
      );

      // Iterate on the frozen range and check the expected background mode
      for (var index = 0; index < frozenCount; index++) {
        if (frozenRangeLists.selectedRangeList
            .where((value) => value.contains(index))
            .isNotEmpty) {
          result.add(HeaderStyleState.selected);
        } else if (frozenRangeLists.highlightedRangeList
            .where((value) => value.contains(index))
            .isNotEmpty) {
          result.add(HeaderStyleState.highlighted);
        } else {
          result.add(HeaderStyleState.normal);
        }
      }
    }

    final rangeLists = _getHeaderModeRangeLists(selections, widget.axis, range);
    // Iterate the target range and check the expected background mode
    for (final index in range.iterable) {
      if (rangeLists.selectedRangeList
          .where((value) => value.contains(index))
          .isNotEmpty) {
        result.add(HeaderStyleState.selected);
      } else if (rangeLists.highlightedRangeList
          .where((value) => value.contains(index))
          .isNotEmpty) {
        result.add(HeaderStyleState.highlighted);
      } else {
        result.add(HeaderStyleState.normal);
      }
    }

    return result;
  }

  /// Handles changes to [FocusNode] focus state. It recomputes the
  /// [headerStyleStates] with the new state of focus.
  void onFocusChanged() {
    final styles = _getHeadersHeaderStyleState();
    setState(() {
      headerStyleStates = styles;
    });
  }

  /// Handles changes to [widget.rangeNotifier]. It sets the new range and
  /// recomputes [headerSizes] and [headerStyleStates].
  void onRangeChange() {
    setState(() {
      viewportAxisContextState = widget.rangeNotifier.value;
    });

    final styles = _getHeadersHeaderStyleState();
    setState(() {
      headerStyleStates = styles;
    });
  }

  /// Handles changes to [selectionController]. It recomputes the
  /// [headerStyleStates] with the new selections state.
  void onSelectionsChange() {
    final styles = _getHeadersHeaderStyleState();
    setState(() {
      headerStyleStates = styles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = viewportAxisContextState.scrollableRange.start;

    final frozenExtent = widget.rangeNotifier.value.frozenExtent;
    final frozenCount = widget.rangeNotifier.value.frozenOffsets.length;

    // No headers, no widgets.
    if (headerStyleStates.isEmpty) {
      return const SizedBox.shrink();
    }

    // First add widgets for frozen headers
    final headers = <HeaderItem>[];
    for (var index = 0; index < frozenCount; index++) {
      final extent = viewportAxisContextState.frozenSizes[index];
      if (extent > 0) {
        headers.add(
          HeaderItem(
            key: ValueKey('frozen-$index'),
            index: index,
            axis: widget.axis,
            extent: extent,
            styleState: headerStyleStates[index],
            swayzeStyle: style,
          ),
        );
      }
    }

    // Then add widgets for the range headers
    for (final index in viewportAxisContextState.scrollableRange.iterable) {
      final relativeIndex = index - initial;

      final extent = viewportAxisContextState.sizes[relativeIndex];
      if (extent > 0) {
        headers.add(
          HeaderItem(
            key: ValueKey(index),
            index: index,
            axis: widget.axis,
            extent: extent,
            styleState: headerStyleStates[relativeIndex + frozenCount],
            swayzeStyle: style,
          ),
        );
      }
    }

    return ExpandAll(
      children: [
        HeaderDisplacer(
          axis: widget.axis,
          children: headers,
          frozenExtent: frozenExtent,
          frozenCount: frozenCount,
          displacement: widget.displacement,
          background: widget.background,
        ),
        HeaderGestureDetector(
          axis: widget.axis,
          displacement: widget.displacement,
        ),
      ],
    );
  }
}
