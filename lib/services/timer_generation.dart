import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:isolate';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:universal_frontend/services/cache_service.dart';
import 'package:universal_frontend/ui/generation/generation_page.dart';

import '../data_models/city.dart';
import '../data_models/generation_message.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

const FINISHED = 200, PROCESSED_CITY = 201, error = 500, TICK_RESULT = 202;

class TimerMessage {
  late String date, message;
  late int statusCode, events;
  String? cityName;
  List<GenerationMessage>? generationMessages = <GenerationMessage>[];
  TimerMessage(
      {required this.date,
      required this.message,
      required this.statusCode,
      this.cityName,
      this.generationMessages,
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
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    var m = <dynamic>[];
    for (var element in generationMessages!) {
      m.add(element.toJson());
    }

    map['date'] = date;
    map['message'] = message;
    map['statusCode'] = statusCode;
    map['cityName'] = cityName;
    map['events'] = events;
    map['generationMessages'] = m;

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
      p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
      throw Exception(
          '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
    }
    // } catch (e) {
    //   p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Things got a little fucked up! $blueDot error: $e');
    //   throw Exception('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Network screwed up! $e');
    // }
    return cities;
  }

  var mCount = 0;
  var messages = <GenerationMessage>[];

  Future<List<GenerationMessage>> startEventsByRandomCities(
      {required GenerationParameters params}) async {
    sendPort = params.sendPort!;
    p('\n\nGenerator: ${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}, ... startEventsByRandomCities ...');
    mCount = 0;
    messages.clear();
    //start timer
    _runTheTimer(params);
    //run the first call
    p('${Emoji.diamond}${Emoji.diamond} Generator: running call without timer delay ...');
    var list = await _generateEventsByRandomCities(params: params);
    var events = 0;
    for (var value in list) {
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
      p('${Emoji.diamond}${Emoji.diamond} Generator: Timer tick: ${timer.tick} ${Emoji.diamond} , ... calling _generateEventsByRandomCities ...');

      if (timer.tick > params.maxTimerTicks) {
        p('${Emoji.diamond}${Emoji.diamond} Generator: Timer tick maximum has been reached:: ${timer.tick} ${Emoji.diamond} , ... stopping work!');

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
        messages.addAll(list);
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

  Future<List<GenerationMessage>> _generateEventsByRandomCities(
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
    var m = buf.toString();
    // p('${Emoji.appleRed} cityIds string : $m');

    var client = http.Client();
    var suffix1 = 'generateEventsByCities?cityIds=$m';
    var suffix2 = '&upperCount=${params.upperCount}';
    var fullUrl = '${params.url}$suffix1$suffix2';

    var internalMessages = <GenerationMessage>[];
    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var start = DateTime.now().millisecondsSinceEpoch;
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 9000));
      p('${Emoji.brocolli} ${Emoji.brocolli} TimerGeneration: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      var end = DateTime.now().millisecondsSinceEpoch;
      var elapsed = (end - start) / 1000;
      p('${Emoji.brocolli} ${Emoji.brocolli} Elapsed time: ${elapsed.toStringAsFixed(1)} seconds for network call');
      if (response.statusCode == 200) {
        var body = response.body;
        List mJson = jsonDecode(body);
        for (var json in mJson) {
          internalMessages.add(GenerationMessage.fromJson(json));
        }
        _printMessages(internalMessages);
        return internalMessages;
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Things got a little fucked up! $blueDot error: $e');
      throw Exception(
          '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Network screwed up! $e');
    }
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

  Future<GenerationMessage> generateEventsByCity(
      {required String cityId, required int count, required String url}) async {
    var client = http.Client();
    var suffix1 = 'generateEventsByCity?cityId=$cityId';
    var suffix2 = '&count=$count';
    var fullUrl = '$url$suffix1$suffix2';

    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var start = DateTime.now().millisecondsSinceEpoch;
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 90));
      p('${Emoji.brocolli} ${Emoji.brocolli} TimerGeneration: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      var end = DateTime.now().millisecondsSinceEpoch;
      var elapsed = (end - start) / 1000;
      p('${Emoji.brocolli} ${Emoji.brocolli} Elapsed time: ${elapsed.toStringAsFixed(1)} seconds for network call');
      if (response.statusCode == 200) {
        var body = response.body;
        var msg = GenerationMessage.fromJson(jsonDecode(body));
        return msg;
      } else {
        p('${Emoji.redDot} Error Response status code: ${response.statusCode}');
        throw Exception(
            '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Things got a little fucked up! $blueDot error: $e');
      throw Exception(
          '${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot} Network screwed up! $e');
    }
  }

  late SendPort sendPort;

  Future<void> start({required GenerationParameters params}) async {
    p('$heartBlue $heartBlue $heartBlue TimerGeneration started ..... ${Emoji.redDot}');
    sendPort = params.sendPort!;

    var start = DateTime.now().millisecondsSinceEpoch;
    if (params.city != null) {
      _timer = Timer.periodic(const Duration(days: 100), (timer) {});
      var result = await generateEventsByCity(
          cityId: params.city!.id!, count: params.upperCount, url: params.url);
      p('$appleRed $appleRed ${result.count} events generated for ${Emoji.brocolli} ${params.city!.city}\n');
      stop();
      var end = DateTime.now().millisecondsSinceEpoch;
      var m = (end - start) / 1000;
      p('TimerGeneration: ${Emoji.leaf}${Emoji.leaf}${Emoji.leaf}'
          ' total time elapsed: ${m.toStringAsFixed(1)} seconds for ${params.city!.city}');
      var msg = TimerMessage(
          date: DateTime.now().toIso8601String(),
          message: 'TimerGeneration completed',
          statusCode: FINISHED,
          cityName: '',
          events: result.count!);

      try {
        sendPort.send(msg.toJson());
      } catch (e) {
        //ignore
      }
      return;
    }

    if (params.cities == null) {
      _cities = await getCities(params.url);
    } else {
      _cities = params.cities!;
    }
    mCount = 0;
    _timer = Timer.periodic(Duration(seconds: params.intervalInSeconds),
        (timer) async {
      p('$heartBlue $heartBlue Timer tick: ${timer.tick}');
      var count = random.nextInt(5);
      if (count == 0) count = 1;
      var success = 0;
      p('$heartBlue $heartBlue $heartBlue Generating events  for $appleRed: $count cities');
      for (var i = 0; i < count; i++) {
        success += (await _doTheDance(params.upperCount, params.url))!;
      }
      mCount++;
      if (mCount > params.maxTimerTicks) {
        stop();
        var end = DateTime.now().millisecondsSinceEpoch;
        var m = (end - start) / 1000;
        p('TimerGeneration: ${Emoji.leaf}${Emoji.leaf}${Emoji.leaf}'
            ' total time elapsed: ${m.toStringAsFixed(1)} seconds for whole process');
        var msg = TimerMessage(
            date: DateTime.now().toIso8601String(),
            message: 'TimerGeneration completed',
            statusCode: FINISHED,
            cityName: '',
            events: success);

        try {
          sendPort.send(msg.toJson());
        } catch (e) {
          //ignore
        }
      }
    });
  }

  Future<int?> _doTheDance(int upperCount, String url) async {
    //choose random cities

    var index = random.nextInt(_cities.length - 1);
    var city = _cities.elementAt(index);
    var count = random.nextInt(upperCount);
    if (count < 10) count = 10;
    var result =
        await generateEventsByCity(cityId: city.id!, count: count, url: url);
    p('$appleRed $appleRed ${result.count} events generated for ${Emoji.brocolli} ${city.city}\n');

    var msg = TimerMessage(
        date: DateTime.now().toIso8601String(),
        message: 'Events generated',
        statusCode: PROCESSED_CITY,
        cityName: city.city,
        events: result.count!);
    // _streamController.sink.add(msg);
    try {
      sendPort.send(msg.toJson());
    } catch (e) {
      //ignore
    }
    return result.count;
  }

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
