import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';

import '../../../data_models/event.dart';

class EventsByTime extends StatelessWidget {
  const EventsByTime(
      {Key? key,
      required this.elevation,
      this.color,
      required this.dashboardData,
      required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle})
      : super(key: key);

  final double elevation;
  final Color? color;
  final DashboardData dashboardData;
  final double width, height;
  final TextStyle numberTextStyle, captionTextStyle;
  @override
  Widget build(BuildContext context) {
    var f = NumberFormat.compact();
    var mTop = 48.0;
    if (kIsWeb) {
      mTop = 100.0;
    }
    return Card(
        elevation: elevation,
        color: color ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
             SizedBox(
              height: mTop,
            ),
            Text(
              f.format(dashboardData.events),
              style: numberTextStyle,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Events',
              style: captionTextStyle,
            ),
          ],
        ));
  }
}
