import 'package:flutter/material.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';

import '../../../data_models/event.dart';

class RatingByTime extends StatelessWidget {
  const RatingByTime(
      {Key? key,
      required this.elevation,
      this.color,
      required this.dashData,
      required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle})
      : super(key: key);

  final double elevation;
  final Color? color;
  final DashboardData dashData;
  final double width, height;
  final TextStyle numberTextStyle, captionTextStyle;

  @override
  Widget build(BuildContext context) {
    var avg = dashData.averageRating.toStringAsFixed(2);
    return Card(
        elevation: elevation,
        color: color ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 48,
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
