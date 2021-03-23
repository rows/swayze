import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../../intents.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../internal_scope.dart';

/// Defines the default behavior swayze will take when some [SwayzeIntent]s
/// are emitted.
///
/// Subclasses of this should be added to [DefaultActions] wrapped with
/// [Action.overridable]
abstract class DefaultSwayzeAction<T extends SwayzeIntent>
    extends ContextAction<T> {
  final InternalScope internalScope;
  final ViewportContext viewportContext;

  DefaultSwayzeAction(
    this.internalScope,
    this.viewportContext,
  );

  @override
  @nonVirtual
  void invoke(T intent, [BuildContext? context]) {
    invokeAction(intent, context!);
  }

  void invokeAction(T intent, BuildContext context);

  /// Instantly make this action [overridable] for [context].
  Action overridable(BuildContext context) {
    return Action.overridable(
      defaultAction: this,
      context: context,
    );
  }
}
