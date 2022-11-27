import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/providers.dart';
import 'amount_by_time.dart';
import 'events_by_time.dart';
import 'rating_by_time.dart';

class DashboardGrid extends ConsumerWidget {
  const DashboardGrid(
      {required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle,
      required this.gridColumns,
      Key? key,
      required this.cardElevation})
      : super(key: key);
  final double cardElevation;
  final double width, height;
  final TextStyle numberTextStyle, captionTextStyle;
  final int gridColumns;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myEventsFutureProvider);

    return Scaffold(
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
