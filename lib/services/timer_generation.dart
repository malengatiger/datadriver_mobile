import 'dart:async';
import 'dart:math';

import '../data_models/city.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';
import 'data_service.dart';
import 'network_service.dart';

class TimerGeneration {
  late Timer timer;
  var cities = <City>[];
  var networkService = NetworkService();
  var dataService = DataService();
  var random = Random(DateTime.now().millisecondsSinceEpoch);

  void start({required int intervalInSeconds}) async {
    cities = await dataService.getCities();
    timer = Timer.periodic(Duration(seconds: intervalInSeconds), (timer) async {
      p('$heartBlue Timer tick: ${timer.tick}');
      var index = random.nextInt(cities.length - 1);
      var city = cities.elementAt(index);
      var count = random.nextInt(500);
      if (count < 100) count = 100;

      var result = await networkService.generateEventsByCity(cityId: city.id, count: count);
      p('$heartBlue ${result?.count} events generated for ${city.city}');
    });
  }

  void stop() {
    timer.cancel();
    p('$heartBlue Timer cancelled');
  }
}
