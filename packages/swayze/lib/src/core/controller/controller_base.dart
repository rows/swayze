import 'package:flutter/foundation.dart';

import 'controller.dart';

/// A base class for all controllers and sub controllers on swayze.
///
/// Controller that are created by [SwayzeController] should
/// subclass [SubController].
///
/// See also:
/// - [SwayzeController] for a controller that contains sub controllers.
/// - [SubController] controllers contained by [SwayzeController] should extend
///   this class.
abstract class ControllerBase {
  /// When set to be removed, controllers may have listeners and other
  /// references that may create memory dead dependency. [dispose] should drop
  /// such references.
  @mustCallSuper
  void dispose();
}

/// A controller that manages state related to data, usually
/// provided externally to [SwayzeController].
///
/// See also:
/// - [SwayzeTableDataController] an example of [DataController].
abstract class DataController extends ControllerBase {}

/// A controller to be created by [SwayzeController] and have access
/// to it via [parent].
///
/// See also:
/// - [SwayzeSelectionController] an example of [SubController].
abstract class SubController<ParentType extends SwayzeController>
    extends ControllerBase {
  /// The [SwayzeController] that has created this sub-controller.
  final ParentType parent;

  SubController(this.parent);
}
