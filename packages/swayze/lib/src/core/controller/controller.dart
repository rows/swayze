import '../../widgets/table.dart';
import 'cells/cells_controller.dart';
import 'controller_base.dart';
import 'editor/inline_editor_controller.dart';
import 'scroll/scroll_controller.dart';
import 'selection/selection_controller.dart';
import 'table/table_controller.dart';
export 'cells/cells_controller.dart';
export 'cells/cells_controller_operations.dart';
export 'controller_base.dart';
export 'scroll/scroll_controller.dart' hide ScrollControllerAttacher;
export 'selection/selection_controller.dart';
export 'table/table_controller.dart';

/// The main controller on swayze.
///
/// A controller is way of widgets providing an API for having parts of its
/// state to be controlled externally.
///
/// [SwayzeController] allows changes to be made to a table during its lifetime
/// from inside an outside the [SliverSwayzeTable] widget.
///
/// Each controller instance should be passed to a single [SliverSwayzeTable]
/// and disposed when the table is supposed to leave the widget tree.
///
/// See also:
/// - [SwayzeSelectionController] the state for selections.
/// - [SwayzeTableDataController] for table meta and columns/rows state
/// - [SwayzeCellsController] for managing all the cells of the table
abstract class SwayzeController extends ControllerBase {
  /// The controller that contains the state related to selections on the table.
  late final selection = SwayzeSelectionController();
  late final scroll = SwayzeScrollController(this);
  late final inlineEditor = SwayzeInlineEditorController();

  /// The controller that contains the state related to columns/rows and the
  /// table's meta information.
  SwayzeTableDataController get tableDataController;
  SwayzeCellsController get cellsController;

  @override
  void dispose() {
    selection.dispose();
    scroll.dispose();
    inlineEditor.dispose();
  }
}
