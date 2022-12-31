import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/services/timer_generation.dart';
import 'package:universal_frontend/ui/dashboard/dashboard_main.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/shared_prefs.dart';
import 'package:universal_frontend/utils/util.dart';

import 'firebase_options.dart';
import 'package:get_it/get_it.dart';

late FirebaseApp firebaseApp;
final getIt = GetIt.instance;
late TimerGeneration timerGeneration;

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

  // await SharedPrefs.deleteConfig();

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
  //hiveUtil.fixRatings();
  // CacheService.getEventZipFile(minutesAgo: 120, url: "http://192.168.86.230:8080/");
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
