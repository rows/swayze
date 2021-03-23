import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../helpers/scroll/auto_scroll.dart';

const _kMaxVelocity = 3.0;

class _ScrollTicker {
  void Function(double dt) callback;
  Duration previous = Duration.zero;
  late Ticker _ticker;

  _ScrollTicker(this.callback) {
    _ticker = Ticker(_tick);
  }

  void _tick(Duration timestamp) {
    final dt = _computeDeltaT(timestamp);
    callback(dt);
  }

  double _computeDeltaT(Duration now) {
    final delta = previous == Duration.zero ? Duration.zero : now - previous;
    previous = now;
    return delta.inMicroseconds / Duration.millisecondsPerSecond;
  }

  void start() {
    _ticker.start();
  }

  void stop() {
    _ticker.stop();
  }

  void dispose() {
    _ticker.dispose();
  }
}

/// Returns [maxToScroll] or, if none is defined, returns
/// [position.extentAfter] or [position.extentBefore] depending on the given
/// [GrowthDirection].
double _getMaxToScroll({
  double? maxToScroll,
  required ScrollPosition position,
  required GrowthDirection direction,
}) {
  final extent = direction == GrowthDirection.forward
      ? position.extentAfter
      : position.extentBefore;

  if (maxToScroll != null) {
    return min(maxToScroll, extent);
  }

  return extent;
}

/// Controller for a [AutoScrollActivity], it allows to compute the scroll
/// velocity based on the current pointer distance.
class AutoScrollController {
  double pointerDistance;

  AutoScrollController({required this.pointerDistance});

  double get velocity {
    final distanceRatio = pointerDistance / kAutoScrollTriggerThreshold;
    final powerVelocity = pow(3.0, distanceRatio).toDouble() - 1;
    return min<double>(powerVelocity, _kMaxVelocity);
  }
}

/// [ScrollActivity] that keeps the scrolling indefinetly in a given
/// [GrowthDirection] at a given [velocity].
class AutoScrollActivity extends ScrollActivity {
  /// If applicable, the velocity at which the scroll offset is currently
  /// independently changing (i.e. without external stimuli such as a dragging
  /// gestures) in logical pixels per second for this activity.
  final AutoScrollController controller;

  /// The direction in which the scroll offset increases.
  final GrowthDirection direction;

  /// Maximium offset to scroll.
  final double maxToScroll;

  /// Amount already scrolled
  double scrolledAccumulator = 0.0;

  /// Track if its currently scrolling
  bool _isScrolling = true;

  late _ScrollTicker ticker = _ScrollTicker(onTick);

  AutoScrollActivity({
    required ScrollActivityDelegate delegate,
    required ScrollPosition position,
    required this.direction,
    required this.controller,
    double? maxToScroll,
  })  : maxToScroll = _getMaxToScroll(
          maxToScroll: maxToScroll,
          direction: direction,
          position: position,
        ),
        super(delegate);

  @override
  void dispatchScrollStartNotification(
    ScrollMetrics metrics,
    BuildContext? context,
  ) {
    super.dispatchScrollStartNotification(metrics, context);
    ticker.start();
  }

  /// On every tick apply an increased offset with the defined [velocity]
  /// in the provided [direction].
  @visibleForTesting
  void onTick(double deltaTime) {
    if (scrolledAccumulator >= maxToScroll) {
      delegate.goIdle();
      return;
    }

    var distance = deltaTime * velocity;
    if (scrolledAccumulator + distance > maxToScroll) {
      // make sure we do not o verscroll.
      distance = maxToScroll - scrolledAccumulator;
    }

    scrolledAccumulator = scrolledAccumulator + distance;
    final deltaDistance =
        direction == GrowthDirection.forward ? -distance : distance;

    if (deltaDistance == 0) {
      return;
    }

    delegate.applyUserOffset(deltaDistance);
  }

  @override
  void dispose() {
    ticker.stop();
    ticker.dispose();
    scrolledAccumulator = 0.0;
    _isScrolling = false;
    super.dispose();
  }

  @override
  bool get isScrolling => _isScrolling;

  @override
  bool get shouldIgnorePointer => false;

  @override
  double get velocity => controller.velocity;
}
