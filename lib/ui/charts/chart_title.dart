import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/city_cache_manager.dart';

class ChartTitle extends StatelessWidget {
  const ChartTitle({Key? key, required this.days, required this.onSelected, required this.title}) : super(key: key);
  final int days;
  final Function(int) onSelected;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title),
        const SizedBox(width: 24,),
        Text('See Previous Days', style: GoogleFonts.lato(
            textStyle: Theme.of(context).textTheme.bodySmall,
            fontWeight: FontWeight.normal)),
        const SizedBox(width: 8,),
        DaysSelector(onSelected: (int days) {
          onSelected(days);
        },),
        const SizedBox(width: 24,),
        Text('$days', style: GoogleFonts.secularOne(
            textStyle: Theme.of(context).textTheme.bodyMedium,
            fontWeight: FontWeight.w900)),
      ],
    );
  }
}
