import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/services/timer_generation.dart';

import '../../utils/emojis.dart';
import '../../utils/util.dart';

class GenerationPage extends StatefulWidget {
  const GenerationPage({Key? key}) : super(key: key);

  @override
  GenerationPageState createState() => GenerationPageState();
}

class GenerationPageState extends State<GenerationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _controller.dispose();
    timerGeneration.stop();
    super.dispose();
  }

  final _intervalController = TextEditingController(text: '10');
  final _maxController = TextEditingController(text: '10');
  final _upperCountController = TextEditingController(text: '100');
  bool _isGeneration = false;

  void _showSnack({
    required String message,
  }) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _listen() {
    p('$diamond $diamond $diamond $diamond listening to stream from timerGeneration');
    timerGeneration.stream.listen((timerMessage) {
      p('$diamond $diamond $diamond $diamond GenerationPage listening: '
          '\n$appleRed TimerGeneration message arrived, statusCode: ${timerMessage.statusCode} '
          'msg: ${timerMessage.message} $appleRed city: ${timerMessage.cityName}');

      if (mounted) {
        if (timerMessage.statusCode == FINISHED) {
          p('$diamond $diamond $diamond $diamond GenerationPage completed! ${Emoji.leaf}');
          _showSnack(message: 'Generation completed!');
          setState(() {
            _isGeneration = false;
          });
        } else {
          processTimerMessage(timerMessage);
          setState(() {
          });
        }

      }
    });
  }

  var cityHashMap = HashMap<String, String>();
  var totalGenerated = 0;

  void processTimerMessage(TimerMessage message) {
    cityHashMap[message.cityName!] = message.cityName!;
    totalGenerated += message.events;
  }

  void showTimerSnack({
    required TimerMessage message,
  }) {
    if (message.cityName == null || message.cityName!.isEmpty) {
      return;
    }
    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(
        'Events: ${message.events} - ${message.cityName}',
        style: const TextStyle(fontSize: 12),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  final numberFormat = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[100],
        elevation: 1,
        title: Text(
          'Streaming Data Generation',
          style: GoogleFonts.secularOne(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.normal),
        ),
      ),
      backgroundColor: Colors.brown[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 4,
                  color: Colors.brown[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                              child: Column(
                            children: [
                              Text(
                                'Generation Config',
                                style: GoogleFonts.secularOne(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyMedium,
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              TextFormField(
                                controller: _intervalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(),
                                style: GoogleFonts.secularOne(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyMedium,
                                    fontWeight: FontWeight.w900),
                                decoration: const InputDecoration(
                                  label: Text('Interval in Seconds'),
                                  hintText: 'Enter interval seconds',
                                  border: OutlineInputBorder(),
                                ),
                                // The validator receives the text that the user has entered.
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Interval in Seconds';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              TextFormField(
                                controller: _upperCountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(),
                                style: GoogleFonts.secularOne(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyMedium,
                                    fontWeight: FontWeight.w900),
                                decoration: const InputDecoration(
                                  label: Text('Upper Count'),
                                  hintText: 'Enter Upper Count',
                                  border: OutlineInputBorder(),
                                ),
                                // The validator receives the text that the user has entered.
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Upper Count';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              TextFormField(
                                controller: _maxController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(),
                                style: GoogleFonts.secularOne(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyMedium,
                                    fontWeight: FontWeight.w900),
                                decoration: const InputDecoration(
                                  label: Text('Maximum Timer Ticks'),
                                  hintText: 'Enter Maximum Ticks',
                                  border: OutlineInputBorder(),
                                ),
                                // The validator receives the text that the user has entered.
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Maximum Timer Ticks';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              totalGenerated == 0
                                  ? const SizedBox(
                                height: 0,
                              )
                                  : Row(
                                    children: [
                                      Text(numberFormat.format(totalGenerated), style: GoogleFonts.secularOne(
                                          textStyle: Theme.of(context).textTheme.bodyMedium,
                                          fontWeight: FontWeight.w900),),
                                      const SizedBox(width: 4,),
                                      Text(
                                      style: GoogleFonts.lato(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          fontWeight: FontWeight.normal, color: Colors.blue[700]),
                                          'Events generated for '),
                                      const SizedBox(width: 4,),
                                      Text(numberFormat.format(cityHashMap.keys.toList().length), style: GoogleFonts.secularOne(
                                          textStyle: Theme.of(context).textTheme.bodyMedium,
                                          fontWeight: FontWeight.w900),),
                                      const SizedBox(width: 4,),
                                      const Text('cities'),
                                    ],
                                  ),
                              const SizedBox(
                                height: 28,
                              ),
                              _isGeneration? const SizedBox(height: 16, width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4, backgroundColor: Colors.orange,
                                  ),):ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 8,
                                  ),
                                  onPressed: startGenerator,
                                  child:  Text('Start Generator',style: GoogleFonts.lato(
                                      textStyle: Theme.of(context).textTheme.bodySmall,
                                      fontWeight: FontWeight.normal, color: Colors.white),))
                            ],
                          )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _isGeneration
              ? Positioned(
                  left: 60,
                  top: 2,
                  child: SizedBox(
                    height: 60,
                    width: 200,
                    child: Card(
                      elevation: 16,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 8,
                            ),
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 6,
                                backgroundColor: Colors.pink,
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  elevation: 2,
                                ),
                                onPressed: stopGenerator,
                                child: Text(
                                  'Stop Generator',
                                  style: GoogleFonts.lato(
                                      textStyle:
                                          Theme.of(context).textTheme.bodyMedium,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white, fontSize: 12),
                                )),
                            const SizedBox(
                              width: 8,
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(
                  height: 0,
                ),
        ],
      ),
    );
  }

  void startGenerator() {
    setState(() {
      _isGeneration = true;
    });
    cityHashMap.clear();
    totalGenerated = 0;

    timerGeneration.start(
        intervalInSeconds: int.parse(_intervalController.value.text),
        upperCount: int.parse(_upperCountController.value.text),
        max: int.parse(_maxController.value.text));
  }

  void stopGenerator() {
    timerGeneration.stop();
    setState(() {
      _isGeneration = false;
    });
  }
}
