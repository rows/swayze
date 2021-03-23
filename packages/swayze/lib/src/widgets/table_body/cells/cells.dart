import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../controller.dart';
import '../../../core/delegates/cell_delegate.dart';
import '../../../core/style/style.dart';
import 'cell/cell.dart';

const _kRangeListEquality = ListEquality<double>();

/// Render and layout all cells that are being displayed given vertical and
/// horizontal scroll frame.
/// It takes the values from [ViewportContext] as params to ease update
/// comparison.
///
/// See also:
/// - [_CellsElement] that actually does the hard work of managing
///   visible cells.
class Cells<CellDataType extends SwayzeCellData> extends RenderObjectWidget {
  /// [ViewportAxisContextState.offsets] for columns
  final List<double> columnOffsets;

  /// [ViewportAxisContextState.offsets] for rows
  final List<double> rowOffsets;

  /// [ViewportAxisContextState.scrollableRange] for columns
  final Range horizontalRange;

  /// [ViewportAxisContextState.scrollableRange] for rows
  final Range verticalRange;

  /// [ViewportAxisContextState.visibleIndices] for columns
  final Iterable<int> visibleColumnsIndices;

  /// [ViewportAxisContextState.visibleIndices] for rows
  final Iterable<int> visibleRowsIndices;

  /// [ViewportAxisContextState.sizes] for columns
  final List<double> columnSizes;

  /// [ViewportAxisContextState.sizes] for rows
  final List<double> rowSizes;

  /// The scope that exposes Swayze state and controllers.
  final SwayzeController swayzeController;

  final SwayzeStyle swayzeStyle;

  final CellDelegate<CellDataType> cellDelegate;

  const Cells({
    Key? key,
    required this.columnOffsets,
    required this.rowOffsets,
    required this.horizontalRange,
    required this.verticalRange,
    required this.columnSizes,
    required this.rowSizes,
    required this.swayzeController,
    required this.swayzeStyle,
    required this.visibleColumnsIndices,
    required this.visibleRowsIndices,
    required this.cellDelegate,
  }) : super(key: key);

  @override
  RenderObjectElement createElement() {
    return _CellsElement<CellDataType>(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCells();
  }
}

/// The [Element] that controls the exhibition of cells on a table given the
/// state of the scroll.
///
/// This is the workhorse of the mechanism  that virtualizes cell widgets.
///
/// On a particular scroll event that changes the set of visible columns and
/// rows, this element:
/// - Keeps all alive cells;
/// - Instantiate new ones once they enter the screen;
/// - Finally, drop the ones that leave the viewport.
///
/// For non empty cells (cells with representation in the cells state) it
/// creates children using [Cell] as widget and [CellParentData] as parent
/// data.
///
/// It works like [MultiChildRenderObjectElement] but it saves child
/// elements in a [MatrixMap].
///
/// The cells are positioned and sized by [_RenderCells] according to its
/// [CellParentData] generated here.
///
/// See also:
/// - [VirtualizationCalculator] the widget that takes scroll constraints and
///   convert into [VirtualizationState];
/// - [ViewportContext] the source of truth in respect of the disposition
///   of the visible columns and rows;
/// - [_CellsElement.update] The core of the virtualization of cells.
class _CellsElement<CellDataType extends SwayzeCellData>
    extends RenderObjectElement {
  _CellsElement(Cells<CellDataType> widget) : super(widget);

  @override
  Cells<CellDataType> get widget => super.widget as Cells<CellDataType>;

  @override
  _RenderCells get renderObject => super.renderObject as _RenderCells;

  /// The children elements organized in a local [MatrixMap] indexed by
  /// cell coordinates.
  final MatrixMap<Element> children = MatrixMap<Element>();

  /// We keep a set of forgotten children to avoid O(n^2) work walking _children
  /// repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  /// Shorthand for the cellsController
  SwayzeCellsController<CellDataType> get cellsController =>
      widget.swayzeController.cellsController
          as SwayzeCellsController<CellDataType>;

  @override
  Future<void> insertRenderObjectChild(
    RenderBox child,
    IntVector2 slot,
  ) async {
    renderObject.insert(child, slot);
    assert(child.parent == renderObject);
  }

  @override
  void moveRenderObjectChild(
    RenderBox child,
    IntVector2 oldSlot,
    IntVector2 newSlot,
  ) {
    assert(child.parent == renderObject);
    renderObject.move(child, oldSlot, newSlot);
  }

  @override
  void removeRenderObjectChild(RenderBox child, IntVector2 slot) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    children.forEach((child, colIndex, rowIndex) {
      if (!_forgottenChildren.contains(child)) {
        visitor(child);
      }
    });
  }

  @override
  void forgetChild(Element child) {
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);

    // bind to cells store updates
    cellsController.addCellOperationsListener(markNeedsCellStoreSync);

    // create all cells on mount
    retrieveDataAndCreateChildren(
      colIndices: widget.visibleColumnsIndices,
      rowIndices: widget.visibleRowsIndices,
    );
  }

  @override
  void unmount() {
    // unbind to cells stores updates
    cellsController.removeCellOperationsListener(markNeedsCellStoreSync);
    super.unmount();
  }

  /// Find if there was an update in the cells controller that is waiting to
  /// take effect on the UI.
  ///
  /// It is marked by [markNeedsCellStoreSync] and unmarked by
  /// [cellControllerSync].
  bool hasPendingControllerSync = false;

  /// Stores the timestamp of the last sync with the cells store
  int lastControllerSync = DateTime.now().millisecondsSinceEpoch;

  /// Marks the element as unsynced with the cells store.
  ///
  /// It will make [cellControllerSync] to be invoked in the next [rebuild].
  void markNeedsCellStoreSync(List<CellOperation> lastPerformedOperations) {
    scheduleMicrotask(() {
      var affectsViewport = false;
      final viewport = Range2D.fromSides(
        widget.horizontalRange,
        widget.verticalRange,
      );

      for (final operation in lastPerformedOperations) {
        final affects = operation.affects(viewport);
        if (affects) {
          affectsViewport = true;
          break;
        }
      }

      // Only update widgets if the update has affected visible cells.
      if (!affectsViewport) {
        return;
      }

      hasPendingControllerSync = true;
      markNeedsBuild();
    });
  }

  /// From a single [SwayzeCellData], inflate a child widget and index on
  /// [children].
  void createChild(CellDataType cell) {
    final localColIndex = cell.position.dx - widget.horizontalRange.start;
    final localRowIndex = cell.position.dy - widget.verticalRange.start;

    final offset = Offset(
      widget.columnOffsets[localColIndex],
      widget.rowOffsets[localRowIndex],
    );
    final size = Size(
      widget.columnSizes[localColIndex],
      widget.rowSizes[localRowIndex],
    );

    final localPosition = IntVector2.from(cell.position);

    /// create child widget.
    final childWidget = Cell<CellDataType>(
      key: ObjectKey(cell.id),
      data: cell,
      selectionsController: widget.swayzeController.selection,
      swayzeStyle: widget.swayzeStyle,
      textDirection: TextDirection.ltr,
      cellDelegate: widget.cellDelegate,
    );
    final newChild = inflateWidget(childWidget, localPosition);

    // create and attach parent data to its render object.
    final parentData = CellParentData(
      offset: offset,
      size: size,
      position: localPosition,
      updateStamp: lastControllerSync,
    );
    newChild.renderObject!.parentData = parentData;

    // finally, add created element into the children matrix
    children[localPosition] = newChild;
  }

  /// From a list of [colIndices] and [rowIndices], seek for cells in the state
  /// and create widgets for each cell found.
  void retrieveDataAndCreateChildren({
    required Iterable<int> colIndices,
    required Iterable<int> rowIndices,
  }) =>
      cellsController.cellMatrixReadOnly.forEachExistingItemOn(
        colIndices: colIndices,
        rowIndices: rowIndices,
        iterate: (cell, _, __) {
          // skip empty cells
          if (cell.isPristine) {
            return;
          }
          createChild(cell);
        },
      );

  /// Check for changes on the ranges and update positioning.
  /// To be triggered when the virtualization changes the visible ranges.
  ///
  /// Returns `true` if there was a update in the visible ranges,
  /// `false` otherwise.
  bool checkAndHandleScrollUpdates({required Cells oldWidget}) {
    final afterHorizontalRange = widget.horizontalRange;
    final afterVerticalRange = widget.verticalRange;

    // maps ranges from before and after
    final beforeHorizontal = oldWidget.visibleColumnsIndices.toSet();
    final afterHorizontal = widget.visibleColumnsIndices.toSet();
    final beforeVertical = oldWidget.visibleRowsIndices.toSet();
    final afterVertical = widget.visibleRowsIndices.toSet();

    // if the scroll did not trigger update in any visible range,
    if (beforeHorizontal == afterHorizontal &&
        beforeVertical == afterVertical) {
      return false;
    }

    // compute the columns diff
    final columnsIndicesToRemove = beforeHorizontal.difference(afterHorizontal);
    final columnsIndicesToAdd = afterHorizontal.difference(beforeHorizontal);

    // compute the rows diff
    final rowsIndicesToRemove = beforeVertical.difference(afterVertical);

    final rowsIndicesToAdd = afterVertical.difference(beforeVertical);

    // Remove references for cells to be removed
    if (rowsIndicesToRemove.isNotEmpty || columnsIndicesToRemove.isNotEmpty) {
      for (final rowIndex in beforeVertical) {
        if (rowsIndicesToRemove.contains(rowIndex)) {
          children.forEachInRow(rowIndex, (child, colIndex, rowIndex) {
            deactivateChild(child);
          });
          children.clearRow(rowIndex);
          continue;
        }
        if (columnsIndicesToRemove.isEmpty) {
          continue;
        }
        children.forEachInRow(rowIndex, (child, colIndex, rowIndex) {
          if (columnsIndicesToRemove.contains(colIndex)) {
            deactivateChild(child);
          }
        });

        children.removeWhereInRow(
          rowIndex,
          (colIndex, child) => columnsIndicesToRemove.contains(colIndex),
        );
      }
    }

    // Update existing cells positions
    children.forEach((oldChild, colIndex, rowIndex) {
      final localColIndex = colIndex - afterHorizontalRange.start;
      final localRowIndex = rowIndex - afterVerticalRange.start;

      final offset = Offset(
        widget.columnOffsets[localColIndex],
        widget.rowOffsets[localRowIndex],
      );
      final size = Size(
        widget.columnSizes[localColIndex],
        widget.rowSizes[localRowIndex],
      );
      final parentData = CellParentData(
        offset: offset,
        size: size,
        position: IntVector2(colIndex, rowIndex),
        updateStamp: lastControllerSync,
      );

      oldChild.renderObject!.parentData = parentData;
      oldChild.renderObject!.markNeedsLayout();
    });

    // add new cells
    if (rowsIndicesToAdd.isNotEmpty || columnsIndicesToAdd.isNotEmpty) {
      for (final rowIndex in afterVertical) {
        // if this is not a new row
        if (rowsIndicesToAdd.contains(rowIndex)) {
          retrieveDataAndCreateChildren(
            rowIndices: [rowIndex],
            colIndices: widget.visibleColumnsIndices,
          );
        } else {
          retrieveDataAndCreateChildren(
            rowIndices: [rowIndex],
            colIndices: columnsIndicesToAdd,
          );
        }
      }
    }

    return true;
  }

  /// Check for changes on the sizes of the visible headers and
  /// update positioning.
  ///
  /// Returns `true` if there was a update in the visible headers,
  /// `false` otherwise.
  bool checkAndHandleHeaderUpdates({required Cells oldWidget}) {
    final beforeSizesHorizontal = oldWidget.columnSizes;
    final afterSizesHorizontal = widget.columnSizes;
    final beforeSizesVertical = oldWidget.rowSizes;
    final afterSizesVertical = widget.rowSizes;

    if (_kRangeListEquality.equals(
          beforeSizesHorizontal,
          afterSizesHorizontal,
        ) &&
        _kRangeListEquality.equals(
          beforeSizesVertical,
          afterSizesVertical,
        )) {
      return false;
    }

    children.forEach((oldChild, colIndex, rowIndex) {
      final localColIndex = colIndex - widget.horizontalRange.start;
      final localRowIndex = rowIndex - widget.verticalRange.start;

      final offset = Offset(
        widget.columnOffsets[localColIndex],
        widget.rowOffsets[localRowIndex],
      );
      final size = Size(
        widget.columnSizes[localColIndex],
        widget.rowSizes[localRowIndex],
      );
      final parentData = CellParentData(
        offset: offset,
        size: size,
        position: IntVector2(colIndex, rowIndex),
        updateStamp: lastControllerSync,
      );

      oldChild.renderObject!.parentData = parentData;
      oldChild.renderObject!.markNeedsLayout();
    });

    return true;
  }

  /// Sync the cells display with the current cell controller.
  void cellControllerSync() {
    // if there is no pending sync, do nothing.
    if (!hasPendingControllerSync) {
      return;
    }

    hasPendingControllerSync = false;
    lastControllerSync = DateTime.now().millisecondsSinceEpoch;

    cellsController.cellMatrixReadOnly.forEachExistingItemOn(
      colIndices: widget.visibleColumnsIndices,
      rowIndices: widget.visibleRowsIndices,
      iterate: (cell, colIndex, rowIndex) {
        // empty cells are ignored
        if (cell.isPristine) {
          return;
        }

        final existingChild = children[cell.position];

        if (existingChild != null) {
          final widget = existingChild.widget as Cell<CellDataType>;

          if (widget.data == cell) {
            /// if the data hasn't changed, just mark as up to date and move on
            (existingChild.renderObject!.parentData! as CellParentData)
                .updateStamp = lastControllerSync;
            return;
          }

          final existingParentData = existingChild.renderObject!.parentData;

          /// Create a new widget with up to date data
          final childWidget = Cell(
            key: ObjectKey(cell.id),
            data: cell,
            selectionsController: widget.selectionsController,
            swayzeStyle: widget.swayzeStyle,
            textDirection: widget.textDirection,
            cellDelegate: widget.cellDelegate,
          );

          final newChild = updateChild(
            existingChild,
            childWidget,
            cell.position,
          )!;

          newChild.renderObject!.parentData = existingParentData;

          // mark new child as up to date
          (newChild.renderObject!.parentData! as CellParentData).updateStamp =
              lastControllerSync;

          // finally, add created element into the children matrix
          children[cell.position] = newChild;
        } else {
          // if it is a newly inserted child, create brand new widgets
          createChild(cell);
        }
      },
    );

    // flush every child that was not marked as up to date
    children.removeWhere((rowIndex, colIndex, child) {
      final parentData = child.renderObject!.parentData! as CellParentData;
      final gonnaRemove = parentData.updateStamp != lastControllerSync;

      if (gonnaRemove) {
        deactivateChild(child);
      }

      return gonnaRemove;
    });
  }

  @override
  void rebuild() {
    super.rebuild();
    // Sync with cells store if necessary
    cellControllerSync();
  }

  @override
  void update(Cells newWidget) {
    // keep a reference for the widget prior to updates
    final oldWidget = widget;
    super.update(newWidget);
    // after super.update, widget should be the new one
    assert(widget == newWidget);

    final isScrollUpdate = checkAndHandleScrollUpdates(oldWidget: oldWidget);

    if (!isScrollUpdate) {
      checkAndHandleHeaderUpdates(oldWidget: oldWidget);
    }
  }
}

/// The [Cells]'s [RenderObject].
///
/// It is responsible for positioning and rendering each cell render object
/// from the parent data set by [RenderObjectElement].
///
/// As well as [_CellsElement], this keeps children organized in a [MatrixMap].
class _RenderCells extends RenderBox {
  final MatrixMap<RenderBox> children = MatrixMap();

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  /// Insert child into this render object's child matrix [at] the given place.
  ///
  /// Called by [_CellsElement.insertRenderObjectChild] when a new cell widget
  /// is inflated as child.
  void insert(RenderBox child, IntVector2 at) {
    adoptChild(child);
    children[at] = child;
  }

  /// Remove this child from the child matrix.
  ///
  /// Requires the child to be present in the child matrix.
  ///
  /// Called by [_CellsElement.removeRenderObjectChild] when a child should be
  /// removed.
  void remove(RenderBox child) {
    final data = (child.parentData as CellParentData?)!.position;
    children.remove(
      colIndex: data.dx,
      rowIndex: data.dy,
    );
    dropChild(child);
  }

  /// Move the given `child` in the child matrix [from] a place [to] another.
  ///
  /// Requires that [child] be located exactly on [from].
  void move(RenderBox child, IntVector2 from, IntVector2 to) {
    final actualChildAtNewPosition = children[to];
    if (actualChildAtNewPosition == child) {
      return;
    }
    assert(
      children[from] != child,
      'Tried to move a child from a different place.',
    );
    children.remove(
      colIndex: from.dx,
      rowIndex: from.dy,
    );

    children[to] = child;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    children.forEach((child, colIndex, rowIndex) {
      child.attach(owner);
    });
  }

  @override
  void detach() {
    super.detach();
    children.forEach((child, colIndex, rowIndex) {
      child.detach();
    });
  }

  @override
  void redepthChildren() {
    children.forEach((child, colIndex, rowIndex) {
      redepthChild(child);
    });
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    children.forEach((child, colIndex, rowIndex) {
      visitor(child);
    });
  }

  @override
  void performLayout() {
    children.forEach((child, colIndex, rowIndex) {
      child.layout(
        BoxConstraints.loose(
          (child.parentData as CellParentData?)!.size,
        ),
      );
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // This is inevitably O(n^2) , so we need to be extra careful with
    // performance inside this loop and in the cells paint.
    children.forEach((child, colIndex, rowIndex) {
      final childOffset =
          (child.parentData as CellParentData?)!.offset + offset;
      context.pushLayer(
        OffsetLayer(offset: childOffset),
        (PaintingContext context, Offset offset) {
          context.paintChild(child, offset);
        },
        offset,
      );
    });
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    late var isAnyHit = false;

    children.forEach((child, colIndex, rowIndex) {
      final childOffset = (child.parentData as CellParentData?)!.offset;
      final rect = childOffset & child.size;
      if (!rect.contains(position)) {
        return;
      }

      final isHit = result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformed) {
          assert(transformed == position - childOffset);
          return child.hitTest(result, position: transformed!);
        },
      );

      if (isHit) {
        isAnyHit = true;
      }
    });

    return isAnyHit;
  }
}

/// A set of information for [Cells] to decide where to render a particular
/// visible cell.
@visibleForTesting
class CellParentData extends ContainerBoxParentData<_RenderCells> {
  /// The exact size in pixel of this cell
  final Size size;

  /// The local coordinates of this cell.
  final IntVector2 position;

  /// A stamp of the last update that was processed over a particular cell.
  int updateStamp;

  CellParentData({
    required Offset offset,
    required this.size,
    required this.position,
    required this.updateStamp,
  }) {
    this.offset = offset;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellParentData &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          position == other.position &&
          updateStamp == other.updateStamp;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => size.hashCode ^ position.hashCode ^ updateStamp.hashCode;
}
