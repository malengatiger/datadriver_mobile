
import 'package:hive/hive.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';

import 'event.dart';
part 'event_bag.g.dart';

@HiveType(typeId: 6)
class EventBag {
  @HiveField(0)
  late List<Event> list;
  @HiveField(1)
  late String date;
  

  EventBag(
      {required this.list,
      required this.date,
      });

  EventBag.fromJson(Map<String, dynamic> json) {

    date = json['date'];
    list = [];

    if (json['list'] != null) {
      List m = json['list'];
      for (var value in m) {
        list.add(Event.fromJson(value));
      }
    }

  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['date'] = date;

    var mList = <Map<String, dynamic>>[];
    for (var value in list) {
      var m = value.toJson();
      mList.add(m);
    }
    map['list'] = mList;

    return map;
  }
}
