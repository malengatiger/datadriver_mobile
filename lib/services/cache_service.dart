import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/cache_bag.dart';
import 'package:universal_frontend/data_models/cache_config.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/data_models/city_place.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:http/http.dart' as http;

import '../data_models/city.dart';
import '../data_models/event.dart';
import '../utils/util.dart';

final CacheService cacheService = CacheService._instance;

class CacheParameters {
  late SendPort sendPort;
  late String url;
  late City? city;
  late bool useCacheService = true;
  late CacheConfig cacheConfig;

  CacheParameters({
    required this.sendPort,
    required this.url,
    this.city,
    required this.useCacheService,
    required this.cacheConfig,
  });
}

class CacheMessage {
  late String message;
  late int statusCode;
  late int type;
  late String date;
  late double? elapsedSeconds;
  late String? cities, places, events, aggregates, dashboards;
  late Map<String, dynamic>? cacheBagJson;

  CacheMessage(
      {required this.message,
      required this.statusCode,
      required this.date,
      required this.elapsedSeconds,
      required this.type,
      this.cacheBagJson,
      this.cities,
      this.places,
      this.events,
      this.aggregates,
      this.dashboards});

  CacheMessage.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    type = json['type'];
    statusCode = json['statusCode'];
    date = json['date'];
    elapsedSeconds = json['elapsedSeconds'];
    cities = json['cities'];
    places = json['places'];
    events = json['events'];
    aggregates = json['aggregates'];
    dashboards = json['dashboards'];
    cacheBagJson = json['cacheBagJson'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'elapsedSeconds': elapsedSeconds,
        'message': message,
        'date': date,
        'type': type,
        'statusCode': statusCode,
        'cities': cities,
        'places': places,
        'events': events,
        'dashboards': dashboards,
        'aggregates': aggregates,
        'cacheBagJson': cacheBagJson,
      };
}

const TYPE_MESSAGE = 0,
    TYPE_CITY = 1,
    TYPE_PLACE = 2,
    TYPE_EVENT = 3,
    TYPE_AGGREGATES = 4,
    TYPE_DASHBOARDS = 5,
    TYPE_CACHE_BAG = 6;
const STATUS_BUSY = 201, STATUS_DONE = 200, STATUS_ERROR = 500;

class CacheService {
  static final CacheService _instance = CacheService._internal();

  // using a factory is important
  // because it promises to return _an_ object of this type
  // but it doesn't promise to make a new one.
  factory CacheService() {
    return _instance;
  }

  // This named constructor is the "real" constructor
  // It'll be called exactly once, by the static property assignment above
  // it's also private, so it can only be called in this class
  CacheService._internal() {
    // initialization logic
  }

  var cities = <City>[];
  var places = <CityPlace>[];
  var start = 0;
  final numberFormat = NumberFormat.compact();

  static late SendPort sendPort;
  static late CacheParameters cacheParameters;

  void startCaching({required CacheParameters params}) async {
    sendPort = params.sendPort;
    cacheParameters = params;

    p('\n\n${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
        ' CacheService: .......... preparing remote data for storing in local hive cache ...');
    start = DateTime.now().millisecondsSinceEpoch;

    int minutesAgo = _calculateMinutes();
    if (params.useCacheService) {
      p('${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
          ' CacheService: .......... preparing remote data from $minutesAgo minutesAgo ago (15 minutesAgo added) ...');
      _getDataForCaching(minutesAgo: minutesAgo, url: params.url);
      return;
    }

    var url = params.url;
    if (params.city != null) {
      _cacheOneCity(params: params);
      return;
    }
    //cache dashboards
    var m = await _cacheDashboards(url: url, config: params.cacheConfig);
    _processMessage(mStart: start, message: '$m dashboards');
    //cache cities
    var i = await _cacheCities(url: url);
    _processMessage(mStart: start, message: '$i cities');

    p('${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
        ' CacheService: caching places and events for ${cities.length} cities ...');
    if (cities.isNotEmpty) {
      for (var city in cities) {
        //cache places ....
        var mStart = DateTime.now().millisecondsSinceEpoch;
        var numberOfPlaces = await _cachePlaces(
            cityId: city.id!, cityName: city.city!, url: url);
        _processMessage(
            mStart: mStart,
            message:
                '🍎${city.city} - ${numberFormat.format(numberOfPlaces)} places');
        //cache events ...
        mStart = DateTime.now().millisecondsSinceEpoch;
        var numberOfEvents = await _cacheEvents(
            cityId: city.id!,
            cityName: city.city!,
            url: url,
            config: params.cacheConfig);
        _processMessage(
            mStart: mStart,
            message:
                '🥬${city.city} - ${numberFormat.format(numberOfEvents)} events');

        //cache aggregates
        mStart = DateTime.now().millisecondsSinceEpoch;
        var aggregates = await _cacheAggregates(
            cityId: city.id!,
            cityName: city.city!,
            url: url,
            config: params.cacheConfig);
        _processMessage(
            mStart: mStart,
            message:
                '🥬${city.city} - ${numberFormat.format(aggregates)} aggregates');
      }
    } else {
      p('${Emoji.redDot} ${Emoji.redDot} No cities found anywhere!');
      p('\n 🔴🔴🔴🔴🔴🔴 CacheService: Caching has NOT been done. No cities!  🔴🔴🔴🔴🔴🔴\n');
      var end = DateTime.now().millisecondsSinceEpoch;
      var secs = (end - start) / 1000;
      var msg = CacheMessage(
          message: 'Errors stumbled upon. No cities, Senor!',
          statusCode: STATUS_ERROR,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: secs,
          type: TYPE_MESSAGE);
      sendPort.send(msg.toJson());
      return;
    }

    p('\n🔵🔵🔵🔵🔵🔵 CacheService: Caching has been completed! 🔵🔵🔵🔵🔵🔵🔵\n');
    var end = DateTime.now().millisecondsSinceEpoch;
    var secs = (end - start) / 1000;

    var msg = CacheMessage(
        message: '🔵Caching completed!',
        statusCode: STATUS_DONE,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: secs,
        type: TYPE_MESSAGE);

    sendPort.send(msg.toJson());
    p('${Emoji.leaf} CacheService: Main caching took $secs seconds to complete! ${Emoji.redDot}${Emoji.redDot}');
  }

  int _calculateMinutes() {
    var prevDate = DateTime.fromMillisecondsSinceEpoch(cacheParameters.cacheConfig.longDate);
    p('${Emoji.leaf} CacheService: cacheConfig date: ${prevDate.toIso8601String()} ${Emoji.redDot}');

    var nowDate = DateTime.now();
    var milliseconds = nowDate.millisecondsSinceEpoch - prevDate.millisecondsSinceEpoch;
    var minutes = milliseconds / 1000 ~/ 60;
    if (minutes < 100) {
      minutes = 120;
    }
    p('${Emoji.blueDot} CacheService: minutesAgo calculated: $minutes ${Emoji.redDot}');

    return minutes;
  }

  void _cacheOneCity({required CacheParameters params}) async {
    sendPort = params.sendPort;
    p('\n\n${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
        ' CacheService: cacheOneCity .......... preparing remote data for storing in local hive cache ...');
    var mStart = DateTime.now().millisecondsSinceEpoch;
    start = DateTime.now().millisecondsSinceEpoch;
    places = await _getCityPlaces(cityId: params.city!.id!, url: params.url);
    var mEnd = DateTime.now().millisecondsSinceEpoch;
    double elapsed = (mEnd - mStart) / 1000;
    String jsonTags = jsonEncode(places);
    var msg = CacheMessage(
        message: '${params.city!.city!} ${places.length} places cached',
        statusCode: STATUS_BUSY,
        places: jsonTags,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_PLACE);

    p('${Emoji.leaf}${Emoji.leaf} CacheService: returning ${places.length} places via sendPort: ${params.city!.city}\n');
    sendPort.send(msg.toJson());
    msg = CacheMessage(
        message:
            '💙${params.city!.city!} ${numberFormat.format(places.length)} places',
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg.toJson());
    //events
    mStart = DateTime.now().millisecondsSinceEpoch;
    var minutes =
        (DateTime.now().millisecondsSinceEpoch - params.cacheConfig.longDate) /
            1000 ~/
            60;
    minutes += 15;

    var events = await _getCityEvents(
        cityId: params.city!.id!,
        minutesAgo: minutes,
        url: params.url); //3 days worth of events
    mEnd = DateTime.now().millisecondsSinceEpoch;
    elapsed = (mEnd - mStart) / 1000;
    jsonTags = jsonEncode(events);
    //send events
    msg = CacheMessage(
        message: '💙${params.city!.city!} ${events.length} events',
        statusCode: STATUS_BUSY,
        events: jsonTags,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_EVENT);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${events.length} events via sendPort: ${params.city!.city}\n');
    sendPort.send(msg.toJson());
    //send events message
    msg = CacheMessage(
        message:
            '💙${params.city!.city!} ${numberFormat.format(events.length)} events',
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning caching DONE message via sendPort: ${params.city!.city!}\n');
    sendPort.send(msg.toJson());
    //send aggregates message
    mStart = DateTime.now().millisecondsSinceEpoch;
    var m = _cacheAggregates(
        cityId: params.city!.id!,
        url: params.url,
        config: params.cacheConfig,
        cityName: params.city!.city!);
    mEnd = DateTime.now().millisecondsSinceEpoch;
    elapsed = (mEnd - mStart) / 1000;
    jsonTags = jsonEncode(events);
    msg = CacheMessage(
        message: '💙${params.city!.city!} ${numberFormat.format(m)} aggregates',
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        aggregates: jsonTags,
        elapsedSeconds: elapsed,
        type: TYPE_AGGREGATES);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning caching DONE message via sendPort: ${params.city!.city!}\n');
    sendPort.send(msg.toJson());

    //send DONE message
    elapsed = (mEnd - start) / 1000;
    msg = CacheMessage(
        message: '🍎${params.city!.city!} completed!',
        statusCode: STATUS_DONE,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning caching DONE message via sendPort: ${params.city!.city}\n');
    sendPort.send(msg.toJson());
  }

  void _processMessage({required int mStart, required String message}) {
    var mEnd = DateTime.now().millisecondsSinceEpoch;
    var elapsed = (mEnd - mStart) / 1000;
    var msg = CacheMessage(
        message: message,
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg.toJson());
  }

  Future<int> _cacheCities({required String url}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    cities = await _getCities(url);
    cities.sort((a, b) => a.city!.compareTo(b.city!));
    var mEnd = DateTime.now().millisecondsSinceEpoch;
    double elapsed = (mEnd - mStart) / 1000;
    String jsonTags = jsonEncode(cities);

    var msg = CacheMessage(
        message: '${cities.length} cities found',
        statusCode: STATUS_BUSY,
        cities: jsonTags,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_CITY);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${cities.length} cities via sendPort\n');
    sendPort.send(msg.toJson());
    return cities.length;
  }

  Future<int> _cachePlaces(
      {required String cityId,
      required String cityName,
      required String url}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    places = await _getCityPlaces(cityId: cityId, url: url);
    places.sort((a, b) => a.name!.compareTo(b.name!));
    var mEnd = DateTime.now().millisecondsSinceEpoch;
    double elapsed = (mEnd - mStart) / 1000;
    String jsonTags = jsonEncode(places);
    var msg = CacheMessage(
        message: 'places cached',
        statusCode: STATUS_BUSY,
        places: jsonTags,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_PLACE);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${places.length} places via sendPort: $cityName\n');
    sendPort.send(msg.toJson());
    return places.length;
  }

  Future<int> _cacheAggregates(
      {required String cityId,
      required String cityName,
      required String url,
      required CacheConfig config}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    var minutes = 0;
    minutes =
        (DateTime.now().millisecondsSinceEpoch - config.longDate) / 1000 ~/ 60;
    minutes += 15;

    var aggregates =
        await _getCityAggregates(cityId: cityId, url: url, minutesAgo: minutes);
    if (aggregates.isEmpty) {
      p('${Emoji.redDot} Aggregates not found');
      return 0;
    }
    var mEnd = DateTime.now().millisecondsSinceEpoch;
    double elapsed = (mEnd - mStart) / 1000;
    String jsonTags = jsonEncode(aggregates);
    var msg = CacheMessage(
        message: 'city aggregates returned',
        statusCode: STATUS_BUSY,
        aggregates: jsonTags,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_AGGREGATES);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${aggregates.length} aggregates via sendPort: $cityName\n');
    sendPort.send(msg.toJson());
    return aggregates.length;
  }

  Future<int> _cacheEvents(
      {required String cityId,
      required String cityName,
      required String url,
      required CacheConfig config}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    try {
      var minutes = 0;
      minutes = (DateTime.now().millisecondsSinceEpoch - config.longDate) /
          1000 ~/
          60;
      minutes += 15;

      var events =
          await _getCityEvents(cityId: cityId, minutesAgo: minutes, url: url);

      if (events.isEmpty) {
        p('\n${Emoji.blueDot} No events found for minutesAgo: $minutes');
        return 0;
      }
      var mEnd = DateTime.now().millisecondsSinceEpoch;
      double elapsed = (mEnd - mStart) / 1000;
      String jsonTags = jsonEncode(events);
      var msg = CacheMessage(
          message: '$cityName events cached',
          statusCode: STATUS_BUSY,
          events: jsonTags,
          date: DateTime.now().toIso8601String(),
          elapsedSeconds: elapsed,
          type: TYPE_EVENT);

      p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${events.length} events via sendPort: $cityName\n');
      sendPort.send(msg.toJson());
      return events.length;
    } catch (e) {
      _handleError(e);
    }
    return 0;
  }

  Future<int> _cacheDashboards(
      {required String url, required CacheConfig config}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    var minutes = 0;
    minutes =
        (DateTime.now().millisecondsSinceEpoch - config.longDate) / 1000 ~/ 60;
    minutes += 15;

    var dashboards = await _getDashboards(minutesAgo: minutes, url: url);
    var mEnd = DateTime.now().millisecondsSinceEpoch;
    double elapsed = (mEnd - mStart) / 1000;
    String jsonTags = jsonEncode(dashboards);
    var msg = CacheMessage(
        message: '${dashboards.length} dashboards cached',
        statusCode: STATUS_BUSY,
        dashboards: jsonTags,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_DASHBOARDS);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${dashboards.length} '
        'dashboards via sendPort: ${dashboards.length}\n');
    sendPort.send(msg.toJson());
    return dashboards.length;
  }

  static Future<List<City>> _getCities(String url) async {
    var client = http.Client();
    var suffix1 = 'getCities';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var cities = <City>[];
    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var start = DateTime.now().millisecondsSinceEpoch;

      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 30));
      p('${Emoji.brocolli}${Emoji.brocolli} CacheService: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      var end = DateTime.now().millisecondsSinceEpoch;
      double elapsed = _printElapsed(end, start);

      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        cities = List<City>.from(l.map((model) => City.fromJson(model)));
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleError(e);
    }
    return cities;
  }

  static Future<List<CityPlace>> _getCityPlaces(
      {required String cityId, required String url}) async {
    var client = http.Client();
    var suffix1 = 'getPlacesByCity?cityId=$cityId';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var cityPlaces = <CityPlace>[];
    var filteredCityPlaces = <CityPlace>[];
    var start = DateTime.now().millisecondsSinceEpoch;

    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 30));
      printStatusCode(response);
      var end = DateTime.now().millisecondsSinceEpoch;
      double elapsed = _printElapsed(end, start);
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        cityPlaces =
            List<CityPlace>.from(l.map((model) => CityPlace.fromJson(model)));
        for (var place in cityPlaces) {
          if (place.geometry != null) {
            filteredCityPlaces.add(place);
          }
        }
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleError(e);
    }
    return filteredCityPlaces;
  }

  static Future<List<CityAggregate>> _getCityAggregates(
      {required String cityId,
      required String url,
      required int minutesAgo}) async {
    var client = http.Client();
    var suffix1 =
        'getCityAggregatesByCity?cityId=$cityId&minutesAgo=$minutesAgo';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var aggregates = <CityAggregate>[];
    var start = DateTime.now().millisecondsSinceEpoch;

    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 30));
      p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode} body length: ${response.body.length}');
      var end = DateTime.now().millisecondsSinceEpoch;
      double elapsed = _printElapsed(end, start);
      if (response.statusCode == 200) {
        Iterable jsonIterable = json.decode(response.body);
        aggregates = List<CityAggregate>.from(
            jsonIterable.map((model) => CityAggregate.fromJson(model)));
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleError(e);
    }
    return aggregates;
  }

  static Future<List<Event>> _getCityEvents(
      {required String cityId,
      required int minutesAgo,
      required String url}) async {
    var client = http.Client();
    var suffix1 = 'getCityEvents?cityId=$cityId&minutes=$minutesAgo';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var events = <Event>[];
    var start = DateTime.now().millisecondsSinceEpoch;

    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 90));
      printStatusCode(response);
      var end = DateTime.now().millisecondsSinceEpoch;
      double elapsed = _printElapsed(end, start);
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        events = List<Event>.from(l.map((model) => Event.fromJson(model)));
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleError(e);
    }
    return events;
  }

  static Future<List<DashboardData>> _getDashboards(
      {required int minutesAgo, required String url}) async {
    var client = http.Client();
    var suffix1 = 'getDashboardData?minutesAgo=$minutesAgo';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var dashboards = <DashboardData>[];
    var start = DateTime.now().millisecondsSinceEpoch;

    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 90));
      printStatusCode(response);
      var end = DateTime.now().millisecondsSinceEpoch;
      double elapsed = _printElapsed(end, start);
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        dashboards = List<DashboardData>.from(
            l.map((model) => DashboardData.fromJson(model)));
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      _handleError(e);
    }
    return dashboards;
  }

  Future<void> _getDataForCaching(
      {required int minutesAgo, required String url}) async {
    p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: ....... starting _getDataForCaching: minutesAgo: $minutesAgo');
    var client = http.Client();
    var suffix1 = 'getDataForCache?minutesAgo=$minutesAgo';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var start = DateTime.now().millisecondsSinceEpoch;
    CacheBag? cacheBag;
    try {
      p("$heartOrange _getDataForCaching: HTTP Url: $fullUrl");

      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 9000));

      printStatusCode(response);
      var end = DateTime.now().millisecondsSinceEpoch;
      double elapsed = _printElapsed(end, start);

      if (response.statusCode == 200) {
        p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: unpacking the data coming in ...');

        var data = json.decode(response.body);
        cacheBag = CacheBag.fromJson(data);
        cacheBag.elapsedSeconds = elapsed;

        _printCacheBag(cacheBag);

        var msg = CacheMessage(
            message: "cacheBag",
            statusCode: STATUS_BUSY,
            date: DateTime.now().toIso8601String(),
            elapsedSeconds: elapsed,
            type: TYPE_CACHE_BAG,
            cacheBagJson: cacheBag.toJson());
        p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: sending cacheBag over the sendPort ...');
        sendPort.send(msg.toJson());

        _sendCacheBagMessages(cacheBag, elapsed);

        Future.delayed(const Duration(milliseconds: 500), () {
          p('${Emoji.brocolli}${Emoji.brocolli} cacheService: Sending DONE message after waiting 500 milliseconds');
          var msg = CacheMessage(
              message: "${Emoji.appleRed} Data extract completed",
              statusCode: STATUS_DONE,
              date: DateTime.now().toIso8601String(),
              elapsedSeconds: elapsed,
              type: TYPE_MESSAGE);
          sendPort.send(msg.toJson());
        });
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        var e = Exception(
            'Server could not handle request, status: ${response.statusCode} - ${response.body}');
        _handleError(e);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _sendCacheBagMessages(CacheBag cacheBag, double elapsed) {
    var fm = NumberFormat.decimalPattern();
    var msg1 = CacheMessage(
        message: "${Emoji.blueDot} ${cacheBag.cities.length} cities",
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg1.toJson());

    var msg2 = CacheMessage(
        message: "${Emoji.blueDot} ${fm.format(cacheBag.places.length)} places",
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg2.toJson());


    var msg3 = CacheMessage(
        message: "${Emoji.blueDot} ${cacheBag.dashboards.length} dashboards",
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg3.toJson());

    var msg4 = CacheMessage(
        message: "${Emoji.blueDot} ${fm.format(cacheBag.aggregates.length)} aggregates",
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg4.toJson());

    var msg5 = CacheMessage(
        message: "${Emoji.blueDot} ${fm.format(cacheBag.events.length)} events",
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg5.toJson());

    var msg6 = CacheMessage(
        message: "${Emoji.peach} ${cacheBag.elapsedSeconds.toStringAsFixed(1)} seconds elapsed",
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg6.toJson());
  }

  static void _printCacheBag(CacheBag bag) {
    p('\n${Emoji.blueDot}${Emoji.blueDot} CacheBag: date: ${bag.date} cities: ${bag.cities.length} '
        'places: ${bag.places.length} dashboards: ${bag.dashboards.length} '
        'aggregates: ${bag.aggregates.length} events: ${bag.events.length}');
    p('${Emoji.blueDot}${Emoji.blueDot} CacheBag: Call took: ${bag.elapsedSeconds} seconds to execute ${Emoji.blueDot}\n');
  }
  static void printStatusCode(http.Response response) {
    p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: We have a response from the DataDriver API! $heartOrange '
        'statusCode: ${response.statusCode}');
  }

  static double _printElapsed(int end, int start) {
    var elapsed = (end - start) / 1000;
    p('${Emoji.brocolli}${Emoji.brocolli} CacheService: '
        ' elapsed time for network call: $heartOrange '
        ' $elapsed seconds');
    return elapsed;
  }

  static void _handleError(dynamic e) {
    p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Things got a little troubled!  $blueDot error: $e');
    var msg = CacheMessage(
        message: "$e",
        statusCode: STATUS_ERROR,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: 0,
        type: TYPE_MESSAGE,);
    sendPort.send(msg.toJson());
  }
}
