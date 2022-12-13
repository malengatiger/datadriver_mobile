import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_frontend/data_models/aggregate_bag.dart';
import 'package:universal_frontend/data_models/city.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/data_models/event.dart';
import 'package:universal_frontend/data_models/event_bag.dart';
import 'package:universal_frontend/data_models/geometry.dart';
import 'package:universal_frontend/data_models/location.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/util.dart';

import '../data_models/city_place.dart';

const stillWorking = 201, doneCaching = 200;
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

  late final BoxCollection _boxCollection;
  late CollectionBox<AggregateBag> _aggregateBox;
  late CollectionBox<DashboardData> _dashboardDataBox;
  late CollectionBox<Event> _eventBox;
  late CollectionBox<City> _cityBox;
  late CollectionBox<CityPlace> _cityPlaceBox;
  bool _isInitialized = false;

  _init() async {
    if (!_isInitialized) {
      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Creating a Hive box collection');
      var appDir = await getApplicationDocumentsDirectory();
      File file = File('${appDir.path}/db.file');

      _boxCollection = await BoxCollection.open(
        'MyGreatBox', // Name of your database
        {'events', 'aggregateBags', 'dashboardData', 'cities', 'cityPlaces'}, // Names of your boxes
        path: file
            .path, // Path where to store your boxes (Only used in Flutter / Dart IO)
      );

      Hive.registerAdapter(DashboardDataAdapter());
      Hive.registerAdapter(AggregateBagAdapter());
      Hive.registerAdapter(CityAggregateAdapter());
      Hive.registerAdapter(EventBagAdapter());
      Hive.registerAdapter(EventAdapter());
      Hive.registerAdapter(CityAdapter());
      Hive.registerAdapter(CityPlaceAdapter());
      Hive.registerAdapter(GeometryAdapter());
      Hive.registerAdapter(LocationAdapter());

      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive box collection created');

      // Open your boxes. Optional: Give it a type.
      _aggregateBox =
          await _boxCollection.openBox<AggregateBag>('aggregateBags');
      _dashboardDataBox =
          await _boxCollection.openBox<DashboardData>('dashboardData');
      _eventBox = await _boxCollection.openBox<Event>('events');
      _cityBox = await _boxCollection.openBox<City>('cities');
      _cityPlaceBox = await _boxCollection.openBox<CityPlace>('cityPlaces');

      _isInitialized = true;
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
    await _dashboardDataBox.put(key, data);
    p('${Emoji.peach}${Emoji.peach} DashboardData has been cached in Hive');
  }

  Future<DashboardData?> getLastDashboardData() async {
    await _init();
    var keys = await _dashboardDataBox.getAllKeys();
    p('${Emoji.peach}${Emoji.peach}${Emoji.peach} hive dash keys: ${keys.length}');
    keys.sort((a, b) => b.compareTo(a)); //sor
    if (keys.isNotEmpty) {
      // t descending
      var data = await _dashboardDataBox.get(keys[0]);
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
    await _aggregateBox.put(key, bag);
    p('${Emoji.peach}${Emoji.peach} CityAggregates have been cached in Hive');
  }

  Future<void> addCities({required List<City> cities}) async {
    await _init();
    p('\n${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach} '
        'HiveUtil: adding ${cities.length} cities to Hive');

    for (var city in cities) {
      await _cityBox.put(city.id!, city);
      p('\n${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
          ' HiveUtil: City ${city.city} has been cached in Hive\n');
    }


  }

  Future<List<CityAggregate>?> getLastAggregates() async {
    await _init();
    var keys = await _aggregateBox.getAllKeys();
    keys.sort((a, b) => b.compareTo(a));
    var list = <CityAggregate>[];
    if (keys.isNotEmpty) {
      var bag = await _aggregateBox.get(keys[0]);
      if (bag != null) {
        for (var value in bag.list) {
          list.add(value);
        }
      }
      p('🔷🔷🔷🔷HiveUtil: Aggregates found in cache: ${list.length}');
      return list;
    }
    return [];
  }

  Future<List<City>> getCities() async {
    await _init();
    var keys = await _cityBox.getAllKeys();
    p('HiveUtil:  🔴🔴 getting cities from cache ....  🔴 keys: ${keys.length}');
    keys.sort((a, b) => a.compareTo(b));
    var list = <City>[];
    if (keys.isNotEmpty) {
      for (var key in keys) {
        var city = await _cityBox.get(key);
        if (city != null) {
          list.add(city);
        }
      }

      p('🔷🔷🔷🔷HiveUtil: cities found in cache: ${list.length}');
      return list;
    } else {
      p('No cities found in cache');
    }
    return [];
  }

  Future<void> addEvents({required List<Event> events}) async {
    await _init();

    for (var e in events) {
      String key = '${e.cityId}-${e.placeId}-${e.eventId}';
      await _eventBox.put(key, e);
    }

    p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
        ' HiveUtil: ${events.length} Events have been cached in Hive');
  }
  Future<void> addPlaces({required List<CityPlace> places}) async {
    await _init();

    for (var e in places) {
      String key = '${e.cityId}-${e.placeId}';
      await _cityPlaceBox.put(key, e);
    }

    p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
        ' HiveUtil:${places.length} places have been cached in Hive');
  }

}
