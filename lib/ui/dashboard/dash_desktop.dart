import 'package:emoji_alert/arrays.dart';
import 'package:emoji_alert/emoji_alert.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:side_navigation/side_navigation.dart';
import 'package:universal_frontend/ui/city/cities_map.dart';
import 'package:universal_frontend/ui/dashboard/widgets/dash_grid.dart';
import 'package:universal_frontend/ui/dashboard/widgets/my_drawer.dart';

import '../../data_models/dashboard_data.dart';
import '../../services/api_service.dart';
import '../../services/timer_generation.dart';
import '../../utils/emojis.dart';
import '../../utils/providers.dart';
import '../../utils/util.dart';

class DashDesktop extends StatefulWidget {
  const DashDesktop({Key? key}) : super(key: key);

  @override
  DashDesktopState createState() => DashDesktopState();
}

class DashDesktopState extends State<DashDesktop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  DashboardData? dashData;
  var apiService = ApiService();
  bool isLoading = false;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    // _listen();
    _getDashboardData();
  }

  void _getDashboardData() async {
    p('$redDot $redDot getting dashboard data .............');
    setState(() {
      isLoading = true;
    });
    try {
      dashData = await apiService.getDashboardData(minutesAgo: minutesAgo);
    } catch (e) {
      var em = EmojiAlert(
        emojiType: EMOJI_TYPE.ANGRY,
        description: Text('$e'),
      );
      em.displayAlert(context);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGenerator() {
    if (isGenerating) {
      return;
    }
    TimerGeneration.start(intervalInSeconds: 5, upperCount: 200, max: 3);
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
      p('$diamond $diamond $diamond $diamond  Dashboard Mobile listening'
          '\nTimerGeneration message arrived, statusCode: ${timerMessage.statusCode} '
          'msg: ${timerMessage.message} $appleRed city: ${timerMessage.cityName}');
      if (mounted) {
        if (timerMessage.statusCode == finished) {
          setState(() {
            isGenerating = false;
            showStop = false;
          });
          _showSnack(message: 'Generation completed!, will refresh');
          _getDashboardData();
        } else {
          showTimerSnack(message: timerMessage);
        }
      }
    });
  }

  void showTimerSnack({
    required TimerMessage message,
  }) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(
        'Events: ${message.events} - ${message.cityName}',
        style: const TextStyle(fontSize: 12),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool showTimeChooser = false, isGenerating = false, showStop = false;
  var selectedIndex = 0;
  Widget _getSelectedWidget() {
    switch (selectedIndex) {
      case 0:
        return dashData == null
            ? const Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: Text(
                'No data yet',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ))
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: DashGrid(
            cardElevation: 4.0,
            height: 120,
            width: 240,
            backgroundColor: Colors.brown.shade100,
            gridColumns: 3,
            captionTextStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.normal),
            numberTextStyle: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900),
            dashboardData: dashData!,
          ),
        );
        break;
      case 1:
        return Container(color: Colors.teal,);
        break;
      case 2:
        return CitiesMap(dashboardData: dashData,);
        break;
      case 3:
        return Container(color: Colors.indigo,);
        break;
    }
    return const Center(
      child: Text('Something not on? '),
    );
  }
  _onSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DataDriver+ Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showTimeChooser = true;
              });
            },
            icon: const FaIcon(
              FontAwesomeIcons.clock,
              size: 18,
              color: Colors.black,
            ),
          ),
          IconButton(
              onPressed: () {
                _getDashboardData();
              },
              icon: const Icon(
                Icons.refresh,
                color: Colors.black,
              )),
          isGenerating
              ? Container()
              : IconButton(
                  onPressed: _startGenerator,
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.black,
                  )),
          showStop
              ? IconButton(
                  onPressed: _stopGenerator, icon: const Icon(Icons.stop))
              : Container(),
        ],
      ),
      backgroundColor: Colors.brown[100],
      body: Stack(children: [
        Row(
          children: [
             MyDrawer(onSelected: _onSelected,),
            const Divider(color: Colors.brown),
            Expanded(
              child: _getSelectedWidget(),
            )
          ],
        ),
        const Positioned(bottom: 12, left: 12, child: DiorTheCat()),
      ]),
    );
  }
}
