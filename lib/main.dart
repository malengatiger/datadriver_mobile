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
import 'package:universal_frontend/services/timer_generation.dart';
import 'package:universal_frontend/ui/dashboard/dashboard_main.dart';
import 'package:universal_frontend/ui/generation/generation_page.dart';
import 'package:universal_frontend/utils/emojis.dart';
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
Future<void> createIsolate() async {
  p('creating isolate ${Emoji.blueDot}');
  var status = dotenv.env['CURRENT_STATUS'];
  late String url = '';
  if (status == 'dev') {
    url = dotenv.env['DEV_URL']!;
  } else {
    url = dotenv.env['PROD_URL']!;
  }
  p('${Emoji.heartOrange} url is: $url');
  var rp = ReceivePort();
  var params = GenerationParameters(
      url: url,
      intervalInSeconds: 10,
      upperCount: 200,
      sendPort: rp.sendPort,
      maxTimerTicks: 10);

  var isolate = await Isolate.spawn<GenerationParameters>(
      heavyTask, params,);
  p('${Emoji.pear}${Emoji.pear}${Emoji.pear} isolate debug name is ${isolate.debugName}');
  // isolate.addErrorListener(rp.sendPort);
  // isolate.resume(isolate.pauseCapability!);
  // isolate.addOnExitListener(rp.sendPort);
  rp.listen((message) {
    if (message != null) {
      p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}'
          ' msg from isolate: $message');
      var m = message as Map<String, dynamic>;
      if (m['statusCode'] == FINISHED) {
        p('${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}${Emoji.diamond}'
            ' isolate is done! finis!');
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
  firebaseApp = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  createIsolate();
  DataService.listenForAuth();
  if (kIsWeb) {
    p('💙💙💙💙💙 We are running on the web!');
  }
  // wrap the entire app with a ProviderScope so that widgets
  // will be able to read providers
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
    return MaterialApp(
      title: 'DataDriver+',
      debugShowCheckedModeBanner: false,
      theme: FlexThemeData.light(scheme: FlexScheme.mallardGreen),
      // The Mandy red, dark theme.
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.mallardGreen),
      // Use dark or light theme based on system setting.
      themeMode: ThemeMode.system,
      // home: const AggregatePage(),
      home: const DashboardMain(),
    );
  }
}
