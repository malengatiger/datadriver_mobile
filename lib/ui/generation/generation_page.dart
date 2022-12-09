import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:universal_frontend/services/timer_generation.dart';

import '../../services/generation_monitor.dart';
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

  void _listen() async {
    generationMonitor.cancelStream.listen((event) {
      p('${Emoji.redDot}${Emoji.redDot} '
          'Received stop message from the cancel stream! ${Emoji.redDot}${Emoji.redDot}');
      isolate.kill();
      p('${Emoji.redDot} ${Emoji.redDot} Isolate has been slaughtered; '
          '${Emoji.appleGreen} generation stopped');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final _intervalController = TextEditingController(text: '10');
  final _maxController = TextEditingController(text: '3');
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

  var cityHashMap = HashMap<String, String>();
  var totalGenerated = 0;

  void processTimerMessage(TimerMessage message) {
    if (message.statusCode == FINISHED) {
      p('data generation is done!');
      try {
        setState(() {
          _isGeneration = false;
        });
      } catch (e) {
        p('${Emoji.redDot} Ignored last setState error ${Emoji.redDot}${Emoji.redDot}');
      }
      return;
    }
    cityHashMap[message.cityName!] = message.cityName!;
    totalGenerated += message.events;
    try {
      setState(() {});
    } catch (e) {
      p('${Emoji.redDot} Ignored setState error ${Emoji.redDot}${Emoji.redDot}');
    }
  }

  late TimerGeneration timerGeneration;

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
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        elevation: 1,
        title: Text(
          'Streaming Data Generation',
          style: GoogleFonts.lato(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).primaryColor),
        ),
      ),
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 4,
                  // color: Colors.brown[50],
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
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Generation Config',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyLarge,
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(
                                height: 32,
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
                                        Text(
                                          numberFormat.format(totalGenerated),
                                          style: GoogleFonts.secularOne(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                            style: GoogleFonts.lato(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            'Events for '),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          numberFormat.format(
                                              cityHashMap.keys.toList().length),
                                          style: GoogleFonts.secularOne(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        const Text('cities'),
                                      ],
                                    ),
                              const SizedBox(
                                height: 28,
                              ),
                              _isGeneration
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 4,
                                        backgroundColor: Colors.orange,
                                      ),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          elevation: 8,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                          )),
                                      onPressed: startGenerator,
                                      child: Text(
                                        'Start Generator',
                                        style: GoogleFonts.lato(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white),
                                      ))
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
                                onPressed: _sendStopMessageToIsolate,
                                child: Text(
                                  'Stop Generator',
                                  style: GoogleFonts.lato(
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                      fontSize: 12),
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

  Future<void> startGenerator() async {
    p('${Emoji.pear}${Emoji.pear} startGenerator: spawn isolate ...');
    setState(() {
      totalGenerated = 0;
      cityHashMap.clear();
    });

    var status = dotenv.env['CURRENT_STATUS'];
    late String url = '';
    if (status == 'dev') {
      url = dotenv.env['DEV_URL']!;
    } else {
      url = dotenv.env['PROD_URL']!;
    }
    var params = GenerationParameters(
        url: url,
        intervalInSeconds: int.parse(_intervalController.value.text),
        upperCount: int.parse(_upperCountController.value.text),
        maxTimerTicks: int.parse(_maxController.value.text));

    createIsolate(params: params);
    setState(() {
      _isGeneration = true;
    });
  }

  void _sendStopMessageToIsolate() {
    p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} ....... ending STOP message to isolate');
    //isolate.controlPort.send('stop');
    receivePort.sendPort.send('stop');
    setState(() {
      _isGeneration = false;
    });
  }

  late Isolate isolate;
  late ReceivePort receivePort = ReceivePort();

  Future<void> createIsolate({required GenerationParameters params}) async {
    try {
      receivePort = ReceivePort();
      var errorReceivePort = ReceivePort();
      //pass sendPort to the params so isolate can send messages
      params.sendPort = receivePort.sendPort;
      IsolateChannel channel = IsolateChannel(receivePort, receivePort.sendPort);
      channel.stream.listen((data) {
        p('${Emoji.heartBlue}${Emoji.heartBlue} Channel received msg: $data');
        if (data != null) {
          if (data is String) {
            if (data == 'stop') {
              isolate.kill();
              p('${Emoji.blueDot} ${Emoji.blueDot} ${Emoji.blueDot} '
                  'isolate killed after channel received STOP message '
                  '{Emoji.blueDot} ${Emoji.blueDot} ${Emoji.blueDot} ${Emoji.redDot}');
              sendFinishedMessage();
            }

          } else {
            var msg = TimerMessage.fromJson(data);
            processTimerMessage(msg);
            generationMonitor.addMessage(msg);
            if (msg.statusCode == FINISHED) {
              isolate.kill();
              p('${Emoji.leaf} ${Emoji.redDot}${Emoji.redDot}${Emoji
                  .redDot} isolate has been killed!');
            }
          }
        } else {
          sendFinishedMessage();
        }
      });

      isolate = await Isolate.spawn<GenerationParameters>(
          heavyTask, params,
          paused: true,
          onError: errorReceivePort.sendPort,
          onExit:receivePort.sendPort );

      isolate.addErrorListener(errorReceivePort.sendPort);
      isolate.resume(isolate.pauseCapability!);
      isolate.addOnExitListener(receivePort.sendPort);

      errorReceivePort.listen((e) {
        p('${Emoji.redDot}${Emoji.redDot} exception occurred: $e');
      });
      // receivePort.listen((message) {
      //   p('${Emoji.leaf}${Emoji.leaf}${Emoji.leaf}${Emoji.leaf}'
      //       ' isolate msg: $message');
      //   if (message != null) {
      //     var msg = TimerMessage.fromJson(message);
      //     processTimerMessage(msg);
      //     if (msg.statusCode == FINISHED) {
      //       isolate.kill();
      //       p('${Emoji.leaf} ${Emoji.redDot}${Emoji.redDot}${Emoji.redDot} isolate has been killed!');
      //     }
      //   }
      // });
    } catch (e) {
      p('${Emoji.redDot} we have a problem ${Emoji.redDot} ${Emoji.redDot}');
    }

    // Isolate.spawn<GenerationParameters>(heavyTask, params).then((isolate) {
    //   p('${Emoji.appleGreen }Isolate is known as: ${isolate.debugName}');
    //   isolate.addOnExitListener(responsePort)
    // }).catchError((err) {
    //   p('${Emoji.redDot} We have an error : $err');
    // }).whenComplete(() {
    //   p('${Emoji.leaf}${Emoji.leaf} Isolate is complete. Tell someone');
    // });
  }

  void sendFinishedMessage() {
    var msg = TimerMessage(
        date: DateTime.now().toIso8601String(),
        message: 'Generation stopped',
        statusCode: FINISHED, events: 0);
    generationMonitor.addMessage(msg);
  }

}

class GenerationParameters {
  GenerationParameters(
      {required this.intervalInSeconds,
      required this.upperCount,
      required this.maxTimerTicks,
      required this.url,
      this.sendPort});

  final int intervalInSeconds;
  final int upperCount;
  final int maxTimerTicks;
  final String url;
  SendPort? sendPort;
}

Future<void> heavyTask(GenerationParameters model) async {
  TimerGeneration gen = TimerGeneration();
  gen.start(params: model);
}
