import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayze/src/helpers/keyed_notifier/keyed_notifier.dart';
import 'package:swayze/src/helpers/keyed_notifier/keyed_notifier_builder.dart';

void main() {
  testWidgets('Fires only necessary stuff', (tester) async {
    final notifier = KeyedNotifier<int>();
    final keyedBuilder = KeyedNotifierBuilder(
      keyedNotifier: notifier,
      keyToListenTo: 1,
      builder: (_, selected) {
        return Text('Selected: $selected');
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: keyedBuilder,
      ),
    );

    final textFinderBeforeUpdate = find.text('Selected: false');

    expect(textFinderBeforeUpdate, findsNWidgets(1));

    notifier.setKey(1);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: keyedBuilder,
      ),
    );

    final textFinderAfterUpdate = find.text('Selected: true');

    expect(textFinderAfterUpdate, findsNWidgets(1));
  });
}
