import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/home/widgets/about.dart';

import '../data_models/event.dart';
import '../services/data_service.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

class HomeMobile extends StatefulWidget {
  const HomeMobile({Key? key}) : super(key: key);

  @override
  State<HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends State<HomeMobile> {
  var events = <Event>[];
  void getEvents() async {
    events = await DataService.getEvents(minutes: 10);
    p('${events.length} events (10 minutes) found from Firestore $redDot');
  }

  Widget getBody() {
    return Container(
      color: Colors.blue,
      child: Center(
        child: ElevatedButton(
            onPressed: () {
              getEvents();
            },
            child: const Text('Get Events')),
      ),
    );
  }

  navigateToAbout() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: const About()));
  }

  @override
  Widget build(BuildContext context) {
    p('Building Mobile  view ... $heartGreen');

    return Scaffold(
      appBar: AppBar(
        title: Text('DataDriver Mobile ${DateTime.now().toIso8601String()}'),
        actions: [
          IconButton(onPressed: navigateToAbout, icon: const Icon(Icons.info)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Stack(
        children: [
          getBody(),
        ],
      ),
    );
  }
}
