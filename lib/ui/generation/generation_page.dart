import 'dart:collection';
import 'dart:isolate';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:universal_frontend/data_models/generation_message.dart';
import 'package:universal_frontend/services/api_service.dart';
import 'package:universal_frontend/services/timer_generation.dart';

import '../../data_models/city.dart';
import '../../services/data_service.dart';
import '../../services/generation_monitor.dart';
import '../../utils/emojis.dart';
import '../../utils/hive_util.dart';
import '../../utils/providers.dart';
import '../../utils/util.dart';

class GenerationPage extends StatefulWidget {
  const GenerationPage({Key? key}) : super(key: key);

  @override
  GenerationPageState createState() => GenerationPageState();
}

class GenerationPageState extends State<GenerationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  var cities = <City>[];

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(seconds: 3),
        reverseDuration: const Duration(seconds: 2),
        value: 0.0,
        vsync: this);
    super.initState();
    _listen();
    _getCities();
  }

  void _getCities() async {
    cities = (await hiveUtil.getCities());
    p('${Emoji.leaf}${Emoji.leaf}${Emoji.leaf} GenerationPage: Cities from Hive cache: ${cities.length}');
    if (cities.isEmpty) {
      cities = await DataService.getCities();
      await hiveUtil.addCities(cities: cities);
    }
    cities.sort((a, b) => a.city!.compareTo(b.city!));
    setState(() {});
  }

  List<DropdownMenuItem<City>>? menuItems;
  City? selectedCity;

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
    _animationController.dispose();
    super.dispose();
  }

  final _intervalController = TextEditingController(text: '60');
  final _maxTicksController = TextEditingController(text: '5');
  final _upperCountController = TextEditingController(text: '450');
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
  bool? _isSortedByEvents;

  void _sort() {
    if (_isSortedByEvents == null) {
      _sortByEvents();
      _isSortedByEvents = true;
      return;
    }
    if (_isSortedByEvents!) {
      _sortByCity();
      _isSortedByEvents = false;
      return;
    } else {
      _sortByEvents();
      _isSortedByEvents = true;
      return;
    }
  }

  void _sortByEvents() {
    generationMessages.sort((a, b) => b.count!.compareTo(a.count!));
    setState(() {});
    _scrollToTop();
  }

  void _sortByCity() {
    generationMessages.sort((a, b) => a.message!.compareTo(b.message!));
    setState(() {});
    _scrollToTop();
  }

  void processTimerMessage(TimerMessage message) {
    for (var msg in message.generationMessages!) {
      cityHashMap[msg.message!] = message.message;
    }
    for (var element in message.generationMessages!) {
      _totalEvents += element.count!;
    }
    var end = DateTime.now().millisecondsSinceEpoch;
    var ms = (end - _start) / 1000;
    _elapsedSeconds = ms;

    totalGenerated += message.events;
    //consolidate messages
    var map = HashMap<String, int>();
    for (var m in generationMessages) {
      if (map.containsKey(m.message)) {
        int? count = map[m.message];
        if (count != null) {
          count += m.count!;
          map[m.message!] = count;
        }
      } else {
        map[m.message!] = m.count!;
      }
    }
    generationMessages.clear();
    map.forEach((key, value) {
      generationMessages
          .add(GenerationMessage(type: '', message: key, count: value));
    });
    if (mounted) {
      p('${Emoji.redDot} setting state for tick message ... generationMessages: ${generationMessages.length}');

      try {
        setState(() {});
      } catch (e) {
        p('${Emoji.redDot} Ignored setState error ${Emoji.redDot}${Emoji.redDot}');
      }
      _animationController.reverse().then((value) {
        _animationController.forward().then((value) {
          _scrollToBottom();
        });
      });
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
  List<GenerationMessage> generationMessages = <GenerationMessage>[];

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
                                height: 4,
                              ),
                              Text(
                                'Generation Config',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyLarge,
                                    fontWeight: FontWeight.w900),
                              ),
                              selectedCity == null
                                  ? const SizedBox()
                                  : Column(
                                      children: [
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Text('${selectedCity!.city}'),
                                      ],
                                    ),
                              const SizedBox(
                                height: 32,
                              ),
                              selectedCity == null
                                  ? TextFormField(
                                      controller: _intervalController,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      style: GoogleFonts.secularOne(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
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
                                    )
                                  : const SizedBox(
                                      height: 0,
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
                                decoration: InputDecoration(
                                  label: selectedCity == null
                                      ? const Text('Upper Count')
                                      : const Text('Count'),
                                  hintText: 'Enter Upper Count',
                                  border: const OutlineInputBorder(),
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
                              selectedCity == null
                                  ? TextFormField(
                                      controller: _maxTicksController,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(),
                                      style: GoogleFonts.secularOne(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
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
                                    )
                                  : const SizedBox(
                                      height: 0,
                                    ),
                              const SizedBox(
                                height: 16,
                              ),
                              cities.isEmpty
                                  ? const SizedBox(
                                      height: 0,
                                    )
                                  : _isGeneration
                                      ? const SizedBox(
                                          height: 0,
                                        )
                                      : DropdownButton<City>(
                                          hint: Text(
                                            'Select City',
                                            style: GoogleFonts.lato(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                fontWeight: FontWeight.normal,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                          ),
                                          items: cities.map((myCity) {
                                            return DropdownMenuItem(
                                              value: myCity,
                                              child: Text(
                                                '${myCity.city}',
                                                style: GoogleFonts.lato(
                                                  textStyle: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: onChanged),
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
          generationMessages.isEmpty
              ? const SizedBox(
                  height: 0,
                )
              : Positioned(
                  child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (BuildContext context, Widget? child) {
                    return FadeScaleTransition(
                      animation: _animationController,
                      child: child,
                    );
                  },
                  child: Container(
                    color: Theme.of(context).secondaryHeaderColor,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Generation Results'),
                            const SizedBox(
                              width: 60,
                            ),
                            IconButton(
                                onPressed: () {
                                  _animationController.reverse().then((value) {
                                    setState(() {
                                      generationMessages.clear();
                                    });
                                  });
                                },
                                icon: const Icon(Icons.close))
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 12,
                            ),
                            Text('Total Elapsed Time',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12)),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(_elapsedSeconds.toStringAsFixed(1),
                                style: GoogleFonts.secularOne(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(
                              width: 8,
                            ),
                            Text('seconds',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 12,
                            ),
                            Text('Total Events Generated',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12)),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(fm.format(_totalEvents),
                                style: GoogleFonts.secularOne(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(
                              width: 8,
                            ),
                            Text('events',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 12,
                            ),
                            Text('Total Cities Touched',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12)),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(fm.format(cityHashMap.length),
                                style: GoogleFonts.secularOne(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(
                              width: 8,
                            ),
                            Text('cities',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: ListView.builder(
                              itemCount: generationMessages.length,
                              controller: _scrollController,
                              itemBuilder: (context, index) {
                                var msg = generationMessages.elementAt(index);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: GestureDetector(
                                    onTap: _sort,
                                    child: Card(
                                      elevation: 2,
                                      // color: Colors.teal,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0),
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            SizedBox(
                                              width: 48,
                                              child: Text(
                                                fm.format(msg.count),
                                                style: GoogleFonts.secularOne(
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    fontWeight:
                                                        FontWeight.w900),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            Flexible(
                                              child: Text(
                                                  '${Emoji.blueDot} ${msg.message}',
                                                  style: GoogleFonts.lato(
                                                      textStyle:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodySmall,
                                                      fontWeight:
                                                          FontWeight.normal)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                        )),
                      ],
                    ),
                  ),
                )),
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

  var fm = NumberFormat.decimalPattern();
  var _elapsedSeconds = 0.0;
  var _totalEvents = 0;
  var _start = 0;

  Future<void> startGenerator() async {
    p('${Emoji.pear}${Emoji.pear} startGenerator: spawn isolate ...');
    _start = DateTime.now().millisecondsSinceEpoch;
    generationMessages.clear();
    setState(() {
      totalGenerated = 0;
      cityHashMap.clear();
      _totalEvents = 0;
      _elapsedSeconds = 0.0;
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
        city: selectedCity,
        intervalInSeconds: int.parse(_intervalController.value.text),
        upperCount: int.parse(_upperCountController.value.text),
        maxTimerTicks: int.parse(_maxTicksController.value.text));

    generationMessages.clear();
    _createIsolate(params: params);
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
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        position,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.minScrollExtent;
      _scrollController.animateTo(
        position,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _createIsolate({required GenerationParameters params}) async {
    try {
      receivePort = ReceivePort();
      var errorReceivePort = ReceivePort();
      var cities = await hiveUtil.getCities();
      if (cities.isNotEmpty) {
        params.cities = cities;
      }
      //pass sendPort to the params so isolate can send messages
      params.sendPort = receivePort.sendPort;
      //create channel for comms
      IsolateChannel channel =
          IsolateChannel(receivePort, receivePort.sendPort);
      channel.stream.listen((data) async {
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

            switch (msg.statusCode) {
              case TICK_RESULT:
                p('${Emoji.heartBlue}${Emoji.heartBlue} Channel received a ${Emoji.redDot} TICK_RESULT; '
                    'messages: ${msg.generationMessages!.length}');
                var list = msg.generationMessages!;
                generationMessages.addAll(list);
                processTimerMessage(msg);
                break;
              case DASHBOARD_ADDED:
                p('${Emoji.heartBlue}${Emoji.heartBlue} Channel received a ${Emoji.redDot} DASHBOARD_ADDED '
                    'message date: ${msg.dashboardData!.date}');
                var db = msg.dashboardData;
                if (db != null) {
                  await hiveUtil.addDashboardDataList(dataList: [db]);
                }
                break;
              case AGGREGATES_ADDED:
                p('${Emoji.heartBlue}${Emoji.heartBlue} Channel received a ${Emoji.redDot} AGGREGATES_ADDED '
                    ' aggregates: ${msg.aggregates!.length}');
                var aggregates = msg.aggregates;
                if (aggregates != null) {
                  await hiveUtil.addAggregates(aggregates: aggregates);
                }
                break;
              case FINISHED:
                p('${Emoji.heartBlue}${Emoji.heartBlue} Channel received a ${Emoji.redDot} FINISHED '
                    'message ');
                isolate.kill();
                var end = DateTime.now().millisecondsSinceEpoch;
                var ms = end - _start;
                _elapsedSeconds = ms / 1000;
                p('${Emoji.leaf} ${Emoji.redDot}${Emoji.redDot}${Emoji.redDot} isolate has been killed!');
                if (mounted) {
                  setState(() {
                    _isGeneration = false;
                  });
                }
                sendFinishedMessage();
                if (mounted) {
                  _animationController.reset();
                  _animationController.forward();
                }
                break;
            }
            generationMonitor.addMessage(msg);
          }
        } else {
          sendFinishedMessage();
        }
      });

      isolate = await Isolate.spawn<GenerationParameters>(heavyTask, params,
          paused: true,
          onError: errorReceivePort.sendPort,
          onExit: receivePort.sendPort);

      isolate.addErrorListener(errorReceivePort.sendPort);
      isolate.resume(isolate.pauseCapability!);
      isolate.addOnExitListener(receivePort.sendPort);

      errorReceivePort.listen((e) {
        p('${Emoji.redDot}${Emoji.redDot} GenerationPage: exception occurred: $e');
      });
    } catch (e) {
      p('${Emoji.redDot} we have a problem ${Emoji.redDot} ${Emoji.redDot}');
    }
  }

  var apiService = ApiService();
  void sendFinishedMessage() async {
    var msg = TimerMessage(
        date: DateTime.now().toIso8601String(),
        message: 'Generation stopped',
        statusCode: FINISHED,
        events: 0);
    generationMonitor.addMessage(msg);
    if (mounted) {
      setState(() {
        selectedCity = null;
      });
    }
  }

  void onChanged(City? value) {
    p('${Emoji.blueDot} GenerationPage: city selected: ${value!.city!}');
    setState(() {
      selectedCity = value;
    });
  }
}

class GenerationParameters {
  GenerationParameters(
      {required this.intervalInSeconds,
      required this.upperCount,
      required this.maxTimerTicks,
      required this.url,
      this.sendPort,
      this.city,
      this.cities});

  final int intervalInSeconds;
  final int upperCount;
  final int maxTimerTicks;
  final String url;
  SendPort? sendPort;
  City? city;
  List<City>? cities;
}

Future<void> heavyTask(GenerationParameters params) async {
  TimerGeneration gen = TimerGeneration();
  gen.startEventsByRandomCities(params: params);
}
