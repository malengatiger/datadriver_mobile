import 'dart:isolate';

import 'package:animations/animations.dart';
import 'package:emoji_alert/arrays.dart';
import 'package:emoji_alert/emoji_alert.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/ui/city/city_details_page.dart';
import 'package:universal_frontend/utils/shared_prefs.dart';
import 'package:universal_frontend/utils/util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data_models/cache_bag.dart';
import '../data_models/cache_config.dart';
import '../data_models/city.dart';
import '../services/cache_service.dart';
import 'cache_manager.dart';
import 'emojis.dart';
import 'hive_util.dart';

class CityCacheManager extends StatefulWidget {
  const CityCacheManager({
    Key? key,
    this.cityId,
  }) : super(key: key);

  final String? cityId;
  @override
  CityCacheManagerState createState() => CityCacheManagerState();
}

class CityCacheManagerState extends State<CityCacheManager>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ScrollController listScrollController = ScrollController();

  var cities = <City>[];
  String? selectedCityId;
  City? selectedCity;
  bool isCaching = false;
  late Isolate isolate;
  int _isolateEnd = 0;
  double elapsedSeconds = 0.0;
  final _daysTextController = TextEditingController(text: '14');

  @override
  void initState() {
    _controller = AnimationController(
        value: 0.0,
        duration: const Duration(seconds: 3),
        reverseDuration: const Duration(seconds: 2),
        vsync: this);
    super.initState();
    _getCities();
    selectedCityId = widget.cityId;
    if (selectedCityId != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _createIsolate(cityId: selectedCityId!);
      });
    }
  }

  void _getCities() async {
    cities = await hiveUtil.getCities();
    cities.sort((a, b) => a.city!.compareTo(b.city!));
    if (widget.cityId != null) {
      for (var m in cities) {
        if (m.id == widget.cityId) {
          selectedCity = m;
          break;
        }
      }
    }
    if (mounted) {
      setState(() {});
      _controller.forward();
    }
  }

  Future<void> _processMessage(CacheMessage msg) async {
    if (msg.statusCode == statusDone) {
      p('\n${Emoji.redDot}${Emoji.redDot} '
          'CacheManager: received end message from CacheService, will remove loading ui '
          '${Emoji.heartBlue}${Emoji.heartBlue}');
      isolate.kill(priority: Isolate.immediate);
      p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond} isolate killed!!');

      if (msg.message.contains('No need to cache')) {
        p('🍏 No need to cache so config not updated');
      } else {
        msg.message = '${Emoji.blueDot} ${msg.message}';
      }
      messages.add(msg);
    } else {
      if (msg.statusCode == statusError) {
        isolate.kill(priority: Isolate.immediate);
        p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond} isolate killed');
        p("We have an error. Do something!");
        var snackBar = SnackBar(
          content: Text('Error: ${msg.message}'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        isCaching = false;
        msg.message = '${Emoji.redDot} ${msg.message}';
        messages.add(msg);
        if (mounted) {
          setState(() {});
        }
      } else {
        msg.message = '${Emoji.appleRed} ${msg.message}';
        messages.add(msg);
      }
    }

    if (mounted) {
      setState(() {
        _isolateEnd = DateTime.now().millisecondsSinceEpoch;
        elapsedSeconds = ((_isolateEnd! - _isolateStart) / 1000);
      });
    }
  }

  String? _getUrlPrefix() {
    var status = dotenv.env['CURRENT_STATUS'];
    if (status == 'dev') {
      return dotenv.env['DEV_URL'];
    }
    if (status == 'prod') {
      return dotenv.env['PROD_URL'];
    }
    return null;
  }

  void _scrollToBottom() {
    if (listScrollController.hasClients) {
      final position = listScrollController.position.maxScrollExtent;
      listScrollController.animateTo(
        position,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut,
      );
    }
  }

  var messages = <CacheMessage>[];
  bool _eventsCached = false;
  void _saveEvents(CacheMessage msg) async {
    var start = DateTime.now().millisecondsSinceEpoch;

    if (msg.cacheBagJson != null) {
      var bag = CacheBag.fromJson(msg.cacheBagJson!);
      p('${Emoji.heartOrange} ${bag.events.length} events to be written to Hive cache ...');
      await hiveUtil.addEvents(events: bag.events);
      _eventsCached = true;
      isCaching = false;
      var end = DateTime.now().millisecondsSinceEpoch;
      var ms = (end - start) / 1000;

      var mMsg = CacheMessage(
          message: '${Emoji.blueDot} ${bag.events.length} Hive events cached',
          statusCode: statusBusy,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: ms,
          type: typeMessage);

      messages.add(mMsg);
      if (mounted) {
        setState(() {});
      }
    } else {
      p('${Emoji.redDot} No events in cacheBag');
    }

    if (mounted) {
      setState(() {});
    }
  }

  int _isolateStart = 0;
  late ReceivePort receivePort;

  Future<void> _createIsolate({required String cityId}) async {
    p('...................._createIsolate starting .. cityId: $cityId');
    try {
      setState(() {
        isCaching = true;
      });
      //build isolate artifacts
      _isolateStart = DateTime.now().millisecondsSinceEpoch;
      receivePort = ReceivePort();
      p('receivePort has been set up. ${receivePort.sendPort.toString()}');
      var errorReceivePort = ReceivePort();
      //pass sendPort to the params so isolate can send messages
      // params.sendPort = receivePort.sendPort;
      IsolateChannel channel =
          IsolateChannel(receivePort, receivePort.sendPort);
      channel.stream.listen((data) async {
        if (data != null) {
          p('${Emoji.heartBlue}${Emoji.heartBlue}${Emoji.heartBlue} '
              'CacheManager: Received cacheService result ${Emoji.appleRed} CacheMessage '
              'statusCode: ${data['statusCode']} type: ${data['type']} msg: ${data['message']}');
          try {
            var msg = CacheMessage.fromJson(data);
            switch (msg.type) {
              case typeMessage:
                await _processMessage(msg);
                break;
              case typeEvent:
                _saveEvents(msg);
                break;

              default:
                p('${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}'
                    'CacheManger: ........... type not available! wtf? ${Emoji.redDot}');
                break;
            }
            _scrollToBottom();
          } catch (e) {
            p(e);
            if (mounted) {
              setState(() {
                isCaching = false;
              });
              _scrollToBottom();
            }
          }
        }
      });

      String? url = _getUrlPrefix();
      if (url == null) {
        throw Exception("CacheManager: Crucial Url parameter missing! 🔴🔴");
      }

      var min = numberOfDays * 24 * 60;

      var params = CacheParameters(
        sendPort: receivePort.sendPort,
        minutesAgo: min,
        url: url,
        useCacheService: true,
        cityId: cityId,
      );

      isolate = await Isolate.spawn<CacheParameters>(heavyTask, params,
          paused: true,
          onError: errorReceivePort.sendPort,
          onExit: receivePort!.sendPort);

      isolate.addErrorListener(errorReceivePort.sendPort);
      isolate.resume(isolate.pauseCapability!);
      isolate.addOnExitListener(receivePort!.sendPort);

      errorReceivePort.listen((e) {
        p('${Emoji.redDot}${Emoji.redDot} exception occurred: $e');
        isCaching = false;
        setState(() {});
        var ding = EmojiAlert(
          emojiSize: 32,
          alertTitle: const Text('DataDriver+'),
          background: Theme.of(context).backgroundColor,
          height: 200,
          emojiType: EMOJI_TYPE.SCARED,
          description: Text(
            'Error $e',
            style: const TextStyle(fontSize: 11),
          ),
        );
        ding.displayAlert(context);
      });
    } catch (e) {
      p('${Emoji.redDot} we have a problem: $e ${Emoji.redDot} ${Emoji.redDot}');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int numberOfDays = 1;

  void _navigateToDetails() {
    if (!_eventsCached) {
      p('Events are still being cached, please wait ...');
    }
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child:  CityDetailsPage(numberOfDays: numberOfDays, city: selectedCity!)));


  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('City Cache'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 24,
                    ),
                    selectedCity == null
                        ? const SizedBox()
                        : InkWell(
                          onTap: _navigateToDetails,
                          child: Text(
                              '${selectedCity!.city}',
                              style: GoogleFonts.secularOne(
                                  textStyle:
                                      Theme.of(context).textTheme.bodyLarge,
                                  fontWeight: FontWeight.w900),
                            ),
                        ),
                    SizedBox(
                            height: 80,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Events Cached',
                                      style: GoogleFonts.lato(
                                          textStyle:
                                              Theme.of(context).textTheme.bodySmall,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                                Row(mainAxisAlignment: MainAxisAlignment.center,
                                  children:  [
                                    Text('Number of Days', style: GoogleFonts.lato(
                                        textStyle: Theme.of(context).textTheme.bodySmall,
                                        fontWeight: FontWeight.normal),),
                                    const SizedBox(width: 4,),
                                    DaysSelector(onSelected: (value) {
                                        setState(() {
                                          numberOfDays = value;
                                        });
                                    }),
                                    const SizedBox(width: 16,),
                                    numberOfDays > 0? Text('$numberOfDays', style: GoogleFonts.secularOne(
                                        textStyle: Theme.of(context).textTheme.bodyMedium,
                                        fontWeight: FontWeight.w900),):const SizedBox(),
                                  ],
                                ),
                              ],
                            ),
                          ),

                      Expanded(

                          child: AnimatedBuilder(
                            animation: _controller,

                            builder: (BuildContext context, Widget? child) {
                              return FadeScaleTransition(animation: _controller, child: child,);
                            },
                            child: ListView.builder(
                                itemCount: cities.length,
                                itemBuilder: (context, index) {
                                  var city = cities.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      selectedCity = city;
                                      _controller.reverse().then((value) => _controller.forward());
                                      _createIsolate(cityId: city.id!);
                                    },
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '${Emoji.appleGreen} ${city.city} ${city.adminName == null ? '' : ',${city.adminName}'}',
                                          style: GoogleFonts.lato(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              fontWeight: FontWeight.normal),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                      ),

                  ],
                ),
              ),
            ),
          ),
          isCaching
              ? const Positioned(
                  left: 4,
                  top: 16,
                  child: CachingCard(),
                )
              : const SizedBox(
                  height: 0,
                ),
        ],
      ),
    ));
  }
}

//task run in the isolate
Future<void> heavyTask(CacheParameters cacheParams) async {
  p('\n\n${Emoji.redDot}${Emoji.redDot}${Emoji.redDot} '
      '.... Heavy isolate cache task starting ...........');

  cacheService.cacheCityEvents(parameters: cacheParams);
}

class DaysSelector extends StatelessWidget {
  const DaysSelector({Key? key, required this.onSelected}) : super(key: key);
  final Function(int) onSelected;
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
        items: const [
      DropdownMenuItem(value: 1, child: Text('1')),
      DropdownMenuItem(value: 2, child: Text('2')),
      DropdownMenuItem(value: 3, child: Text('3')),
      // DropdownMenuItem(value: 4, child: Text('4')),
      // DropdownMenuItem(value: 5, child: Text('5')),
    ], onChanged: onChanged);
  }

  void onChanged(int? value) {
    onSelected(value!);
  }
}

