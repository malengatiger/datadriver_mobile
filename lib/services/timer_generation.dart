import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:isolate';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/ui/generation/generation_page.dart';

import '../data_models/city.dart';
import '../data_models/dashboard_data.dart';
import '../data_models/generation_message.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

const FINISHED = 200, PROCESSED_CITY = 201, error = 500, TICK_RESULT = 202,
    DASHBOARD_ADDED = 203, AGGREGATES_ADDED = 204;

class TimerMessage {
  late String date, message;
  late int statusCode, events;
  String? cityName;
  List<GenerationMessage>? generationMessages = <GenerationMessage>[];
  List<CityAggregate>? aggregates = <CityAggregate>[];
  DashboardData? dashboardData;
  TimerMessage(
      {required this.date,
      required this.message,
      required this.statusCode,
      this.cityName,
      this.generationMessages,
        this.aggregates, this.dashboardData,
      required this.events});

  TimerMessage.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    message = json['message'];
    statusCode = json['statusCode'];
    cityName = json['cityName'];
    events = json['events'];
    cityName = json['cityName'];
    generationMessages = [];
    if (json['generationMessages'] != null) {
      List messages = json['generationMessages'];
      for (var value in messages) {
        generationMessages!.add(GenerationMessage.fromJson(value));
      }
    }
    aggregates = [];
    if (json['aggregates'] != null) {
      List messages = json['aggregates'];
      for (var value in messages) {
        aggregates!.add(CityAggregate.fromJson(value));
      }
    }
    if (json['dashboardData'] != null) {
      dashboardData = DashboardData.fromJson(json['dashboardData']);
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    var m = <dynamic>[];
    if (generationMessages != null) {
      for (var element in generationMessages!) {
        m.add(element.toJson());
      }
    }
    var mx = <dynamic>[];
    if (aggregates != null) {
      for (var element in aggregates!) {
        mx.add(element.toJson());
      }
    }

    map['date'] = date;
    map['message'] = message;
    map['statusCode'] = statusCode;
    map['cityName'] = cityName;
    map['events'] = events;
    map['generationMessages'] = m;
    map['aggregates'] = mx;
    map['dashboardData'] = dashboardData == null? null: dashboardData!.toJson();

    return map;
  }
}

class TimerGeneration {
  late Timer _timer;
  var _cities = <City>[];
  var random = Random(DateTime.now().millisecondsSinceEpoch);

  static Future<List<City>> getCities(String url) async {
    var client = http.Client();
    var suffix1 = 'getCities';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var cities = <City>[];
    // try {
    p("$heartOrange HTTP Url: $fullUrl");
    var response = await client
        .get(Uri.parse(fullUrl))
        .timeout(const Duration(seconds: 90));
    p('${Emoji.brocolli} ${Emoji.brocolli} TimerGeneration: We have a response from the DataDriver API! $heartOrange '
        'statusCode: ${response.statusCode}');

    if (response.statusCode == 200) {
      Iterable mIterable = json.decode(response.body);
      // mIterable.map((e) => p(e));
      cities = List<City>.from(mIterable.map((model) => City.fromJson(model)));
    } else {
      _handleStatus(response);
    }
    // } catch (e) {
    //   p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Things got a little fucked up! $blueDot error: $e');
    //   throw Exception('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Network screwed up! $e');
    // }
    return cities;
  }

  var mCount = 0;
  var messages = <GenerationMessage>[];
  int start = 0;

  Future<List<GenerationMessage>> startEventsByRandomCities(
      {required GenerationParameters params}) async {
    sendPort = params.sendPort!;
    p('\n\nGenerator: ${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}, ... startEventsByRandomCities ...');
    mCount = 0;
    messages.clear();
    start = DateTime.now().millisecondsSinceEpoch;
    //start timer
    _runTheTimer(params);
    //run the first call
    p('${Emoji.diamond}${Emoji.diamond} Generator: running call without timer delay ...');
    var list = await _generateEventsByRandomCities(params: params);
    var events = 0;
    for (var value in list!) {
      events += value.count!;
    }
    p('${Emoji.diamond}${Emoji.diamond} Generator: sending initial results, list of ${list.length}');
    var msg = TimerMessage(date: DateTime.now().toIso8601String(),
        message: "Timer tick: 0 ", statusCode: TICK_RESULT, events: events, generationMessages: list);
    sendPort.send(msg.toJson());

    messages.addAll(list);
    p('${Emoji.diamond}${Emoji.diamond} Generator: starting the Timer: params.intervalInSeconds: ${params.intervalInSeconds} ...');


    return messages;
  }

  Future<void> _runTheTimer(GenerationParameters params,) async {
    p('${Emoji.diamond}${Emoji.diamond} Generator: starting the timer ...');

    _timer = Timer.periodic(Duration(seconds: params.intervalInSeconds),
        (timer) async {
      p('${Emoji.diamond}${Emoji.diamond} Generator: Timer tick: ${timer.tick} of ${params.maxTimerTicks} maxTimerTicks ${Emoji.diamond} , ... calling _generateEventsByRandomCities ...');

      if (timer.tick > params.maxTimerTicks) {
        p('${Emoji.diamond}${Emoji.diamond} Generator: Timer tick maximum ${params.maxTimerTicks} has been reached:: ${timer.tick} ${Emoji.diamond} , ... stopping work!');

        var end = DateTime.now().millisecondsSinceEpoch;
        var minutes = (end-start)/1000/60;

        await _processEndOfGeneration(minutesAgo: (minutes + 2.0).toInt(), url: params.url);

        var message = TimerMessage(
            date: DateTime.now().toIso8601String(),
            message:
            '${Emoji.redDot} Generator stopped; ${messages.length} city runs',
            statusCode: FINISHED,
            events: mCount,
            generationMessages: messages);

        sendPort.send(message.toJson());
        _timer.cancel();

      } else {
        var list = await _generateEventsByRandomCities(params: params);
        messages.addAll(list!);
        //send the list?
        var events = 0;
        for (var value in list) {
          events += value.count!;
        }

        p('${Emoji.diamond}${Emoji.diamond} Generator: Sending Timer tick result over sendPort; '
            'tick: ${timer.tick} ${Emoji.diamond} , ... continuing work!');

        var msg = TimerMessage(date: DateTime.now().toIso8601String(),
            message: "Timer tick: ${timer.tick}", statusCode: TICK_RESULT, events: events, generationMessages: list);
        sendPort.send(msg.toJson());
      }
    });
  }

  Future _processEndOfGeneration({required int minutesAgo, required String url}) async {
    p('${Emoji.heartOrange}${Emoji.heartOrange} _processEndOfGeneration starting ...');
    var dash = await addDashboard(minutesAgo: minutesAgo, url: url);
    var message = TimerMessage(
        date: DateTime.now().toIso8601String(),
        message:
        '${Emoji.redDot} Dashboard added',
        statusCode: DASHBOARD_ADDED,
        dashboardData: dash,
        events: mCount,
        aggregates: [],
        generationMessages: []);

    p('${Emoji.heartOrange}${Emoji.heartOrange} Sending dashboard data via sendPort ..');
    sendPort.send(message.toJson());

    var aggregates = await createAggregatesForAllCities(minutesAgo: minutesAgo, url: url);
    var message2 = TimerMessage(
        date: DateTime.now().toIso8601String(),
        message:
        '${Emoji.redDot} Aggregates added',
        statusCode: AGGREGATES_ADDED,
        aggregates: aggregates,
        generationMessages: [], events: 0);

    p('${Emoji.heartOrange}${Emoji.heartOrange} Sending aggregates data via sendPort ..');
    sendPort.send(message2.toJson());
  }

  Future<List<GenerationMessage>?> _generateEventsByRandomCities(
      {required GenerationParameters params}) async {
    if (_cities.isEmpty) {
      _cities = await getCities(params.url);
    }
    var max = _cities.length / 2;
    int numberOfCities = random.nextInt(max.toInt());
    if (numberOfCities < 10) numberOfCities = 10;

    List<City> selectedCities = _getSelectedCities(numberOfCities);
    var buf = StringBuffer();
    var cnt = 0;
    for (var value in selectedCities) {
      buf.write(value.id);
      if (cnt < selectedCities.length - 1) {
        buf.write(',');
      }
      cnt++;
    }
    var cityIds = buf.toString();

    var client = http.Client();
    var suffix1 = 'generateEventsByCities?cityIds=$cityIds';
    var suffix2 = '&upperCount=${params.upperCount}';
    var fullUrl = '${params.url}$suffix1$suffix2';

    var internalMessages = <GenerationMessage>[];
    try {
      http.Response response = await _executeCall(fullUrl, client);
      if (response.statusCode == 200) {
        var body = response.body;
        List mJson = jsonDecode(body);
        for (var json in mJson) {
          internalMessages.add(GenerationMessage.fromJson(json));
        }
        _printMessages(internalMessages);
        return internalMessages;
      } else {
        _handleStatus(response);
      }
    } catch (e) {
      _handleError(e);
    }
    return null;
  }

  List<City> _getSelectedCities(int numberOfCities) {
    var selectedCities = <City>[];
    for (var i = 0; i < numberOfCities; i++) {
      var index = random.nextInt(_cities.length - 1);
      City city = _cities.elementAt(index);
      selectedCities.add(city);
    }

    for (var city in _cities) {
      if (city.city!.contains('Cape Town')) {
        selectedCities.add(city);
      }
      if (city.city!.contains('Sandton')) {
        selectedCities.add(city);
      }
      if (city.city!.contains('Durban')) {
        selectedCities.add(city);
      }
      if (city.city!.contains('Hermanus')) {
        selectedCities.add(city);
      }
      if (city.city!.contains('George')) {
        selectedCities.add(city);
      }
      if (city.city!.contains('Klerksdorp')) {
        selectedCities.add(city);
      }
    }
    // for (var city in selectedCities) {
    //   p('🥬 Selected City: ${city.city}');
    // }
    p('🥬🥬🥬 Total Selected Cities: ${selectedCities.length}');
    return selectedCities;
  }

  void _printMessages(List<GenerationMessage> list) {
    // for (var value in list) {
    //   p('🔵GenerationMessage: ${value.toJson()}');
    // }
  }

  Future<GenerationMessage?> generateEventsByCity(
      {required String cityId, required int count, required String url}) async {
    var client = http.Client();
    var suffix1 = 'generateEventsByCity?cityId=$cityId';
    var suffix2 = '&count=$count';
    var fullUrl = '$url$suffix1$suffix2';

    try {
      http.Response response = await _executeCall(fullUrl, client);
      if (response.statusCode == 200) {
        var body = response.body;
        var msg = GenerationMessage.fromJson(jsonDecode(body));
        return msg;
      } else {
        _handleStatus(response);
      }
    } catch (e) {
      _handleError(e);
    }
    return null;
  }

  Future<DashboardData?> addDashboard(
      {required int minutesAgo, required String url}) async {
    var client = http.Client();
    var suffix1 = 'addDashboardData?minutesAgo=$minutesAgo';
    var fullUrl = '$url$suffix1';

    try {
      http.Response response = await _executeCall(fullUrl, client);
      if (response.statusCode == 200) {
        var body = response.body;
        var msg = DashboardData.fromJson(jsonDecode(body));
        return msg;
      } else {
        _handleStatus(response);
      }
    } catch (e) {
      _handleError(e);
    }
    return null;
  }
  Future<List<CityAggregate>?> createAggregatesForAllCities(
      {required int minutesAgo, required String url}) async {
    var client = http.Client();
    var suffix1 = 'createAggregatesForAllCities?minutesAgo=$minutesAgo';
    var fullUrl = '$url$suffix1';

    var list = <CityAggregate>[];
    try {
      http.Response response = await _executeCall(fullUrl, client);
      if (response.statusCode == 200) {
        var body = response.body;
        List mList = jsonDecode(body);
        for (var mJson in mList) {
          var msg = CityAggregate.fromJson(mJson);
          list.add(msg);

        }
        return list;
      } else {
        _handleStatus(response);
      }
    } catch (e) {
      _handleError(e);
    }
    return null;
  }

  static void _handleStatus(http.Response response) {
    p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
    throw Exception(
        '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
  }

  void _handleError(Object e) {
    p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Things got a little fucked up! $blueDot error: $e');
    throw Exception(
        '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Network screwed up! $e');
  }

  Future<http.Response> _executeCall(String fullUrl, http.Client client) async {
    p("$heartOrange HTTP Url: $fullUrl");
    var start = DateTime.now().millisecondsSinceEpoch;
    var response = await client
        .get(Uri.parse(fullUrl))
        .timeout(const Duration(seconds: 900));
    p('${Emoji.brocolli} ${Emoji.brocolli} TimerGeneration: We have a response from the DataDriver API! $heartOrange '
        'statusCode: ${response.statusCode}');
    var end = DateTime.now().millisecondsSinceEpoch;
    var elapsed = (end - start) / 1000;
    p('${Emoji.brocolli} ${Emoji.brocolli} Elapsed time: ${elapsed.toStringAsFixed(1)} seconds for network call');
    return response;
  }

  late SendPort sendPort;

  void stop() {
    _timer.cancel();
    var msg = TimerMessage(
        date: DateTime.now().toIso8601String(),
        message: 'Generator timer cancelled',
        statusCode: FINISHED,
        cityName: '',
        events: 0);

    p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} TimerGeneration: Timer cancelled, generation stopped');
  }
}
