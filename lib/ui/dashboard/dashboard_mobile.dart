import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/ui/dashboard/widgets/minutes_widget.dart';

import '../../services/timer_generation.dart';
import '../../utils/emojis.dart';
import '../../utils/providers.dart';
import '../../utils/util.dart';
import '../aggregates/aggregate_page.dart';
import '../dashboard/widgets/dashboard_grid.dart';

class DashboardMobile extends StatefulWidget {
  const DashboardMobile({Key? key}) : super(key: key);

  @override
  State<DashboardMobile> createState() => DashboardMobileState();
}

class DashboardMobileState extends State<DashboardMobile> {
  
  bool showStop = false;
  @override
  void initState() {
    super.initState();
    _listen();
  }
  bool isGenerating = false;
  void _startGenerator() {
    if (isGenerating) {
      return;
    }
    TimerGeneration.start(intervalInSeconds: 15, upperCount: 200, max: 10);
    _showSnack(message: 'Streaming Generator started!');
    setState(() {
      isGenerating = true;
      showStop = true;
    });
  }

  void _showSnack({
    required String message,
  }) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _stopGenerator() {
    TimerGeneration.stop();
    isGenerating = false;
    _showSnack(message: 'Streaming Generator stopped!!');
    setState(() {
      isGenerating = false;
      showStop = false;
    });
  }

  void _listen() {
    TimerGeneration.stream.listen((timerMessage) {
      p('$appleGreen $appleGreen $appleGreen $appleGreen  '
          '\nTimerGeneration message arrived, statusCode: ${timerMessage.statusCode} '
          'msg: ${timerMessage.message} $appleRed city: ${timerMessage.cityName}');
      if (mounted) {
        showTimerSnack(message: timerMessage);
        if (timerMessage.statusCode == finished) {
          setState(() {
            isGenerating = false;
            showStop = false;
          });
        }
      }
    });
  }
  void showTimerSnack({
    required TimerMessage message,
  }) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      content: Text('Events: ${message.events} - ${message.cityName} - ${message.message} ' ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    var minutes = 0;
    void refresh(int min) {
      p('Refreshing dashboard mobile .............');
      //ref.refresh(myEventsFutureProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('DataDriver+'), actions: [
        IconButton(
            onPressed: () {
              if (minutes == 0) {
                refresh(30);
              } else {
                refresh(minutes);
              }
            },
            icon: const Icon(Icons.refresh)),
        isGenerating
            ? Container()
            : IconButton(
            onPressed: _startGenerator, icon: const Icon(Icons.settings)),
        showStop
            ? IconButton(
            onPressed: _stopGenerator, icon: const Icon(Icons.stop))
            : Container(),
      ]),
      backgroundColor: Colors.amber.shade100,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
              //   child: MinutesWidget(
              //     min: 0,
              //     max: 10,
              //     divisions: 10,
              //     elevation: 8,
              //     onChanged: (value) {
              //       minutes = value;
              //       refresh(minutes);
              //     },
              //   ),
              // ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: DashboardGrid(
                    cardElevation: 4.0,
                    height: 200,
                    width: 220,
                    backgroundColor: Colors.amber.shade100,
                    gridColumns: 2,
                    captionTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    numberTextStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    minutes: minutes,
                  ),
                ),
              ),

            ],
          ),
          isGenerating
              ? Positioned(
            right: 8,
            top: 8,
            child: SizedBox(
              height: 48,
              width: 48,
              child: Card(
                color: Colors.amber[200],
                elevation: 8,
                child: const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      backgroundColor: Colors.pink,
                    ),
                  ),
                ),
              ),
            ),
          )
              : const SizedBox(
            height: 0,
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          elevation: 8,
          currentIndex: 0,
          onTap: (value) {
            onNavTap(context, value);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Aggregates'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
            BottomNavigationBarItem(
              icon: Icon(Icons.area_chart_sharp),
              label: 'Charts',
            ),
          ]),
    );
  }

  void onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        navigateToAggregates(context);
        break;
      case 1:
        navigateToGenerator();
        break;
      case 2:
        navigateToACityList();
    }
  }

  void navigateToAggregates(BuildContext context) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: const AggregatePage()));
  }

  void navigateToACityList() {}

  void navigateToGenerator() {}
}
