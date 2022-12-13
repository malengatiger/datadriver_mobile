import 'dart:convert';
import 'dart:isolate';

import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/city_place.dart';
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
  late int daysAgo = 3;

  CacheParameters({required this.sendPort, required this.url, this.city, required this.daysAgo});
}

class CacheMessage {
  late String message;
  late int statusCode;
  late int type;
  late String date;
  late double? elapsedSeconds;
  late String? cities, places, events;

  CacheMessage(
      {required this.message,
      required this.statusCode,
      required this.date,
      required this.elapsedSeconds,
      required this.type,
      this.cities,
      this.places,
      this.events});

  CacheMessage.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    type = json['type'];
    statusCode = json['statusCode'];
    date = json['date'];
    elapsedSeconds = json['elapsedSeconds'];
    cities = json['cities'];
    places = json['places'];
    events = json['events'];
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
      };
}

const TYPE_MESSAGE = 0, TYPE_CITY = 1, TYPE_PLACE = 2, TYPE_EVENT = 3;
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
  late SendPort sendPort;

  void startCaching({required CacheParameters params}) async {
    sendPort = params.sendPort;
    p('\n\n${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
        ' CacheService: .......... preparing remote data for storing in local hive cache ...');
    start = DateTime.now().millisecondsSinceEpoch;
    var url = params.url;
    if (params.city != null) {
        _cacheOneCity(params: params);
        return;
    }
    //cache cities
    await _cacheCities(url: url);
    _processMessage(mStart: start, message: 'cities');

    p('${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}'
        ' CacheService: caching places and events for ${cities.length} cities ...');
    if (cities.isNotEmpty) {
      for (var city in cities) {
        //cache places ....
        var mStart = DateTime.now().millisecondsSinceEpoch;
        await _cachePlaces(cityId: city.id!, cityName: city.city!, url: url);
        _processMessage(mStart: mStart, message: '🍎 ${city.city} places');

        //cache events ...
        mStart = DateTime.now().millisecondsSinceEpoch;
        await _cacheEvents(cityId: city.id!, cityName: city.city!, url: url, daysAgo: params.daysAgo);
        _processMessage(mStart: mStart, message: '🥬${city.city} events');
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

  final numberFormat = NumberFormat.compact();

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

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${places.length} places via sendPort: ${params.city}\n');
    sendPort.send(msg.toJson());
    msg = CacheMessage(
        message: '💙${params.city!.city!} ${numberFormat.format(places.length)} places',
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);
    sendPort.send(msg.toJson());
    //events
    mStart = DateTime.now().millisecondsSinceEpoch;
    var events = await _getCityEvents(
        cityId: params.city!.id!,
        minutes: (24 * 60 * params.daysAgo),
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

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning ${events.length} events via sendPort: ${params.city}\n');
    sendPort.send(msg.toJson());
    //send events message
    msg = CacheMessage(
        message: '💙${params.city!.city!} ${numberFormat.format(events.length)} events',
        statusCode: STATUS_BUSY,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning caching DONE message via sendPort: ${params.city}\n');
    sendPort.send(msg.toJson());
    //send DONE message
    elapsed = (mEnd - start) / 1000;
    msg = CacheMessage(
        message: '🍎${params.city!.city!} completed!',
        statusCode: STATUS_DONE,
        date: DateTime.now().toIso8601String(),
        elapsedSeconds: elapsed,
        type: TYPE_MESSAGE);

    p('\n${Emoji.leaf}${Emoji.leaf} CacheService: returning caching DONE message via sendPort: ${params.city}\n');
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

  Future<void> _cacheCities({required String url}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    cities = await _getCities(url);
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
  }

  Future<void> _cachePlaces(
      {required String cityId,
      required String cityName,
      required String url}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    places = await _getCityPlaces(cityId: cityId, url: url);
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
  }

  Future<void> _cacheEvents(
      {required String cityId,
      required String cityName,
      required String url, required int daysAgo}) async {
    var mStart = DateTime.now().millisecondsSinceEpoch;
    var events = await _getCityEvents(
        cityId: cityId,
        minutes: (24 * 60 * daysAgo),   //3 days worth of events
        url: url);
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
      var elapsed = (end - start) / 1000;
      p('${Emoji.brocolli}${Emoji.brocolli} CacheService: '
          ' elapsed time for network call: $heartOrange '
          ' $elapsed seconds');

      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        cities = List<City>.from(l.map((model) => City.fromJson(model)));
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $blueDot error: $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
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
      p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      var end = DateTime.now().millisecondsSinceEpoch;
      var elapsed = (end - start) / 1000;
      p('${Emoji.brocolli}${Emoji.brocolli} CacheService: '
          ' elapsed time for network call: $heartOrange '
          ' $elapsed seconds');
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
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $blueDot error: $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
    }
    return filteredCityPlaces;
  }

  static Future<List<Event>> _getCityEvents(
      {required String cityId,
      required int minutes,
      required String url}) async {
    var client = http.Client();
    var suffix1 = 'getCityEvents?cityId=$cityId&minutes=$minutes';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var events = <Event>[];
    var start = DateTime.now().millisecondsSinceEpoch;

    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 90));
      p('${Emoji.brocolli} ${Emoji.brocolli} cacheService: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      var end = DateTime.now().millisecondsSinceEpoch;
      var elapsed = (end - start) / 1000;
      p('${Emoji.brocolli}${Emoji.brocolli} CacheService: '
          ' elapsed time for network call: $heartOrange '
          ' $elapsed seconds');
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        events = List<Event>.from(l.map((model) => Event.fromJson(model)));
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $blueDot error: $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
    }
    return events;
  }
}
