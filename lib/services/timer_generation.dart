import 'dart:async';
import 'dart:math';

import '../data_models/city.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';
import 'data_service.dart';
import 'api_service.dart';

const FINISHED = 200, PROCESSED_CITY = 201, error = 500 ;

class TimerMessage {
  late String date, message;
  late int statusCode, events;
  String? cityName;
  TimerMessage({required this.date, required this.message, required this.statusCode, this.cityName, required this.events});
}
TimerGeneration timerGeneration = TimerGeneration();
class TimerGeneration {
  late Timer _timer;
  var _cities = <City>[];
  final _networkService = ApiService();
  var random = Random(DateTime.now().millisecondsSinceEpoch);

  final StreamController<TimerMessage> _streamController = StreamController.broadcast();
  Stream<TimerMessage> get stream => _streamController.stream;

  var mCount = 0;
  void start({required int intervalInSeconds,
    required int upperCount,
    required int max}) async {
    _cities = await DataService.getCities();
    mCount = 0;
    _timer = Timer.periodic(Duration(seconds: intervalInSeconds), (timer) async {
      p('$heartBlue Timer tick: ${timer.tick}');
      var count = random.nextInt(5);
      var success = 0;
      p('$heartBlue $heartBlue $heartBlue Generating events  for $appleRed: $count cities');
      for (var i = 0; i < count; i++) {
        success += (await _doTheDance(upperCount))!;
      }
      mCount++;
      if (mCount > max) {
        stop();
      }
    });
  }

  Future<int?> _doTheDance(int upperCount) async {
    var index = random.nextInt(_cities.length - 1);
    var city = _cities.elementAt(index);
    var count = random.nextInt(upperCount);
    if (count < 10) count = 10;
    var result = await _networkService.generateEventsByCity(cityId: city.id, count: count);
    p('$appleRed $appleRed ${result.count} events generated for $brocolli ${city.city}\n');

    var msg = TimerMessage(date: DateTime.now().toIso8601String(),
        message: 'Events generated', statusCode: PROCESSED_CITY, cityName: city.city, events: result.count! );
    _streamController.sink.add(msg);
    return result.count;
  }

  void stop() {
    _timer.cancel();
    var msg = TimerMessage(date: DateTime.now().toIso8601String(),
        message: 'Generator timer cancelled', statusCode: FINISHED, cityName: '', events: 0);
    _streamController.sink.add(msg);
    p('$redDot $redDot $redDot TimerGeneration: Timer cancelled, generation stopped');

  }
}
