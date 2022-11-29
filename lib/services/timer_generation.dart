import 'dart:async';
import 'dart:math';

import '../data_models/city.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';
import 'data_service.dart';
import 'network_service.dart';

class TimerGeneration {
  static late Timer timer;
  static var cities = <City>[];
  static var networkService = ApiService();
  static var dataService = DataService();
  static var random = Random(DateTime.now().millisecondsSinceEpoch);

  static var mCount = 0;
  static void start({required int intervalInSeconds, required int upperCount, required int max}) async {
    cities = await dataService.getCities();
    mCount = 0;
    timer = Timer.periodic(Duration(seconds: intervalInSeconds), (timer) async {
      p('$heartBlue Timer tick: ${timer.tick}');
      var count = random.nextInt(5);
      p('$heartBlue $heartBlue $heartBlue Generating events  for $appleRed: $count cities');
      for (var i = 0; i < count; i++) {
        await doTheDance(upperCount);
      }
      mCount++;
      if (mCount > max) {
        stop();
      }
    });
  }

  static Future<void> doTheDance(int upperCount) async {
    var index = random.nextInt(cities.length - 1);
    var city = cities.elementAt(index);
    var count = random.nextInt(upperCount);
    if (count < 10) count = 10;
    var result = await networkService.generateEventsByCity(cityId: city.id, count: count);
    p('$appleRed $appleRed ${result.count} events generated for $brocolli ${city.city}\n');
  }

  static void stop() {
    timer.cancel();
    p('$redDot $redDot $redDot Timer cancelled, generation stopped');
  }
}
