import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/providers.dart';

class MinutesAgoWidget extends StatelessWidget {
  const MinutesAgoWidget({Key? key, required this.date}) : super(key: key);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    var hour = date.hour;
    var minute = date.minute;
    var min = '';
    if (minute < 10) {
      min = '0$minute';
    } else {
      min = minute.toString();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Data from',
            style: TextStyle(
              fontSize: 12,
            )),
        const SizedBox(
          width: 8,
        ),

        Text(
          '$hour:$min',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
