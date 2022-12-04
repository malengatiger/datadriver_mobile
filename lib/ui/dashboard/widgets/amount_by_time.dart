import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../../../data_models/event.dart';
import '../../../utils/util.dart';

class AmountByTime extends StatelessWidget {
  const AmountByTime(
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

    p('$redDot $redDot AmountByTime build, dashboardData: ${dashboardData.toJson()}');
    // var currencySymbol = NumberFormat.compactCurrency(locale: Platform.localeName).currencySymbol;
    var currencyFormatter = NumberFormat.compact();
    var mTop = 48.0;
    if (kIsWeb) {
      mTop = 100.0;
    }
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
               SizedBox(
                height: mTop,
              ),
              Text(
                currencyFormatter.format(dashboardData.amount),
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
