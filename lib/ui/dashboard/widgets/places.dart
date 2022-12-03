import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';

import '../../../utils/providers.dart';

class Places extends StatelessWidget {
  const Places(
      {Key? key,
      required this.backgroundColor,
      required this.elevation,
      this.color,
      required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle,
      required this.dashboardData})
      : super(key: key);

  final double elevation;
  final Color? color;
  final Color backgroundColor;
  final double width, height;
  final TextStyle numberTextStyle, captionTextStyle;
  final DashboardData dashboardData;
  @override
  Widget build(BuildContext context) {
    var f = NumberFormat.compact();

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
              f.format(dashboardData.places),
              style: numberTextStyle,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Places',
              style: captionTextStyle,
            ),
          ],
        ),
      );
  }
}
