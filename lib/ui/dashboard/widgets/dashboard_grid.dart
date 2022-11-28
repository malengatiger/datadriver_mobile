import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/ui/dashboard/widgets/places.dart';
import 'package:universal_frontend/ui/dashboard/widgets/users.dart';

import '../../../utils/providers.dart';
import 'amount_by_time.dart';
import 'cities.dart';
import 'events_by_time.dart';
import 'rating_by_time.dart';

class DashboardGrid extends ConsumerWidget {
  const DashboardGrid(
      {required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle,
      required this.gridColumns,
      required this.backgroundColor,
      required this.minutes,
      Key? key,
      required this.cardElevation})
      : super(key: key);
  final double cardElevation;
  final double width, height;
  final TextStyle numberTextStyle, captionTextStyle;
  final int gridColumns;
  final Color backgroundColor;
  final int minutes;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myEventsFutureProvider);

    return Scaffold(
        backgroundColor: Colors.amber.shade100,
        body: data.when(
            data: (data) {
              var list = data.map((e) => e).toList();
              return GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                ),
                children: [
                  EventsByTime(
                    elevation: cardElevation,
                    events: list,
                    width: width,
                    height: height,
                    numberTextStyle: numberTextStyle,
                    captionTextStyle: captionTextStyle,
                  ),
                  AmountByTime(
                    elevation: cardElevation,
                    events: list,
                    width: width,
                    height: height,
                    numberTextStyle: numberTextStyle,
                    captionTextStyle: captionTextStyle,
                  ),
                  RatingByTime(
                    elevation: cardElevation,
                    events: list,
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
                    captionTextStyle: captionTextStyle,
                  ),
                  Places(
                    elevation: cardElevation,
                    width: width,
                    height: height,
                    backgroundColor: backgroundColor,
                    numberTextStyle: numberTextStyle,
                    captionTextStyle: captionTextStyle,
                  ),
                  Users(
                    elevation: cardElevation,
                    width: width,
                    height: height,
                    backgroundColor: backgroundColor,
                    numberTextStyle: numberTextStyle,
                    captionTextStyle: captionTextStyle,
                  ),
                ],
              );
            },
            error: (err, s) {
              return Center(child: Text(err.toString()));
            },
            loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    backgroundColor: Colors.pink,
                  ),
                )));
  }
}
