import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';

import '../../../utils/providers.dart';

class Cities extends StatelessWidget {
  const Cities(
      {Key? key,
      required this.elevation,
      required this.backgroundColor,
      this.color,
      required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle,
      required this.dashboardData})
      : super(key: key);

  final DashboardData dashboardData;
  final double elevation;
  final Color? color;
  final Color backgroundColor;
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
              f.format(dashboardData.cities),
              style: numberTextStyle,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Cities',
              style: captionTextStyle,
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        ));
    return const Text('Something is badly wrong!');
  }
}
