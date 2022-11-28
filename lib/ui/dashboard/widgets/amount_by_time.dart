import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    var f = NumberFormat.compact();
    return SizedBox(
      height: height,
      width: width,
      child: Card(
          elevation: elevation,
          color: color ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),
              Text(
                f.format(total),
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
