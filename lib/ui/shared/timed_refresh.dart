import 'dart:async';

import 'package:flutter/widgets.dart';

class TimedRefresh extends StatefulWidget {
  final Duration interval;
  final Widget Function(DateTime time, BuildContext context) builder;

  const TimedRefresh({
    required this.interval,
    required this.builder,
    super.key,
  });

  @override
  State<TimedRefresh> createState() => _TimedRefreshState();
}

class _TimedRefreshState extends State<TimedRefresh> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) => widget.builder(DateTime.now(), context);
}
