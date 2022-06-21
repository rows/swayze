import 'package:meta/meta.dart';

/// A set of configurations to enable and disable certain interactions with
/// Swayze widgets.
@immutable
class SwayzeConfig {
  /// Enables the drag of the bottom right corner of the cell to
  /// allow for drag and fill values.
  final bool isDragFillEnabled;

  /// Enables drag and drop of selected headers (rows and columns).
  final bool isHeaderDragAndDropEnabled;

  final bool isResizingHeadersEnabled;

  const SwayzeConfig({
    this.isDragFillEnabled = false,
    this.isHeaderDragAndDropEnabled = false,
    this.isResizingHeadersEnabled = false,
  });

  SwayzeConfig copyWith({
    bool? isDragFillEnabled,
    bool? isHeaderDragAndDropEnabled,
    bool? isResizingHeadersEnabled,
  }) =>
      SwayzeConfig(
        isDragFillEnabled: isDragFillEnabled ?? this.isDragFillEnabled,
        isHeaderDragAndDropEnabled:
            isHeaderDragAndDropEnabled ?? this.isHeaderDragAndDropEnabled,
        isResizingHeadersEnabled:
            isResizingHeadersEnabled ?? this.isResizingHeadersEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeConfig &&
          isDragFillEnabled == other.isDragFillEnabled &&
          isHeaderDragAndDropEnabled == other.isHeaderDragAndDropEnabled &&
          isResizingHeadersEnabled == other.isResizingHeadersEnabled;

  @override
  int get hashCode =>
      isDragFillEnabled.hashCode ^
      isHeaderDragAndDropEnabled.hashCode ^
      isResizingHeadersEnabled.hashCode;
}
