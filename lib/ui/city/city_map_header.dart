import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../dashboard/widgets/minutes_ago_widget.dart';

class CityMapHeader extends StatelessWidget {
  const CityMapHeader(
      {Key? key,
      required this.events,
      required this.averageRating,
      required this.onRequestRefresh,
      required this.totalAmount})
      : super(key: key);

  final int events;
  final double averageRating, totalAmount;
  final Function() onRequestRefresh;
  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact();
    if (kIsWeb) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Events',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(numberFormat.format(events),
                  style: GoogleFonts.secularOne(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.w900),),
              const SizedBox(
                width: 16,
              ),
              const Text(
                'Average Rating',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(averageRating.toStringAsFixed(2),
                  style: GoogleFonts.secularOne(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.w900),),
              const SizedBox(
                width: 16,
              ),
              const Text(
                'Amount',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(numberFormat.format(totalAmount),
                  style: GoogleFonts.secularOne(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      fontWeight: FontWeight.w900),
              )
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Events',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(numberFormat.format(events),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(
                width: 8,
              ),
              const Text(
                'Average Rating',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(averageRating.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(
            height: 4,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 8,
              ),
              const Text(
                'Amount',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(
                width: 4,
              ),
              Text(numberFormat.format(totalAmount),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900))
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          GestureDetector(
              onTap: () {
                onRequestRefresh();
              },
              child: const MinutesAgoWidget()),
          const SizedBox(
            height: 12,
          )
        ],
      );
    }
  }
}
