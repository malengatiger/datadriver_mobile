import 'package:flutter/material.dart';

class MinutesWidget extends StatefulWidget {
  const MinutesWidget(
      {Key? key,
      required this.elevation,
      required this.onChanged,
      required this.min,
      required this.max,
      required this.divisions})
      : super(key: key);

  final Function onChanged;
  final double elevation;
  final double min, max;
  final int divisions;

  @override
  State<MinutesWidget> createState() => _MinutesWidgetState();
}

class _MinutesWidgetState extends State<MinutesWidget> {
  double currentValue = 1.0;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.elevation,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Slider(
              label: 'Minutes',
              value: currentValue,
              onChanged: onChangedEnd,
              max: widget.max,
              min: widget.min,
              divisions: widget.divisions,
              onChangeEnd: onChangedEnd,
            ),
          ),
          // const SizedBox(
          //   width: 2,
          // ),
          Text(
            '${(currentValue * 30).toStringAsFixed(0)} minutes',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.pink,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void onChangedEnd(double value) {
    setState(() {
      currentValue = value;
    });
    widget.onChanged(value);
  }
}
