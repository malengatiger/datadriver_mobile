import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:universal_frontend/services/cache_service.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/services/generation_monitor.dart';
import 'package:universal_frontend/services/timer_generation.dart';
import 'package:universal_frontend/ui/dashboard/dashboard_main.dart';
import 'package:universal_frontend/ui/generation/generation_page.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/hive_util.dart';
import 'package:universal_frontend/utils/shared_prefs.dart';
import 'package:universal_frontend/utils/util.dart';

import 'data_models/cache_bag.dart';
import 'data_models/cache_config.dart';
import 'data_models/city.dart';
import 'data_models/city_aggregate.dart';
import 'data_models/city_place.dart';
import 'data_models/dashboard_data.dart';
import 'data_models/event.dart';
import 'firebase_options.dart';
import 'package:get_it/get_it.dart';

late FirebaseApp firebaseApp;
final getIt = GetIt.instance;
late TimerGeneration timerGeneration;


late ReceivePort _receivePort;
late Isolate _isolate;
String? _getUrlPrefix() {
  var status = dotenv.env['CURRENT_STATUS'];
  if (status == 'dev') {
    return dotenv.env['DEV_URL'];
  }
  if (status == 'prod') {
    return dotenv.env['PROD_URL'];
  }
  return null;
}
Future<void> _heavyTask(CacheParameters cacheParams) async {
  p('\n\n${Emoji.redDot}${Emoji.redDot}${Emoji.redDot} '
      'Heavy isolate cache task starting ...........');
  cacheService.startCaching(params: cacheParams);
}

Future<void> _createIsolate({required int daysAgo}) async {
  try {
    p('💙💙💙💙💙💙 _createIsolate starting ...............');
    _cities = await DataService.getCities();
    _receivePort = ReceivePort();
    var errorReceivePort = ReceivePort();
    //pass sendPort to the params so isolate can send messages
    // params.sendPort = receivePort.sendPort;
    IsolateChannel channel =
    IsolateChannel(_receivePort, _receivePort.sendPort);
    channel.stream.listen((data) async {
      if (data != null) {
        p('${Emoji.heartBlue}${Emoji.heartBlue} '
            'main: Received cacheService result ${Emoji.appleRed} CacheMessage, '
            'statusCode: ${data['statusCode']} type: ${data['type']} msg: ${data['message']}');
        try {
          var msg = CacheMessage.fromJson(data);
          switch (msg.type) {
            case typeMessage:
              if (msg.statusCode == statusDone) {
                p('\n${Emoji.redDot}${Emoji.redDot} '
                    'main: received end message from CacheService, will remove loading ui '
                    '${Emoji.heartBlue}${Emoji.heartBlue}');
                _isolate.kill(priority: Isolate.immediate);
                p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond} isolate killed!!');
                //add cacheConfig
                await SharedPrefs.saveConfig(CacheConfig(
                  longDate: DateTime.now().millisecondsSinceEpoch,
                  stringDate: DateTime.now().toIso8601String(),
                  elapsedSeconds: msg.elapsedSeconds!,));
              } else {
                if (msg.statusCode == statusError) {
                  _isolate.kill(priority: Isolate.immediate);
                  p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond} isolate killed');
                  p("We have an error. Do something! ..... please!");
                } else {
                  msg.message = '${Emoji.appleRed} ${msg.message}';
                }
              }
              break;
            case typeCity:
              _saveCities(msg);
              break;
            case typePlace:
              _savePlaces(msg);
              break;
            case typeEvent:
              _saveEvents(msg);
              break;
            case typeDashboard:
              _saveDashboards(msg);
              break;
            case typeAggregate:
              _saveAggregates(msg);
              break;
            case typeCacheBag:
              _saveCacheBag(msg);
              break;
            default:
              p('${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}'
                  'main: ........... type not available! wtf? ${Emoji.redDot}');
              break;
          }

        } catch (e) {
          p(e);
        }
      }
    });

    String? url = _getUrlPrefix();
    if (url == null) {
      throw Exception("CacheManager: Crucial Url parameter missing! 🔴🔴");
    }
    var config = await SharedPrefs.getConfig();
    if (config == null) {
      var longDate = DateTime.now().subtract(const Duration(days:2)).millisecondsSinceEpoch;
      var stringDate = DateTime.now().subtract(const Duration(days:2)).toIso8601String();
      config = CacheConfig(longDate: longDate, stringDate: stringDate, elapsedSeconds: 0);
      await SharedPrefs.saveConfig(config);
    }

    var min = await SharedPrefs.getMinutesAgo();
    var params = CacheParameters(
      sendPort: _receivePort.sendPort,
      minutesAgo: min,
      url: url,
       useCacheService: true,);

    _isolate = await Isolate.spawn<CacheParameters>(_heavyTask, params,
        paused: true,
        onError: errorReceivePort.sendPort,
        onExit: _receivePort.sendPort);

    _isolate.addErrorListener(errorReceivePort.sendPort);
    _isolate.resume(_isolate.pauseCapability!);
    _isolate.addOnExitListener(_receivePort.sendPort);

    errorReceivePort.listen((e) {
      p('${Emoji.redDot}${Emoji.redDot} exception occurred: $e');

    });
  } catch (e) {
    p('${Emoji.redDot} we have a problem: $e ${Emoji.redDot} ${Emoji.redDot}');
    if (e.toString().contains('FormatException')) {
      await SharedPrefs.deleteConfig();
    }
  }
}

var _cities = <City>[];

void _saveCities(CacheMessage msg) async {
  _cities.clear();
  String mJson = msg.cities!;
  List m = jsonDecode(mJson);
  for (var value in m) {
    var k = City.fromJson(value);
    _cities.add(k);
  }

  await hiveUtil.addCities(cities: _cities);
  p('\nmain: ${Emoji.appleRed}${Emoji.appleRed}${Emoji.appleRed}'
      ' ${_cities.length} cities cached in Hive');
}

void _savePlaces(CacheMessage msg) async {
  var places = <CityPlace>[];
  String mJson = msg.places!;
  List m = jsonDecode(mJson);
  for (var value in m) {
    var k = CityPlace.fromJson(value);
    places.add(k);
  }
  await hiveUtil.addPlaces(places: places);
}

void _saveEvents(CacheMessage msg) async {
  var start = DateTime.now().millisecondsSinceEpoch;
  var events = <Event>[];
  String mJson = msg.events!;
  List m = jsonDecode(mJson);
  for (var value in m) {
    var k = Event.fromJson(value);
    events.add(k);
  }
  await hiveUtil.addEvents(events: events);

  var end = DateTime.now().millisecondsSinceEpoch;
  var ms = (end -start)/1000;
  var mMsg = CacheMessage(message: '${Emoji.blueDot} ${events.length} Hive events cached',
      statusCode: statusBusy, date: DateTime.now().toIso8601String(),
      elapsedSeconds: ms, type: typeMessage);

}

void _saveDashboards(CacheMessage msg) async {
  String mJson = msg.dashboards!;
  List m = jsonDecode(mJson);
  var list = <DashboardData>[];
  for (var value in m) {
    var k = DashboardData.fromJson(value);
    list.add(k);
  }

  await hiveUtil.addDashboardDataList(dataList: list);

  p('${Emoji.diamond} main: dashboards added to Hive: ${m.length}');

}

void _saveAggregates(CacheMessage msg) async {
  String mJson = msg.aggregates!;
  List m = jsonDecode(mJson);
  var aggregates = <CityAggregate>[];
  for (var value in m) {
    var k = CityAggregate.fromJson(value);
    aggregates.add(k);
  }
  await hiveUtil.addAggregates(aggregates: aggregates);
}

void _saveCacheBag(CacheMessage msg) async {
  p('\n\n${Emoji.appleGreen}${Emoji.appleGreen} CacheManager: save data in Hive ... '
      '- ${DateTime.now().toIso8601String()}');
  var start = DateTime.now().millisecondsSinceEpoch;

  Map<String,dynamic> cache = msg.cacheBagJson!;
  var cacheBag = CacheBag.fromJson(cache);
  await hiveUtil.addCities(cities: cacheBag.cities);
  p('${Emoji.diamond} CacheManager: cities added to Hive: ${cacheBag.cities.length}');
  await hiveUtil.addPlaces(places: cacheBag.places);
  p('${Emoji.diamond} CacheManager: places added to Hive: ${cacheBag.places.length}');

  await hiveUtil.addAggregates(aggregates: cacheBag.aggregates);
  p('${Emoji.diamond} CacheManager: aggregates added to Hive: ${cacheBag.aggregates.length}');
  await hiveUtil.addDashboardDataList(dataList: cacheBag.dashboards);
  p('${Emoji.diamond} CacheManager: dashboards added to Hive: ${cacheBag.dashboards.length}');

  // await hiveUtil.addEvents(events: cacheBag.events);
  // p('${Emoji.diamond} CacheManager: events added to Hive: ${cacheBag.events.length}');

  var end = DateTime.now().millisecondsSinceEpoch;
  var elapsed = double.parse('${(end-start)/1000}');
  p('\n\n${Emoji.appleGreen}${Emoji.appleGreen} CacheManager: big Hive cache job is complete! '
      '${Emoji.appleRed} Hive elapsed time: $elapsed seconds '
      '- ${DateTime.now().toIso8601String()}');

  var msg3 = CacheMessage(message: "💙💙Hive writes completed",
      statusCode: statusBusy, date: DateTime.now().toIso8601String(),
      elapsedSeconds: elapsed, type: typeMessage);

}

void setup() {
  // getIt.registerSingleton<TimerGeneration>(TimerGeneration());
  getIt.registerSingletonAsync<TimerGeneration>(() async {
    final timerGen = TimerGeneration();
    return timerGen;
  });
  p('${Emoji.peach} getIt registered TimerGeneration');
// Alternatively you could write it if you don't like global variables
//   GetIt.I.registerSingleton<AppModel>(AppModel());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) exit(1);
  };
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  p('$heartBlue Firebase App has been initialized: ${firebaseApp.name}');

  await dotenv.load(fileName: ".env");
  p('$heartBlue DotEnv has been loaded');

  // setup();

  p('${Emoji.brocolli} Checking for current user : FirebaseAuth');
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    p('Ding Dong! new Firebase user, for now sign in anonymously - check that we dont create user every time $appleGreen  $appleGreen');
    await DataService.signInAnonymously();
  } else {
    p('$blueDot User already exists. $blueDot Cool!');
  }

  //_createIsolate();

  DataService.listenForAuth();
  // var res = await DataService.getPaginatedEvents(
  //     cityId: '25156118-6aaf-4d5a-9e89-2eef5d58e3c3', days: 10, limit: 100);
  // p('🍏🍏🍏 paginated query result: ${res.events.length} events in the page 🍏🍏🍏');
  //
  if (kIsWeb) {
    p('💙💙💙💙💙💙 We are running on the web!');
  } else {
    p('🍊🍊🍊🍊🍊🍊 We are running on something rather than the web!');
  }
  //cache data since last time
  //_createIsolate(daysAgo: 2);
  hiveUtil.fixRatings();
  // wrap the entire app with a ProviderScope so that widgets
  // will be able to read providers
  if (kIsWeb) {
    p('💙💙💙💙💙 We are running on the web and setting up DevicePreview');
    runApp(ProviderScope(
      child: DevicePreview(
          enabled: !kReleaseMode,
          builder: (context) {
            return const MyApp();
          } // Wrap your app
          ),
    ));
  } else {
    p('💙💙💙💙💙 We are running on the mobile and no need of DevicePreview...');
    runApp(
      const ProviderScope(child: MyApp() ),
    );
  }

  // runApp(ProviderScope(
  //   child: DevicePreview(
  //       enabled: !kReleaseMode,
  //       builder: (context) {
  //         return const MyApp();
  //       } // Wrap your app
  //       ),
  // ));
  // var events = await DataService.getEvents(minutes: 30);
  // p('${events.length} events found by  DataService. $heartGreen');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        p('${Emoji.pear} Top level GestureDetector has detected a tap');
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: MaterialApp(
        title: 'DataDriver+',
        debugShowCheckedModeBanner: false,
        theme: FlexThemeData.light(scheme: FlexScheme.mallardGreen),
        // The Mandy red, dark theme.
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mallardGreen),
        // Use dark or light theme based on system setting.
        themeMode: ThemeMode.system,
        // home: const AggregatePage(),
        home: const DashboardMain(),
      ),
    );
  }
}
