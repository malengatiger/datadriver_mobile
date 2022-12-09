import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_frontend/data_models/aggregate_bag.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/data_models/event.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/util.dart';

HiveUtil hiveUtil = HiveUtil._instance;

class HiveUtil {
  static final HiveUtil _instance = HiveUtil._internal();

  // using a factory is important
  // because it promises to return _an_ object of this type
  // but it doesn't promise to make a new one.
  factory HiveUtil() {
    return _instance;
  }

  // This named constructor is the "real" constructor
  // It'll be called exactly once, by the static property assignment above
  // it's also private, so it can only be called in this class
  HiveUtil._internal() {
    // initialization logic
  }

  late final BoxCollection boxCollection;
  late CollectionBox<AggregateBag> aggregateBox;
  late CollectionBox<DashboardData> dashboardDataBox;
  late CollectionBox<List<dynamic>> eventBox;
  bool isInitialized = false;

  _init() async {
    if (!isInitialized) {
      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Creating a Hive box collection');
      var appDir = await getApplicationDocumentsDirectory();
      File file = File('${appDir.path}/db.file');

      boxCollection = await BoxCollection.open(
        'MyGreatBox', // Name of your database
        {'events', 'aggregateBags', 'dashboardData'}, // Names of your boxes
        path: file
            .path, // Path where to store your boxes (Only used in Flutter / Dart IO)
      );

      Hive.registerAdapter(DashboardDataAdapter());
      Hive.registerAdapter(AggregateBagAdapter());
      Hive.registerAdapter(CityAggregateAdapter());

      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive box collection created');

      // Open your boxes. Optional: Give it a type.
      aggregateBox =
          await boxCollection.openBox<AggregateBag>('aggregateBags');
      dashboardDataBox =
          await boxCollection.openBox<DashboardData>('dashboardData');
      eventBox = await boxCollection.openBox<List<Event>>('events');

      isInitialized = true;
      p('${Emoji.peach} ${Emoji.peach} Hive has been initialized and boxes opened');
    }
  }

  String _getKey(DateTime dt) {
    var key = '${dt.millisecondsSinceEpoch}';
    return key;
  }

  Future<void> addDashboardData({required DashboardData data}) async {
    await _init();
    DateTime dt = DateTime.parse(data.date);
    String key = _getKey(dt);
    await dashboardDataBox.put(key, data);
    p('${Emoji.peach}${Emoji.peach} DashboardData has been cached in Hive');
  }

  Future<DashboardData?> getLastDashboardData() async {
    await _init();
    var keys = await dashboardDataBox.getAllKeys();
    p('${Emoji.peach}${Emoji.peach}${Emoji.peach} hive dash keys: ${keys.length}');
    keys.sort((a, b) => b.compareTo(a)); //sor
    if (keys.isNotEmpty) {
      // t descending
      var data = await dashboardDataBox.get(keys[0]);
      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Last dashboard data retrieved: ${data?.date}');
      return data;
    }
    return null;
  }

  Future<void> addAggregates({required List<CityAggregate> aggregates}) async {
    await _init();
    var bag = AggregateBag(list: aggregates, date: DateTime.now().toIso8601String());
    var date = DateTime.parse(aggregates[0].date);
    String key = _getKey(date);
    await aggregateBox.put(key, bag);
    p('${Emoji.peach}${Emoji.peach} CityAggregates have been cached in Hive');
  }

  Future<List<CityAggregate>?> getLastAggregates() async {
    await _init();
    var values = await aggregateBox.getAllValues();
    p('${Emoji.redDot} HiveUtil: ${values.length} values found: $values');
    var keys = await aggregateBox.getAllKeys();
    keys.sort((a, b) => b.compareTo(a));
    var list = <CityAggregate>[];
    if (keys.isNotEmpty) {
      var bag = await aggregateBox.get(keys[0]);
      if (bag != null) {
        // p('🔷🔷🔷🔷HiveUtil: bag found in cache: ${bag.toJson()}');
        for (var value in bag.list) {
          list.add(value);
        }
      }
      p('🔷🔷🔷🔷HiveUtil: Aggregates found in cache: ${list.length}');
      return list;
    }
    return [];
  }

  // Future<void> addEvents({required List<Event> events}) async {
  //   await _init();
  //   var date = DateTime.parse(events[0].date);
  //   String key = _getKey(date);
  //   await eventBox.put(key, events);
  //   p('${Emoji.peach}${Emoji.peach} ${events.length} Events have been cached in Hive');
  // }
  //
  // Future<List<Event>?> getLastEvents() async {
  //   await _init();
  //   var keys = await eventBox.getAllKeys();
  //   var list = <Event>[];
  //   if (keys.isNotEmpty) {
  //     // t descending
  //     var data = await aggregateBox.get(keys[0]);
  //     if (data != null) {
  //       p('🔷🔷🔷🔷dynamics found in cache: ${data.length}');
  //       for (var value in data) {
  //         var mJson = value as Map<String, dynamic>;
  //         p(mJson);
  //         var m = Event.fromJson(mJson);
  //         list.add(m);
  //       }
  //     }
  //   }
  //   p('🔷🔷🔷🔷events found in cache: ${list.length}');
  //   return list;
  // }
}
