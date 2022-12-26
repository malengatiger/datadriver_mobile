import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_frontend/data_models/cache_config.dart';
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

  factory HiveUtil() {
    return _instance;
  }

  HiveUtil._internal() {
    // initialization logic
    //_init();
  }

  BoxCollection? _boxCollection;
  CollectionBox<CityAggregate>? _aggregateBox;
  CollectionBox<DashboardData>? _dashboardDataBox;
  CollectionBox<Event>? _eventBox;
  CollectionBox<City>? _cityBox;
  CollectionBox<CityPlace>? _cityPlaceBox;
  CollectionBox<CacheConfig>? _cacheConfigBox;
  bool _isInitialized = false;

  _init() async {
    if (!_isInitialized) {
      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} ... Creating a Hive box collection');
      var appDir = await getApplicationDocumentsDirectory();
      File file = File('${appDir.path}/db1a.file');

      try {
        _boxCollection = await BoxCollection.open(
          'DataBoxOneA02', // Name of your database
          {
            'events',
            'aggregates',
            'dashboardData',
            'cities',
            'cityPlaces',
            'cacheConfigs'
          },
          // Names of your boxes
          path: file
              .path, // Path where to store your boxes (Only used in Flutter / Dart IO)
        );
      } catch (e) {
        p('🔴🔴 There is some problem with 🔴initialization 🔴');
      }

      p('Registering Hive object adapters ...');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DashboardDataAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive dashboardAdapter registered');
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CityAggregateAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive cityAggregateAdapter registered');
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(EventBagAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive eventBagAdapter registered');
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(EventAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive eventAdapter registered');
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(CityAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive cityAdapter registered');
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(CityPlaceAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive cityPlaceAdapter registered');
      }
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(GeometryAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive geometryAdapter registered');
      }
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(LocationAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive locationAdapter registered');
      }
      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(CacheConfigAdapter());
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive cacheConfigAdapter registered');
      }

      p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach} Hive box collection created and types registered');

      try {
        // Open your boxes. Optional: Give it a type.
        _aggregateBox =
            await _boxCollection!.openBox<CityAggregate>('aggregates');
        _dashboardDataBox =
            await _boxCollection!.openBox<DashboardData>('dashboardData');
        _eventBox = await _boxCollection!.openBox<Event>('events');
        _cityBox = await _boxCollection!.openBox<City>('cities');
        _cityPlaceBox = await _boxCollection!.openBox<CityPlace>('cityPlaces');
        _cacheConfigBox =
            await _boxCollection!.openBox<CacheConfig>('cacheConfigs');

        _isInitialized = true;
        p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
            ' Hive has been initialized and boxes opened');
      } catch (e) {
        p('🔴🔴 We have a problem 🔴 opening Hive boxes');
      }
    }
  }

  Future<DashboardData?> getLatestDashboardData() async {
    await _init();
    var keys = await _dashboardDataBox!.getAllKeys();
    p('${Emoji.peach}${Emoji.peach}${Emoji.peach} hive dash keys: ${keys.length}');
    keys.sort((a, b) => b.compareTo(a)); //sor
    if (keys.isNotEmpty) {
      // t descending
      var data = await _dashboardDataBox!.get(keys[0]);
      p('${Emoji.peach}${Emoji.peach}${Emoji.peach} Last dashboard data retrieved: ${data?.date}');
      return data;
    }
    return null;
  }

  Future<void> addDashboardDataList(
      {required List<DashboardData> dataList}) async {
    await _init();

    for (var element in dataList) {
      Future.delayed(const Duration(milliseconds: 20), () async {
        await _addDashboardData(data: element);
      });
    }
    p('${Emoji.pear} HiveUtil: ${dataList.length} dashboards cached');
  }

  Future<void> _addDashboardData({required DashboardData data}) async {
    await _init();
    var key = '${data.longDate}';
    await _dashboardDataBox!.put(key, data);
  }

  Future<List<DashboardData>> getDashboardDataList(
      {required DateTime date}) async {
    await _init();
    var requiredDay = date.day;
    var keys = await _dashboardDataBox!.getAllKeys();
    p('${Emoji.peach}${Emoji.peach}${Emoji.peach} hive dash keys: ${keys.length}, requiredDay: $requiredDay');
    keys.sort((a, b) => a.compareTo(b));
    var list = <DashboardData>[];
    for (var key in keys) {
      var dd = await _dashboardDataBox!.get(key);
      if (dd != null) {
        var dt = DateTime.parse(dd.date);
        var mDay = dt.day;
        if (requiredDay == mDay) {
          list.add(dd);
        }
      }
    }

    list.sort((a, b) => a.longDate.compareTo(b.longDate));
    p('HiveUtil: ${Emoji.appleGreen} found ${list.length} '
        'dashboards for this date: ${date.toIso8601String()}');
    for (var value in list) {
      p('${Emoji.appleGreen} Dashboard: ${value.date} - events: ${value.events}, avg: ${value.averageRating} ');
    }

    return list;
  }

  var random = Random(DateTime.now().millisecondsSinceEpoch);

  final averages = [3.4,4.0,4.1,4.2,3.3,4.6,2.0,3.1,4.4,4.1,2.5,3.6,4.0,4.2,2,5,2,4.2,3.2,3.3,4.2,2.3,1.6,1.8,4.6,4.1,3.4,3.2,
    2.6,3.2,3.6,3.3,2.8,2.9,4.1,3.2,3.4,4.2,2.3,2.2,3.5,4.6,4.8,2.2,2.4,3.4,3.8,3.9,4.0,4.3,5.0,4.1,2.0,2.3,1.9, 1.8,4.3];
  Future fixRatings() async {
    var dates = <DateTime>[];
    dates.add(DateTime.now().subtract(const Duration(days: 10)));
    dates.add(DateTime.now().subtract(const Duration(days: 9)));
    dates.add(DateTime.now().subtract(const Duration(days: 8)));
    dates.add(DateTime.now().subtract(const Duration(days: 7)));
    dates.add(DateTime.now().subtract(const Duration(days: 6)));
    dates.add(DateTime.now().subtract(const Duration(days: 5)));
    dates.add(DateTime.now().subtract(const Duration(days: 4)));
    dates.add(DateTime.now().subtract(const Duration(days: 3)));
    dates.add(DateTime.now().subtract(const Duration(days: 2)));
    dates.add(DateTime.now().subtract(const Duration(days: 1)));
    dates.add(DateTime.now());
    
    var start = DateTime.now().millisecondsSinceEpoch;
    await _init();
    var cnt = 0;
    p('\n\n🔵🔵🔵🔵🔵🔵 Processing dashboards for date: ${dates.length} dates');
    for (var date in dates) {
      var list = await getDashboardDataList(date: date);
      p('\n🔵🔵 Processing ${list.length} dashboards for date: ${date.toIso8601String()}');
      random = Random(DateTime.now().millisecondsSinceEpoch);
      for (var dashboard in list) {
        var index = random.nextInt(averages.length - 1);
        var avg = averages.elementAt(index);
        dashboard.averageRating = double.parse('$avg');
        var key = '${dashboard.longDate}';
        await _dashboardDataBox!.put(key, dashboard);
        p('🍊updated dashboard date: ${dashboard.date} 🍊averageRating: ${dashboard.averageRating.toStringAsFixed(2)} for ${dashboard.events} events');
        cnt++;
        //
      }
    }
    var end = DateTime.now().millisecondsSinceEpoch;
    var eMs = start - end;
    var eSecs = eMs / 1000;
    p('\n\n🍊🍊🍊Updated a total of $cnt dashboards; elapsed seconds: $eSecs');
  }

  Future<void> addAggregates({required List<CityAggregate> aggregates}) async {
    await _init();

    for (var agg in aggregates) {
      String mKey = '${agg.cityId}*${agg.longDate}';
      await _aggregateBox!.put(mKey, agg);
    }

    p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach} '
        'HiveUtil: ${aggregates.length} CityAggregates have been cached in Hive');
  }

  Future<void> addCities({required List<City> cities}) async {
    await _init();

    for (var city in cities) {
      await _cityBox!.put(city.id!, city);
    }
    p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
        ' HiveUtil: ${cities.length} cities have been cached in Hive');
  }

  Future<List<CityAggregate>?> getLatestAggregates(int minutesAgo) async {
    await _init();
    var keys = await _aggregateBox!.getAllKeys();
    p('🔷🔷🔷🔷HiveUtil: Aggregates KEYS found in cache: ${keys.length}');

    keys.sort((a, b) => b.compareTo(a));

    var list = <CityAggregate>[];
    var start = DateTime.now().millisecondsSinceEpoch;
    if (keys.isNotEmpty) {
      for (var key in keys) {
        //get longDate part of key
        var keySplits = key.split('*');
        var stringLongDate = keySplits[1];

        var keyDate =
            DateTime.fromMillisecondsSinceEpoch(int.parse(stringLongDate));
        var now = DateTime.now();
        var deltaMs =
            now.millisecondsSinceEpoch - keyDate.millisecondsSinceEpoch;
        var deltaMinutes = deltaMs / 1000 ~/ 60;
        if (deltaMinutes <= minutesAgo) {
          var agg = await _aggregateBox!.get(key);
          list.add(agg!);
        }
      }
      p('🔷🔷🔷🔷HiveUtil: Aggregates found in cache: ${list.length}');
      _filterAggregates(list);
      var end = DateTime.now().millisecondsSinceEpoch;
      p('🔷🔷🔷🔷HiveUtil: Aggregates search; elapsed milliseconds: ${(end - start)}');

      return list;
    }
    return [];
  }

  void _filterAggregates(List<CityAggregate> aggregates) {
    var hashMap = HashMap<String, CityAggregate>();
    for (var agg in aggregates) {
      if (!hashMap.containsKey(agg.cityId)) {
        hashMap[agg.cityId!] = agg;
      }
    }
    aggregates = hashMap.values.map((e) => e).toList();
    aggregates.sort((a, b) => a.cityName!.compareTo(b.cityName!));
    p('HiveUtil: ${aggregates.length} filtered aggregates ${Emoji.appleRed}${Emoji.appleRed}');
  }

  Future<List<City>> getCities() async {
    await _init();
    var keys = await _cityBox!.getAllKeys();
    p('HiveUtil:  🔴🔴 getting cities from cache ....  🔴 keys: ${keys.length}');
    keys.sort((a, b) => a.compareTo(b));
    var list = <City>[];
    if (keys.isNotEmpty) {
      for (var key in keys) {
        var city = await _cityBox!.get(key);
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

  Future<City?> getCity({required String cityId}) async {
    await _init();
    City? city = await _cityBox!.get(cityId);
    if (city != null) {
      p('HiveUtil:🔴🔴 city found in cache: 🔴 ${city.city}');
    }
    return city;
    ;
  }

  Future<void> addEvents({required List<Event> events}) async {
    await _init();

    for (var e in events) {
      String key = '${e.cityId}-${e.placeId}-${e.eventId}';
      await _eventBox!.put(key, e);
    }

    p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
        ' HiveUtil: ${events.length} Events have been cached in Hive');
  }

  Future<void> addPlaces({required List<CityPlace> places}) async {
    await _init();

    for (var e in places) {
      String key = '${e.cityId}-${e.placeId}';
      await _cityPlaceBox!.put(key, e);
    }

    p('${Emoji.peach}${Emoji.peach}${Emoji.peach}${Emoji.peach}'
        ' HiveUtil: ${places.length} places have been cached in Hive');
  }

  Future<List<CityPlace>> getCityPlaces({required String cityId}) async {
    var places = <CityPlace>[];
    var keys = await _cityPlaceBox!.getAllKeys();
    for (var key in keys) {
      if (key.contains(cityId)) {
        var m = await _cityPlaceBox!.get(key);
        if (m != null) {
          places.add(m);
        }
      }
    }

    places.sort((a, b) => a.name!.compareTo(b.name!));
    p('HiveUtil: city places found in cache: ${places.length} ${Emoji.peach}${Emoji.peach}');

    return places;
  }

  Future<List<Event>> getCityEventsAll({required String cityId}) async {
    var events = <Event>[];
    var keys = await _eventBox!.getAllKeys();
    for (var key in keys) {
      if (key.contains(cityId)) {
        var m = await _eventBox!.get(key);
        if (m != null) {
          events.add(m);
        }
      }
    }

    //sort by date descending
    events.sort((a, b) => b.longDate.compareTo(a.longDate));
    p('HiveUtil: city events found in cache: ${events.length} ${Emoji.peach}${Emoji.peach}');
    return events;
  }

  Future<List<Event>> getCityEventsMinutesAgo(
      {required String cityId, required int minutesAgo}) async {
    var events = <Event>[];
    var dt = DateTime.now()
        .subtract(Duration(minutes: minutesAgo))
        .millisecondsSinceEpoch;
    var keys = await _eventBox!.getAllKeys();
    for (var key in keys) {
      if (key.contains(cityId)) {
        var m = await _eventBox!.get(key);
        if (m!.longDate >= dt) {
          events.add(m);
        }
      }
    }
    //sort by date descending
    events.sort((a, b) => b.longDate.compareTo(a.longDate));
    p('HiveUtil: city events found in cache: ${events.length} ${Emoji.peach}${Emoji.peach}');
    return events;
  }

  Future<List<Event>> getPlaceEvents({required String placeId}) async {
    var events = <Event>[];
    var keys = await _eventBox!.getAllKeys();
    for (var key in keys) {
      if (key.contains(placeId)) {
        var m = await _eventBox!.get(key);
        if (m != null) {
          events.add(m);
        }
      }
    }

    //sort by date descending
    events.sort((a, b) => b.longDate.compareTo(a.longDate));
    p('HiveUtil: place events found in cache: ${events.length} ${Emoji.peach}${Emoji.peach}');

    return events;
  }
}
