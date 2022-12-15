import 'dart:isolate';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/services/generation_monitor.dart';
import 'package:universal_frontend/services/timer_generation.dart';
import 'package:universal_frontend/ui/dashboard/dashboard_main.dart';
import 'package:universal_frontend/ui/generation/generation_page.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/hive_util.dart';
import 'package:universal_frontend/utils/util.dart';

import 'firebase_options.dart';
import 'package:get_it/get_it.dart';

late FirebaseApp firebaseApp;
final getIt = GetIt.instance;
late TimerGeneration timerGeneration;

Future<void> heavyTask(GenerationParameters model) async {
  timerGeneration = TimerGeneration();
  timerGeneration.start(params: model);
}

Future<void> _createIsolate() async {
  p('\ncreating isolate from main ${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot}');

  var status = dotenv.env['CURRENT_STATUS'];
  late String url = '';
  if (status == 'dev') {
    url = dotenv.env['DEV_URL']!;
  } else {
    url = dotenv.env['PROD_URL']!;
  }
  p('${Emoji.heartOrange} url is: $url');
  var rp = ReceivePort();
  var cities = await hiveUtil.getCities();
  var params = GenerationParameters(
      url: url,
      cities: cities,
      intervalInSeconds: 5,
      upperCount: 300,
      sendPort: rp.sendPort,
      maxTimerTicks: 10);

  var isolate = await Isolate.spawn<GenerationParameters>(
    heavyTask,
    params,
  );
  p('${Emoji.pear}${Emoji.pear}${Emoji.pear} isolate debug name is ${isolate.debugName}');
  rp.listen((message) {
    if (message != null) {
      p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}'
          ' main.dart: msg from isolate: $message');
      var m = message as Map<String, dynamic>;
      if (m['statusCode'] == FINISHED) {
        isolate.kill();
        p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}'
            ' isolate is done! finis! kaput! - isolate killed!');
        //send message on stream ....
        generationMonitor.sendStopMessage();
      }
    }
  });
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
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  p('$heartBlue Firebase App has been initialized: ${firebaseApp.name}');

  await dotenv.load(fileName: ".env");
  p('$heartBlue DotEnv has been loaded');
  setup();

  p('${Emoji.brocolli} Checking for current user : FirebaseAuth');
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    p('Ding Dong! new Firebase user, for now sign in anonymously - check that we dont create user every time $appleGreen  $appleGreen');
    await DataService.signInAnonymously();
  } else {
    p('$blueDot User already exists. $blueDot Cool!');
  }

  var list = await hiveUtil.getCities();
  p('💙💙💙💙💙 ... Cities from Hive cache: ${list.length}');

  //_createIsolate();

  DataService.listenForAuth();
  var res = await DataService.getPaginatedEvents(
      cityId: '25156118-6aaf-4d5a-9e89-2eef5d58e3c3', days: 10, limit: 100);
  p('🍏🍏🍏 paginated query result: ${res.events.length} events in the page 🍏🍏🍏');
  if (kIsWeb) {
    p('💙💙💙💙💙 We are running on the web!');
  }
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
      const ProviderScope(child: MyApp()
          // Wrap your app
          ),
    );
  }

  runApp(ProviderScope(
    child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) {
          return const MyApp();
        } // Wrap your app
        ),
  ));
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
