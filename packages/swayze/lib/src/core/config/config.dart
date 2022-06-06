import 'package:meta/meta.dart';

/// A set of configurations to enable and disable certain interactions with
/// Swayze widgets.
@immutable
class SwayzeConfig {
  /// Enables drag and drop of selected headers (rows and columns).
  final bool isHeaderDragAndDropEnabled;

  final bool isResizingHeadersEnabled;

  const SwayzeConfig({
    this.isHeaderDragAndDropEnabled = false,
    this.isResizingHeadersEnabled = false,
  });

  SwayzeConfig copyWith({
    bool? isHeaderDragAndDropEnabled,
    bool? isResizingHeadersEnabled,
  }) =>
      SwayzeConfig(
        isHeaderDragAndDropEnabled:
            isHeaderDragAndDropEnabled ?? this.isHeaderDragAndDropEnabled,
        isResizingHeadersEnabled:
            isResizingHeadersEnabled ?? this.isResizingHeadersEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeConfig &&
          isHeaderDragAndDropEnabled == other.isHeaderDragAndDropEnabled &&
          isResizingHeadersEnabled == other.isResizingHeadersEnabled;

  @override
  int get hashCode =>
      isHeaderDragAndDropEnabled.hashCode ^ isResizingHeadersEnabled.hashCode;
}
