import 'package:flutter_test/flutter_test.dart';

import 'package:swayze/src/helpers/keyed_notifier/keyed_notifier.dart';

void main() {
  test('Fires only necessary stuff', () {
    bool? hasFiredForKey1;
    bool? hasFiredForKey2;
    bool? hasFiredForKey3;

    final notifier = KeyedNotifier<int>()
      ..setListenerForKey(1, (value) {
        hasFiredForKey1 = value;
      })
      ..setListenerForKey(2, (value) {
        hasFiredForKey2 = value;
      })
      ..setListenerForKey(3, (value) {
        hasFiredForKey3 = value;
      });

    notifier.setKey(1);

    expect(hasFiredForKey1, equals(true));
    expect(hasFiredForKey2, equals(null));
    expect(hasFiredForKey3, equals(null));

    notifier.setKey(2);

    expect(hasFiredForKey1, equals(false));
    expect(hasFiredForKey2, equals(true));
    expect(hasFiredForKey3, equals(null));

    notifier.setKey(3);

    expect(hasFiredForKey1, equals(false));
    expect(hasFiredForKey2, equals(false));
    expect(hasFiredForKey3, equals(true));
  });
}
