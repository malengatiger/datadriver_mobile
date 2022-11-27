import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/util.dart';
import 'package:universal_frontend/widgets/events_list.dart';

import 'firebase_options.dart';

late FirebaseApp firebaseApp;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  p('$heartBlue Firebase App has been initialized: ${firebaseApp.name}');

  DataService.listenForAuth();

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  const EventsList(showHeader: true),
    );
  }
}
