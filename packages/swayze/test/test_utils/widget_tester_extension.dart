import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Util extensions for [WidgetTester].
extension WidgetTesterExtension on WidgetTester {
  /// Dispatch two pointer down / pointer up sequences at the given location,
  /// with enough delay between sequences to trigger a double tap.
  Future<void> doubleTapAt(
    Offset offset, {
    Duration delayDuration = const Duration(milliseconds: 10),
  }) async {
    await tapAt(offset);
    await pumpAndSettle(kDoubleTapMinTime + delayDuration);
    await tapAt(offset);
    await pumpAndSettle();
  }
}
