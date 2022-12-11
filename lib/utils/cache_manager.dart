import 'dart:convert';
import 'dart:isolate';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:universal_frontend/data_models/city_place.dart';
import 'package:universal_frontend/services/cache_service.dart';
import 'package:universal_frontend/utils/util.dart';

import '../data_models/city.dart';
import '../data_models/event.dart';
import 'emojis.dart';
import 'hive_util.dart';

class CacheManager extends StatefulWidget {
  const CacheManager({Key? key}) : super(key: key);

  @override
  CacheManagerState createState() => CacheManagerState();
}

class CacheManagerState extends State<CacheManager>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  ScrollController listScrollController = ScrollController();
  late Isolate isolate;
  late ReceivePort receivePort = ReceivePort();
  var messages = <CacheMessage>[];
  bool isCaching = false;
  var cities = <City>[];



  @override
  void initState() {
    _animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 2000),
      reverseDuration: const Duration(milliseconds: 2000),
      vsync: this,
    )..addStatusListener((AnimationStatus status) {
      setState(() {
        // setState needs to be called to trigger a rebuild because
        // the 'HIDE FAB'/'SHOW FAB' button needs to be updated based
        // the latest value of [_controller.status].
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _saveCities(CacheMessage msg) async {
    cities.clear();
    String mJson = msg.cities!;
    List m = jsonDecode(mJson);
    p('\n${Emoji.blueDot} CacheManager decoded cities json: ${m.length} ');
    for (var value in m) {
      var k = City.fromJson(value);
      cities.add(k);
    }

    await hiveUtil.addCities(cities: cities);
    p('\n\nCacheManager: ${Emoji.appleRed}${Emoji.appleRed}${Emoji.appleRed}'
        ' ${cities.length} cities cached in Hive');
    setState(() {});
  }

  void _savePlaces(CacheMessage msg) async {
    var places = <CityPlace>[];
    String mJson = msg.places!;
    List m = jsonDecode(mJson);
    for (var value in m) {
      var k = CityPlace.fromJson(value);
      places.add(k);
    }
    await hiveUtil.addPlaces(places: places);
    p('CacheManager: ${Emoji.appleRed}${Emoji.appleRed} ${places.length} places cached in Hive');
  }

  void _saveEvents(CacheMessage msg) async {
    var events = <Event>[];
    String mJson = msg.events!;
    List m = jsonDecode(mJson);
    for (var value in m) {
      var k = Event.fromJson(value);
      events.add(k);
    }
    await hiveUtil.addEvents(events: events);
    p('CacheManager: ${Emoji.appleRed}${Emoji.appleRed} ${events.length} events cached in Hive');
  }

  void _startCache() async {
    setState(() {
      isCaching = true;
    });
    _createIsolate();
  }

  Future<void> _createIsolate() async {
    try {
      receivePort = ReceivePort();
      var errorReceivePort = ReceivePort();
      //pass sendPort to the params so isolate can send messages
      // params.sendPort = receivePort.sendPort;
      IsolateChannel channel =
          IsolateChannel(receivePort, receivePort.sendPort);
      channel.stream.listen((data) {
        if (data != null) {
          p('${Emoji.heartBlue}${Emoji.heartBlue} '
              'Received cacheService result ${Emoji.appleRed} CacheMessage, '
              'statusCode: ${data['statusCode']} type: ${data['type']} msg: ${data['message']}');
          try {
            var msg = CacheMessage.fromJson(data);
            switch (msg.type) {
              case TYPE_MESSAGE:
                messages.add(msg);
                if (msg.statusCode == STATUS_DONE) {
                  isCaching = false;
                  p('\n${Emoji.redDot}${Emoji.redDot} '
                      'received end message from CacheService, will remove loading ui '
                      '${Emoji.heartBlue}${Emoji.heartBlue}');
                }
                setState(() {});
                break;
              case TYPE_CITY:
                _saveCities(msg);
                break;
              case TYPE_PLACE:
                _savePlaces(msg);
                break;
              case TYPE_EVENT:
                _saveEvents(msg);
                break;
              default:
                p('........... type not available! wtf? ${Emoji.redDot}');
                break;
            }
            _scrollToBottom();
          } catch (e) {
            p(e);
            setState(() {
              isCaching = false;
            });
            _scrollToBottom();

          }
        }
      });

      var status = dotenv.env['CURRENT_STATUS'];
      String? url = '';
      if (status == 'dev') {
        url = dotenv.env['DEV_URL'];
      }
      if (status == 'prod') {
        url = dotenv.env['PROD_URL'];
      }
      var params = CacheParameters(sendPort: receivePort.sendPort, url: url!);
      isolate = await Isolate.spawn<CacheParameters>(heavyTask, params,
          paused: true,
          onError: errorReceivePort.sendPort,
          onExit: receivePort.sendPort);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Boss'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left:8.0, right: 24,top: 16, bottom: 16),
            child: AnimatedBuilder(animation: _animationController,
                builder: (context, child){
                  return FadeScaleTransition(
                      animation: _animationController,
                      child: child);

                },
                child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 16,
                    ),
                    const Text('Data caching logs'),
                    const SizedBox(
                      height: 8,
                    ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: messages.length,
                          controller: listScrollController,
                          itemBuilder: (context, index) {
                            var msg = messages.elementAt(index);
                            return messages.isEmpty
                                ? const Center(
                                    child: Text('No Progress yet'),
                                  )
                                : Card(
                                    elevation: 0,
                                    child: Row(
                                      children: [
                                        Text(
                                          'Code: ${msg.statusCode}',
                                          style: GoogleFonts.lato(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 11),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          '${msg.elapsedSeconds?.toStringAsFixed(1)} sec',
                                          style: GoogleFonts.lato(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 11),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Flexible(
                                          child: Text(
                                            msg.message,
                                            style: GoogleFonts.lato(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                          }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          isCaching
              ? Positioned(
                  left: 32,
                  bottom: 32,
                  child: Card(
                    elevation: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Text(
                            'Caching data',
                            style: GoogleFonts.lato(
                                textStyle:
                                    Theme.of(context).textTheme.bodySmall,
                                fontWeight: FontWeight.normal,
                                fontSize: 12),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              backgroundColor: Colors.pink,
                            ),
                          )
                        ],
                      ),
                    ),
                  ))
              : const SizedBox(
                  height: 0,
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        onPressed: () {
          if (isCaching) {
            p('${Emoji.redDot} Sorry, this exchange is currently busy!');
            return;
          }
          _animationController.forward();
          _startCache();
        },
        child: isCaching? const Icon(Icons.event_busy):const Icon(Icons.directions_walk),
      ),
    );
  }
}

//task run in the isolate
Future<void> heavyTask(CacheParameters cacheParams) async {
  p('${Emoji.redDot}${Emoji.redDot}${Emoji.redDot} '
      'Heavy cache task starting ...........');
  cacheService.startCaching(params: cacheParams);
}
