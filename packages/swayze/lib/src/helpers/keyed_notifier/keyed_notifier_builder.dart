import 'package:flutter/widgets.dart';

import 'keyed_notifier.dart';

class KeyedNotifierBuilder<Subject> extends StatefulWidget {
  final KeyedNotifier<Subject> keyedNotifier;
  final Subject keyToListenTo;
  final Widget Function(BuildContext context, bool update) builder;

  const KeyedNotifierBuilder({
    Key? key,
    required this.keyedNotifier,
    required this.keyToListenTo,
    required this.builder,
  }) : super(key: key);

  @override
  State<KeyedNotifierBuilder<Subject>> createState() =>
      _KeyedNotifierBuilderState<Subject>();
}

class _KeyedNotifierBuilderState<Subject>
    extends State<KeyedNotifierBuilder<Subject>> {
  late bool lastUpdate = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void didUpdateWidget(KeyedNotifierBuilder<Subject> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.keyToListenTo != widget.keyToListenTo) {
      widget.keyedNotifier.clearListenerForKey(oldWidget.keyToListenTo);
      init();
    }
  }

  @override
  void dispose() {
    widget.keyedNotifier.clearListenerForKey(widget.keyToListenTo);
    super.dispose();
  }

  void init() {
    widget.keyedNotifier.setListenerForKey(
      widget.keyToListenTo,
      listener,
    );
    lastUpdate = widget.keyedNotifier.value == widget.keyToListenTo;
  }

  @mustCallSuper
  // ignore: avoid_positional_boolean_parameters
  void listener(bool selected) {
    setState(() {
      lastUpdate = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, lastUpdate);
  }
}
