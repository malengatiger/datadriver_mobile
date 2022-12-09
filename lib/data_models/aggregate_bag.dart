
import 'package:hive/hive.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
part 'aggregate_bag.g.dart';

@HiveType(typeId: 3)
class AggregateBag {
  @HiveField(0)
  late List<CityAggregate> list;
  @HiveField(1)
  late String date;
  

  AggregateBag(
      {required this.list,
      required this.date,
      });

  AggregateBag.fromJson(Map<String, dynamic> json) {

    date = json['date'];
    list = [];

    if (json['list'] != null) {
      List m = json['list'];
      for (var value in m) {
        list.add(CityAggregate.fromJson(value));
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
