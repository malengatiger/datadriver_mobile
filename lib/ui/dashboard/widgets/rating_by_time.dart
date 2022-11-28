import 'package:flutter/material.dart';

import '../../../data_models/event.dart';

class RatingByTime extends StatelessWidget {
  const RatingByTime(
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
    var total = 0;
    for (var element in events) {
      total += element.rating;
    }
    var avg = '0.0';
    if (events.isNotEmpty) {
      avg = (total / events.length).toStringAsFixed(2);
    }
    return Card(
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
              avg,
              style: numberTextStyle,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Rating',
              style: captionTextStyle,
            ),
          ],
        ));
  }
}
