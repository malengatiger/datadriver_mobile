import 'dart:convert';
import 'dart:isolate';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:universal_frontend/data_models/city_place.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/services/cache_service.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/utils/providers.dart';
import 'package:universal_frontend/utils/util.dart';

import '../data_models/city.dart';
import '../data_models/city_aggregate.dart';
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
  var _showCities = false;
  var _isolateStart = 0;
  int? _isolateEnd;

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
    _getCities();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _getCities() async {
    cities = (await hiveUtil.getCities());
    p('${Emoji.leaf} Cities from Hive cache: ${cities.length}');
    if (cities.isEmpty) {
      cities = await DataService.getCities();
    }
    cities.sort((a, b) => a.city!.compareTo(b.city!));
    setState(() {});
  }

  void _saveCities(CacheMessage msg) async {
    cities.clear();
    String mJson = msg.cities!;
    List m = jsonDecode(mJson);
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
  }

  void _saveDashboards(CacheMessage msg) async {
    String mJson = msg.dashboards!;
    List m = jsonDecode(mJson);
    for (var value in m) {
      var k = DashboardData.fromJson(value);
      await hiveUtil.addDashboardData(data: k);
    }
  }

  void _saveAggregates(CacheMessage msg) async {
    String mJson = msg.aggregates!;
    List m = jsonDecode(mJson);
    var aggregates = <CityAggregate>[];
    for (var value in m) {
      var k = CityAggregate.fromJson(value);
      aggregates.add(k);
    }
    await hiveUtil.addAggregates(aggregates: aggregates);
  }

  void _startCache() async {
    setState(() {
      messages.clear();
      isCaching = true;
      _isolateStart = DateTime.now().millisecondsSinceEpoch;
      _isolateEnd = null;
    });

    _createIsolate(daysAgo: daysAgo);
  }

  Future<void> _createIsolate({City? city, required int daysAgo}) async {
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
              'CaheManager: Received cacheService result ${Emoji.appleRed} CacheMessage, '
              'statusCode: ${data['statusCode']} type: ${data['type']} msg: ${data['message']}');
          try {
            var msg = CacheMessage.fromJson(data);
            switch (msg.type) {
              case TYPE_MESSAGE:
                messages.add(msg);
                if (msg.statusCode == STATUS_DONE) {
                  isCaching = false;
                  p('\n${Emoji.redDot}${Emoji.redDot} '
                      'CacheManager: received end message from CacheService, will remove loading ui '
                      '${Emoji.heartBlue}${Emoji.heartBlue}');
                }
                selectedCity = null;
                setState(() {
                  _isolateEnd = DateTime.now().millisecondsSinceEpoch;
                });
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
              case TYPE_DASHBOARDS:
                _saveDashboards(msg);
                break;
              case TYPE_AGGREGATES:
                _saveAggregates(msg);
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
      var params = CacheParameters(
          sendPort: receivePort.sendPort,
          url: url,
          city: city,
          daysAgo: daysAgo);

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
    } catch (e) {
      p('${Emoji.redDot} we have a problem ${Emoji.redDot} ${Emoji.redDot}');
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

  var txtController = TextEditingController(text: '14');

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        p('${Emoji.pear}${Emoji.pear} getting rid of possible keyboard!');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cache Boss'),
          backgroundColor: isDarkMode
              ? Theme.of(context).backgroundColor
              : Theme.of(context).secondaryHeaderColor,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(_isolateEnd == null ? 80 : 100),
            child: isCaching
                ? const SizedBox(
                    height: 0,
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Cache One City?',
                            style: GoogleFonts.lato(
                                textStyle:
                                    Theme.of(context).textTheme.bodySmall,
                                fontWeight: FontWeight.normal,
                                fontSize: 12, color: isDarkMode? Colors.white:Colors.black),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              controller: txtController,
                              onEditingComplete: () {},
                              decoration: InputDecoration(
                                  label: Text(
                                    'Days Ago',
                                    style: GoogleFonts.lato(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12),
                                  ),
                                  hintText: 'Enter Days Ago'),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDarkMode ? Colors.pink : Colors.yellow,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showCities = true;
                                });
                              },
                              child: Text(
                                'Yes',
                                style: GoogleFonts.lato(
                                    textStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12),
                              )),
                          const SizedBox(
                            width: 8,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      _isolateEnd == null
                          ? const SizedBox(
                              height: 0,
                            )
                          : Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total elapsed time: ',
                                        style: GoogleFonts.lato(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                            fontWeight: FontWeight.normal),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                          ((_isolateEnd! - _isolateStart) /
                                                  1000 /
                                                  60)
                                              .toStringAsFixed(1),
                                          style: GoogleFonts.lato(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              fontWeight: FontWeight.w900)),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Text('minutes',
                                          style: GoogleFonts.lato(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              fontWeight: FontWeight.normal))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      _isolateEnd == null
                          ? const SizedBox(
                              height: 0,
                            )
                          : const SizedBox(
                              height: 0,
                            ),
                    ],
                  ),
          ),
        ),
        backgroundColor: isDarkMode
            ? Theme.of(context).backgroundColor
            : Theme.of(context).secondaryHeaderColor,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 8.0, right: 24, top: 16, bottom: 16),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeScaleTransition(
                      animation: _animationController, child: child);
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Column(
                    children: [
                      SizedBox(
                        height: selectedCity == null ? 16 : 120,
                      ),
                      selectedCity == null
                          ? const Text('Data caching logs')
                          : Text('${selectedCity!.city} cache logs'),
                      SizedBox(
                        height: selectedCity == null ? 8 : 24,
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
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Card(
                                        elevation: 2,
                                        child: Row(
                                          children: [

                                            SizedBox(
                                              width: 60,
                                              child: Text(
                                                '${msg.elapsedSeconds?.toStringAsFixed(1)} sec',
                                                style: GoogleFonts.lato(
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                    fontSize: 11),
                                              ),
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
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
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
                    left: 4,
                    top: 0,
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
            _showCities
                ? Positioned(
                    child: CitySelector(
                        cities: cities, onSelected: onSelected, elevation: 4))
                : const SizedBox(
                    height: 0,
                  ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          elevation: 8,
          tooltip: 'Cache Every City',
          onPressed: () {
            if (isCaching) {
              p('${Emoji.redDot} Sorry, this exchange is currently busy!');
              return;
            }
            setState(() {
              selectedCity = null;
            });
            _animationController.forward();
            _startCache();
          },
          child: isCaching
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    backgroundColor: Colors.pink,
                  ))
              : const Icon(Icons.directions_walk),
        ),
      ),
    );
  }

  City? selectedCity;

  onSelected(City city) async {
    selectedCity = city;
    p('${Emoji.pear}${Emoji.pear} getting rid of possible keyboard from method onSelected!');
    FocusManager.instance.primaryFocus?.unfocus();
    messages.clear();

    setState(() {
      _showCities = false;
      isCaching = true;
    });
    _animationController.forward();
    p('${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}'
        ' creating isolate with daysAgo parameter = ${txtController.value.text}');

    //test code
    var places = await hiveUtil.getCityPlaces(cityId: city.id!);
    var events = await hiveUtil.getCityEventsAll(cityId: city.id!);
    if (places.isNotEmpty) {
      var ev = await hiveUtil.getPlaceEvents(placeId: places.first.placeId!);
      p('${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot} '
          'CacheManager:  ${ev.length} '
          'events found for ${places.first.name!}');
    }
    p('${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot} '
        'CacheManager: ${places.length} places and ${events.length} '
        'events found for ${selectedCity!.city}');
    //
    _createIsolate(
        city: selectedCity, daysAgo: int.parse(txtController.value.text));
  }
}

//task run in the isolate
Future<void> heavyTask(CacheParameters cacheParams) async {
  p('\n\n${Emoji.redDot}${Emoji.redDot}${Emoji.redDot} '
      'Heavy isolate cache task starting ...........');
  cacheService.startCaching(params: cacheParams);
}

class CitySelector extends StatelessWidget {
  const CitySelector(
      {Key? key,
      required this.cities,
      required this.onSelected,
      required this.elevation})
      : super(key: key);

  final List<City> cities;
  final double elevation;
  final Function(City) onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      child: Column(
        children: [
          const SizedBox(
            height: 12,
          ),
          const Text(
            'City List',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(
            height: 12,
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    var city = cities.elementAt(index);
                    return GestureDetector(
                      onTap: () {
                        onSelected(city);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text('${city.city}'),
                                const SizedBox(
                                  width: 4,
                                ),
                                city.adminName == null
                                    ? const SizedBox(
                                        height: 0,
                                      )
                                    : Text('${city.adminName}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  })),
        ],
      ),
    );
  }
}
