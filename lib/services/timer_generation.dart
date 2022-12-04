import 'dart:async';
import 'dart:math';

import '../data_models/city.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';
import 'data_service.dart';
import 'api_service.dart';

const finished = 200, processedCity = 201, error = 500 ;

class TimerMessage {
  late String date, message;
  late int statusCode, events;
  String? cityName;
  TimerMessage({required this.date, required this.message, required this.statusCode, this.cityName, required this.events});
}

class TimerGeneration {
  static late Timer timer;
  static var cities = <City>[];
  static var networkService = ApiService();
  static var dataService = DataService();
  static var random = Random(DateTime.now().millisecondsSinceEpoch);

  static StreamController<TimerMessage> streamController = StreamController.broadcast();
  static Stream<TimerMessage> get stream => streamController.stream;

  static var mCount = 0;
  static void start({required int intervalInSeconds, required int upperCount, required int max}) async {
    cities = await DataService.getCities();
    mCount = 0;
    timer = Timer.periodic(Duration(seconds: intervalInSeconds), (timer) async {
      p('$heartBlue Timer tick: ${timer.tick}');
      var count = random.nextInt(5);
      var success = 0;
      p('$heartBlue $heartBlue $heartBlue Generating events  for $appleRed: $count cities');
      for (var i = 0; i < count; i++) {
        success += (await doTheDance(upperCount))!;
      }
      mCount++;
      if (mCount > max) {
        stop();
        var msg = TimerMessage(date: DateTime.now().toIso8601String(),
            message: 'Generator stopped; max ticks reached', statusCode: finished, cityName: '', events: success);
        streamController.sink.add(msg);
      }
    });
  }

  static Future<int?> doTheDance(int upperCount) async {
    var index = random.nextInt(cities.length - 1);
    var city = cities.elementAt(index);
    var count = random.nextInt(upperCount);
    if (count < 10) count = 10;
    var result = await networkService.generateEventsByCity(cityId: city.id, count: count);
    p('$appleRed $appleRed ${result.count} events generated for $brocolli ${city.city}\n');

    var msg = TimerMessage(date: DateTime.now().toIso8601String(),
        message: 'Events generated', statusCode: processedCity, cityName: city.city, events: result.count! );
    streamController.sink.add(msg);
    return result.count;
  }

  static void stop() {
    timer.cancel();
    p('$redDot $redDot $redDot Timer cancelled, generation stopped');
    var msg = TimerMessage(date: DateTime.now().toIso8601String(),
        message: 'Generator timer cancelled', statusCode: finished, cityName: '', events: 0);
    streamController.sink.add(msg);
  }
}
