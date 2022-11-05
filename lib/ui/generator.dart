import 'dart:async';

import 'package:datadriver_mobile/emojis.dart';
import 'package:flutter/material.dart';

import '../data_models/event.dart';
import '../services/data_service.dart';
import '../services/network_service.dart';
import '../services/util.dart';

class Generator extends StatefulWidget {
  const Generator({Key? key}) : super(key: key);

  @override
  _GeneratorState createState() => _GeneratorState();
}

class _GeneratorState extends State<Generator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var dataService = DataService();
  var networkService = HttpService();
  var events = <Event>[];
  var totalCount = 0;

  String result = '';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  void startGenerator() async {
    p('$heartGreen starting the Generator in the cloud ...');
    result = await _runGenerator();
    setState(() {

    });
    p('$heartGreen starting the Timers to read generated event data ...');
    _runTimer();
    _runTimerTotal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  var txtController1 = TextEditingController();
  var txtController2 = TextEditingController();
  var txtController3 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Timer timer, timer2;

  _runGenerator() async {
    p('$heartBlue About to start HttpService generateEvents call');
    p('$heartBlue intervalInSeconds: $intervalInSeconds, upperCountPerPlace: $upperCountPerPlace  maxCount: $maxCount');
    result = (await networkService.generateEvents(
        intervalInSeconds: intervalInSeconds, upperCountPerPlace: upperCountPerPlace, maxCount: maxCount))!;
    if (mounted) {
      setState(() {

      });
    }
  }

  _runTimer() async {
    p('$heartOrange $heartOrange $heartOrange Timer starting; intervalInSeconds; $intervalInSeconds '
        ' dataLastMinutes: $dataLastMinutes');
    timer = Timer.periodic(Duration(seconds: intervalInSeconds), (timer) async {
      p('$heartOrange $heartOrange $heartOrange Timer triggered, tick: ${timer.tick} $redDot ');
      events = await dataService.getEvents(minutes: dataLastMinutes);
      if (mounted) {
        setState(() {

        });
      }
    });
  }

  _runTimerTotal() async {
    p('$heartGreen $heartGreen $heartGreen TimerTotal starting; intervalInSecondsForTotal: $intervalInSecondsForTotal ...');
    timer2 = Timer.periodic(Duration(seconds: intervalInSecondsForTotal), (timer) async {
      p('$heartGreen $heartGreen $heartGreen TimerTotal triggered, tick: ${timer.tick} $redDot ');
      totalCount = await dataService.getEventCount();
      if (mounted) {
        setState(() {

        });
      }
    });
  }

  int intervalInSeconds = 60, intervalInSecondsForTotal = 60,
      maxCount = 20000,
      dataLastMinutes = 120, upperCountPerPlace = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator Control'),
      ),
      backgroundColor: Colors.pink.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 8,
            child: Column(
              children: [
                const SizedBox(
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'Generator Controls',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        // Add TextFormFields and ElevatedButton here.
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Interval In Seconds', hintText: 'Enter Interval In Seconds'),
                          // The validator receives the text that the user has entered.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Interval in Seconds';
                            }
                            intervalInSeconds = int.parse(value);
                            return null;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Interval In Seconds for Total', hintText: 'Enter Interval In Seconds for Total'),
                          // The validator receives the text that the user has entered.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Interval in Seconds';
                            }
                            intervalInSecondsForTotal = int.parse(value);
                            return null;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Place Event Upper Count', hintText: 'Enter Event Upper Count'),
                          // The validator receives the text that the user has entered.
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Upper Bound for Place Event generation';
                            }
                            upperCountPerPlace = int.parse(value);
                            return null;
                          },
                        ),
                        TextFormField(
                          // The validator receives the text that the user has entered.
                          decoration:
                              const InputDecoration(labelText: 'Maximum Events', hintText: 'Enter Max Event Count'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Maximum Events for Generator';
                            }
                            maxCount = int.parse(value);
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 48,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: Colors.teal, onPrimary: Colors.white, onSurface: Colors.grey, elevation: 8),
                          onPressed: () {
                            // Validate returns true if the form is valid, or false otherwise.
                            if (_formKey.currentState!.validate()) {
                              p('$heartOrange Validating form  ...');
                              // If the form is valid, display a snackbar. In the real world,
                              // you'd often call a server or save the information in a database.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data Stream has been kicked off ...')),
                              );
                              startGenerator();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Start Data Streaming'),
                          ),
                        ),
                        const SizedBox(height: 24,),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(result),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
