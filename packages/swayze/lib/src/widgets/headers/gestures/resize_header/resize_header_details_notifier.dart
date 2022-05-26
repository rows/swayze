import 'package:flutter/widgets.dart';

class ResizeHeaderDetailsNotifier
    extends InheritedNotifier<ValueNotifier<ResizeHeaderDetails?>> {
  const ResizeHeaderDetailsNotifier({
    Key? key,
    required ValueNotifier<ResizeHeaderDetails?>? notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static ValueNotifier<ResizeHeaderDetails?> of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ResizeHeaderDetailsNotifier>()!
        .notifier!;
  }
}

@immutable
class ResizeHeaderDetails {
  final int index;
  final Axis axis;
  final double? offset;

  const ResizeHeaderDetails({
    required this.index,
    required this.axis,
    this.offset,
  });

  ResizeHeaderDetails copyWith({
    int? index,
    double? offset,
  }) {
    return ResizeHeaderDetails(
      index: index ?? this.index,
      axis: axis,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResizeHeaderDetails &&
        other.index == index &&
        other.offset == offset &&
        other.axis == axis;
  }

  @override
  int get hashCode => index.hashCode ^ offset.hashCode ^ axis.hashCode;
}
