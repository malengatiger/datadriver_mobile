import 'dart:async';

import 'package:datadriver_mobile/data_models/event.dart';
import 'package:datadriver_mobile/emojis.dart';
import 'package:datadriver_mobile/services/data_service.dart';
import 'package:datadriver_mobile/services/network_service.dart';
import 'package:datadriver_mobile/ui/generator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:datadriver_mobile/services/util.dart';

Future<void> main() async {
  p('DataDriver starting ... $appleGreen $appleGreen');
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  p("$appleRed $appleRed Firebase app initialized");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DataDriver',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const DataDriverHome(title: 'DataDriver Home Page'),
    );
  }
}

class DataDriverHome extends StatefulWidget {
  const DataDriverHome({super.key, required this.title});

  final String title;

  @override
  State<DataDriverHome> createState() => _DataDriverHomeState();
}

class _DataDriverHomeState extends State<DataDriverHome> {


  @override
  void initState() {
    super.initState();

  }

  _navigateToGenerator() async {

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const Generator()));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.amber.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                  elevation: 8,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 16,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'This DataDriver app starts a streaming data generator running in a Cloud Run instance. '
                          'This simulates events that are sent to PubSub and BigQuery and on to Looker ',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            _navigateToGenerator();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Start Generator'),
                          )),
                      const SizedBox(
                        height: 24,
                      ),

                    ],
                  )),
            )
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
