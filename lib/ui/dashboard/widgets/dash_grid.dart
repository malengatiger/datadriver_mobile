import 'package:flutter/material.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/ui/dashboard/widgets/places.dart';
import 'package:universal_frontend/ui/dashboard/widgets/rating_by_time.dart';
import 'package:universal_frontend/ui/dashboard/widgets/users.dart';

import '../../../data_models/event.dart';
import 'amount_by_time.dart';
import 'cities.dart';
import 'events_by_time.dart';

class DashGrid extends StatelessWidget {
  const DashGrid({Key? key,
    required this.dashboardData,
    required this.cardElevation,
    required this.height,
    required this.width,
    required this.numberTextStyle,
    required this.captionTextStyle,
    required this.backgroundColor,
    required this.gridColumns}) : super(key: key);

  final DashboardData dashboardData;
  final double cardElevation;
  final double height, width;
  final TextStyle numberTextStyle, captionTextStyle;
  final Color backgroundColor;
  final int gridColumns;

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
      ),
      children: [
        EventsByTime(
          elevation: cardElevation,
          dashboardData: dashboardData,
          width: width,
          height: height,
          numberTextStyle: numberTextStyle,
          captionTextStyle: captionTextStyle,
        ),
        AmountByTime(
          elevation: cardElevation,
          dashboardData: dashboardData,
          width: width,
          height: height,
          numberTextStyle: numberTextStyle,
          captionTextStyle: captionTextStyle,
        ),
        RatingByTime(
          elevation: cardElevation,
          dashData: dashboardData,
          width: width,
          height: height,
          numberTextStyle: numberTextStyle,
          captionTextStyle: captionTextStyle,
        ),
        Cities(
          elevation: cardElevation,
          width: width,
          height: height,
          backgroundColor: backgroundColor,
          numberTextStyle: numberTextStyle,
          captionTextStyle: captionTextStyle, dashboardData: dashboardData,
        ),
        Places(
          elevation: cardElevation,
          width: width,
          height: height,
          dashboardData: dashboardData,
          backgroundColor: backgroundColor,
          numberTextStyle: numberTextStyle,
          captionTextStyle: captionTextStyle,
        ),
        Users(
          elevation: cardElevation,
          width: width,
          height: height,
          dashboardData: dashboardData,
          backgroundColor: backgroundColor,
          numberTextStyle: numberTextStyle,
          captionTextStyle: captionTextStyle,
        ),
      ],
    );
  }
}
