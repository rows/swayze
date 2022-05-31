import 'package:flutter/widgets.dart';

import '../../../internal_scope.dart';
import 'header_edge_info.dart';

class ResizeHeaderDetailsNotifier extends ValueNotifier<ResizeHeaderDetails?> {
  ResizeHeaderDetailsNotifier(ResizeHeaderDetails? value) : super(value);

  bool get isHoveringHeaderEdge => value?.edgeInfo.index != null;

  bool get isResizingHeader => value?.offset != null;
}

class ResizeHeaderDetailsNotifierProvider
    extends InheritedNotifier<ResizeHeaderDetailsNotifier> {
  const ResizeHeaderDetailsNotifierProvider({
    Key? key,
    required ResizeHeaderDetailsNotifier? notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static ResizeHeaderDetailsNotifier? of(BuildContext context) {
    final internalScope = InternalScope.of(context);

    if (!internalScope.config.isResizingHeadersEnabled) {
      return null;
    }

    return context
        .dependOnInheritedWidgetOfExactType<
            ResizeHeaderDetailsNotifierProvider>()
        ?.notifier;
  }
}

@immutable
class ResizeHeaderDetails {
  final HeaderEdgeInfo edgeInfo;
  final Axis axis;

  /// The offset when the user has started resizing the header.
  final double? initialOffset;

  /// The minimum offset that the resize line can go to.
  final double? minOffset;

  /// The current offset of the resize line.
  final double? offset;

  const ResizeHeaderDetails({
    required this.edgeInfo,
    required this.axis,
    this.initialOffset,
    this.minOffset,
    this.offset,
  });

  ResizeHeaderDetails copyWith({
    HeaderEdgeInfo? edgeInfo,
    double? initialOffset,
    double? minOffset,
    double? offset,
  }) {
    return ResizeHeaderDetails(
      edgeInfo: edgeInfo ?? this.edgeInfo,
      axis: axis,
      initialOffset: initialOffset ?? this.initialOffset,
      minOffset: minOffset ?? this.minOffset,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResizeHeaderDetails &&
        other.edgeInfo == edgeInfo &&
        other.axis == axis &&
        other.initialOffset == initialOffset &&
        other.minOffset == minOffset &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return edgeInfo.hashCode ^
        axis.hashCode ^
        initialOffset.hashCode ^
        minOffset.hashCode ^
        offset.hashCode;
  }
}
