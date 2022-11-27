import 'package:flutter/material.dart';

import '../../../data_models/event.dart';

class AmountByTime extends StatelessWidget {
  const AmountByTime(
      {Key? key,
      required this.elevation,
      this.color,
      required this.events,
      required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle})
      : super(key: key);

  final double elevation;
  final Color? color;
  final List<Event> events;
  final double width, height;
  final TextStyle numberTextStyle, captionTextStyle;
  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (var element in events) {
      total += element.amount;
    }
    return SizedBox(
      height: height,
      width: width,
      child: Card(
          elevation: elevation,
          color: color ?? Colors.white,
          child: Column(
            children: [
              Text(
                total.toStringAsFixed(0),
                style: numberTextStyle,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'Amount',
                style: captionTextStyle,
              ),
            ],
          )),
    );
  }
}
