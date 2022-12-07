import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:isolate';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:universal_frontend/ui/generation/generation_page.dart';

import '../data_models/city.dart';
import '../data_models/generation_message.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

const FINISHED = 200, PROCESSED_CITY = 201, error = 500;

class TimerMessage {
  late String date, message;
  late int statusCode, events;
  String? cityName;
  TimerMessage(
      {required this.date,
      required this.message,
      required this.statusCode,
      this.cityName,
      required this.events});

  TimerMessage.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    message = json['message'];
    statusCode = json['statusCode'];
    cityName = json['cityName'];
    events = json['events'];
    cityName = json['cityName'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date,
        'message': message,
        'statusCode': statusCode,
        'cityName': cityName,
        'events': events,
      };
}

class TimerGeneration {
  late Timer _timer;
  var _cities = <City>[];
  var random = Random(DateTime.now().millisecondsSinceEpoch);
  // final StreamController<TimerMessage> _streamController =
  //     StreamController.broadcast();
  // Stream<TimerMessage> get stream => _streamController.stream;

  Future<List<City>> getCities(String url) async {
    var client = http.Client();
    var suffix1 = 'getCities';
    var fullUrl = '';
    fullUrl = '$url$suffix1';
    var cities = <City>[];
    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 30));
      p('$brocolli $brocolli TimerGeneration: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');

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

  var mCount = 0;
  Future<GenerationMessage> generateEventsByCity(
      {required String cityId, required int count, required String url}) async {
    var client = http.Client();
    var suffix1 = 'generateEventsByCity?cityId=$cityId';
    var suffix2 = '&count=$count';
    var fullUrl = '$url$suffix1$suffix2';

    try {
      p("$heartOrange HTTP Url: $fullUrl");
      var response = await client
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 30));
      p('$brocolli $brocolli TimerGeneration: We have a response from the DataDriver API! $heartOrange '
          'statusCode: ${response.statusCode}');
      if (response.statusCode == 200) {
        var body = response.body;
        var msg = GenerationMessage.fromJson(jsonDecode(body));
        return msg;
      } else {
        p('$redDot Error Response status code: ${response.statusCode}');
        throw Exception(
            '$redDot $redDot $redDot Server could not handle request: ${response.body}');
      }
    } catch (e) {
      p('$redDot $redDot $redDot Things got a little fucked up! $blueDot error: $e');
      throw Exception('$redDot $redDot $redDot Network screwed up! $e');
    }
  }

  late SendPort sendPort;
  void start({required GenerationParameters params}) async {
    sendPort = params.sendPort!;
    _cities = await getCities(params.url);
    mCount = 0;
    _timer = Timer.periodic(Duration(seconds: params.intervalInSeconds),
        (timer) async {
      p('$heartBlue Timer tick: ${timer.tick}');
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
    var index = random.nextInt(_cities.length - 1);
    var city = _cities.elementAt(index);
    var count = random.nextInt(upperCount);
    if (count < 10) count = 10;
    var result =
        await generateEventsByCity(cityId: city.id, count: count, url: url);
    p('$appleRed $appleRed ${result.count} events generated for $brocolli ${city.city}\n');

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
    // _streamController.sink.add(msg);
    p('$redDot $redDot $redDot TimerGeneration: Timer cancelled, generation stopped');
  }
}
