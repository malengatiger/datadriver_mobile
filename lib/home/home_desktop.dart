import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/home/widgets/about.dart';
import 'package:universal_frontend/utils/providers.dart';

import '../data_models/event.dart';
import '../services/data_service.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

class HomeDesktop extends StatefulWidget {
  const HomeDesktop({Key? key}) : super(key: key);

  @override
  State<HomeDesktop> createState() => _HomeDesktopState();
}

class _HomeDesktopState extends State<HomeDesktop> {
  var events = <Event>[];

  getEvents() async {
    events = await DataService.getEvents(minutes: minutesAgo);
    p('${events.length} events $minutesAgo minutes found from Firestore $redDot');
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
    p('Building Desktop  view ... $heartOrange');

    var body = Container(
      color: Colors.pink,
      child: Center(
        child: ElevatedButton(onPressed: getEvents, child: const Text('Get Events')),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('DataDriver Desktop ${DateTime.now().toIso8601String()}'),
        actions: [
          IconButton(onPressed: navigateToAbout, icon: const Icon(Icons.info)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Stack(
        children: [
          body,
        ],
      ),
    );
  }
}
