import 'package:meta/meta.dart';

/// A set of configurations to enable and disable certain interactions with
/// Swayze widgets.
@immutable
class SwayzeConfig {
  /// Enables drag and drop of selected headers (rows and columns).
  final bool isHeaderDragAndDropEnabled;

  const SwayzeConfig({
    this.isHeaderDragAndDropEnabled = false,
  });

  SwayzeConfig copyWith({
    bool? isHeaderDragAndDropEnabled,
  }) =>
      SwayzeConfig(
        isHeaderDragAndDropEnabled:
            isHeaderDragAndDropEnabled ?? this.isHeaderDragAndDropEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeConfig &&
          isHeaderDragAndDropEnabled == other.isHeaderDragAndDropEnabled;

  @override
  int get hashCode => isHeaderDragAndDropEnabled.hashCode;
}
