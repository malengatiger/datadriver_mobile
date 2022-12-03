import 'package:flutter/material.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/providers.dart';

import '../../../utils/util.dart';

class TimeChooser extends StatefulWidget {
  const TimeChooser({Key? key, required this.onSelected,
    required this.elevation, this.backgroundColor}) : super(key: key);

  final Function(double) onSelected;
  final double elevation;
  final Color? backgroundColor;
  @override
  TimeChooserState createState() => TimeChooserState();
}

class TimeChooserState extends State<TimeChooser> {
  var sliderValue = 10.0;
  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: 300, height: 120,
      child: Card(
        elevation: widget.elevation,
        color: widget.backgroundColor ?? Colors.brown[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              const SizedBox(height: 8,),
              Slider(value: sliderValue, onChanged: onChanged,
              label: '$sliderValue', max: 300, min: 10,
                  onChangeEnd: onChangedEnd),
              const SizedBox(height: 4,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(sliderValue.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.w900,
                        fontSize: 20),),
                  const SizedBox(width: 12,),
                  const Text('Minutes'),
                  const SizedBox(width: 48,),
                  ElevatedButton(onPressed: () {
                    p('Button Pressed: slider value ${sliderValue.toInt()} sent back $redDot');
                    minutesAgo = sliderValue.toInt();
                    widget.onSelected(sliderValue);
                  }, child: const Text('Done')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onChanged(double value) {
    //p('onChanged: slider value is $value minutes $redDot');
    sliderValue = value;
  }

  void onChangedEnd(double value) {
    p('onChangedEnd: slider value is ${value.toInt()} minutes $redDot');
    sliderValue = value;
    setState(() {

    });
  }
}
