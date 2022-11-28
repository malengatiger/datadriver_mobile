import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/providers.dart';

class Places extends ConsumerWidget {
  const Places(
      {Key? key,
      required this.backgroundColor,
      required this.elevation,
      this.color,
      required this.width,
      required this.height,
      required this.numberTextStyle,
      required this.captionTextStyle})
      : super(key: key);

  final double elevation;
  final Color? color;
  final Color backgroundColor;
  final double width, height;
  final TextStyle numberTextStyle, captionTextStyle;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var data = ref.watch(myPlacesCountFutureProvider);
    var f = NumberFormat("###,###");
    var count = data.value;

    return Scaffold(
        backgroundColor: backgroundColor,
        body: data.when(
            data: (data) {
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
                        const SizedBox(
                          height: 40,
                        ),
                        Text(
                          f.format(count),
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
                    )),
              );
            },
            error: (err, s) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Something failed: ${err.toString()}'),
                ),
              );
            },
            loading: () => const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.pink,
                  ),
                )));
  }
}
