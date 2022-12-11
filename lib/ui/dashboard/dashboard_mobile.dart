import 'dart:collection';

import 'package:animations/animations.dart';
import 'package:emoji_alert/arrays.dart';
import 'package:emoji_alert/emoji_alert.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/services/api_service.dart';
import 'package:universal_frontend/services/timer_generation.dart';
import 'package:universal_frontend/ui/dashboard/widgets/minutes_ago_widget.dart';
import 'package:universal_frontend/ui/dashboard/widgets/time_chooser.dart';
import 'package:universal_frontend/ui/generation/generation_page.dart';
import 'package:universal_frontend/utils/cache_manager.dart';

import '../../services/generation_monitor.dart';
import '../../utils/emojis.dart';
import '../../utils/hive_util.dart';
import '../../utils/providers.dart';
import '../../utils/util.dart';
import '../aggregates/aggregate_page.dart';
import '../dashboard/widgets/dash_grid.dart';

class DashboardMobile extends StatefulWidget {
  const DashboardMobile({Key? key}) : super(key: key);

  @override
  State<DashboardMobile> createState() => DashboardMobileState();
}

class DashboardMobileState extends State<DashboardMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool showStop = false;
  bool isRefresh = false, isLoading = false;
  bool isGenerating = false;
  DashboardData? dashData;
  var apiService = ApiService();

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        value: 0.0,
        reverseDuration: const Duration(milliseconds: 5000),
        vsync: this);
    super.initState();
    _listen();
    _getLocalData();
  }

  void _listen() {
    p('${Emoji.pear}${Emoji.pear} Listening to generation stream ....');
    generationMonitor.timerStream.listen((TimerMessage message) {
      p('${Emoji.pear}${Emoji.pear}${Emoji.pear}${Emoji.pear} '
          '... Received message from generation stream ....'
          '${Emoji.appleRed} statusCode: ${message.statusCode}');
      if (mounted) {
        if (message.statusCode == FINISHED) {
          p('${Emoji.pear}${Emoji.pear}${Emoji.pear}${Emoji.pear} '
              ' Generation has completed. remove busy signal');
          isGenerating = false;
          showGenerator = false;
          setState(() {});
          _getDashboardData();
        } else {
          _processTimerMessage(message);
          setState(() {});
        }
      }
    });
  }

  var cityHashMap = HashMap<String, String>();
  var totalGenerated = 0;
  bool showGenerator = false;
  DateTime? dashDate;


  void _processTimerMessage(TimerMessage message) {
    if (message.statusCode == FINISHED) {
      p('${Emoji.appleGreen} _processTimerMessage: data generation is done!');
      try {
        setState(() {
          showGenerator = false;
        });
      } catch (e) {
        p('${Emoji.redDot} Ignored last setState error ${Emoji.redDot}${Emoji.redDot}');
      }
      return;
    }
    cityHashMap[message.cityName!] = message.cityName!;
    totalGenerated += message.events;
    if (mounted) {
      try {
        setState(() {
          showGenerator = true;
        });
      } catch (e) {
        p('${Emoji.redDot} Ignored setState error ${Emoji.redDot}${Emoji
            .redDot}');
      }
    }
  }

  void _getLocalData() async {
    p('$redDot $redDot ...getting dashboard data from hive.............');
    setState(() {
      isLoading = true;
    });
    _animationController.reverse();

    try {
      p('${Emoji.brocolli} ... getting DashboardData from hive');
      dashData = await hiveUtil.getLastDashboardData();
      if (dashData != null) {

        setState(() {
          dashDate = DateTime.parse(dashData!.date);
          isLoading = false;
        });
        _getDashboardDataQuietly();
      } else {
        _getDashboardData();
      }
      _animationController.forward();
    } catch (e) {
      setState(() {
        isGenerating = false;
      });
      var ding = EmojiAlert(
        emojiSize: 32,
        alertTitle: const Text('DataDriver+'),
        background: Theme.of(context).backgroundColor,
        height: 200,
        emojiType: EMOJI_TYPE.CONFUSED,
        description: Text(
          'Error $e',
          style: const TextStyle(fontSize: 11),
        ),
      );
      ding.displayAlert(context);
    }
  }

  void _getDashboardData() async {
    p('$redDot $redDot ... getting dashboard data .............');
    setState(() {
      isLoading = true;
    });
    _animationController.reverse();

    try {
      p('${Emoji.brocolli} ... getting DashboardData from remote');

      dashData = await apiService.getDashboardData(minutesAgo: minutesAgo);
      dashData!.date = DateTime.now().toIso8601String();
      dashDate = DateTime.parse(dashData!.date);
      await hiveUtil.addDashboardData(data: dashData!);
      setState(() {
        isLoading = false;
        dashDate = DateTime.parse(dashData!.date).toLocal();
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
        date = DateTime.parse(dashData!.date).toLocal();
      });
      var ding = EmojiAlert(
        emojiSize: 32,
        alertTitle: const Text('DataDriver+'),
        background: Theme.of(context).backgroundColor,
        height: 360,
        emojiType: EMOJI_TYPE.CONFUSED,
        description: Text(
          'Error $e',
          style: const TextStyle(fontSize: 11),
        ),
      );
      ding.displayAlert(context);
    }
  }


  DateTime? date;
  void _getDashboardDataQuietly() async {
    p('$redDot $redDot ... getting dashboard data QUIETLY .............');

    setState(() {
      isGenerating = true;
    });
    try {
      p('${Emoji.brocolli} ... getting DashboardData from remote');
      dashData = await apiService.getDashboardData(minutesAgo: minutesAgo);
      dashData!.date = DateTime.now().toIso8601String();
      dashDate = DateTime.parse(dashData!.date);
      await hiveUtil.addDashboardData(data: dashData!);
      setState(() {
        isGenerating = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      var ding = EmojiAlert(
        emojiSize: 32,
        alertTitle: const Text('DataDriver+'),
        background: Theme.of(context).backgroundColor,
        height: 360,
        emojiType: EMOJI_TYPE.CONFUSED,
        description: Text(
          'Error $e',
          style: const TextStyle(fontSize: 11),
        ),
      );
      ding.displayAlert(context);
    }
  }

  bool showTimeChooser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'DataDriver+',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          backgroundColor: Theme.of(context).secondaryHeaderColor,
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MinutesAgoWidget(
                        date: dashDate == null? DateTime.now(): dashDate!,
                      ),
                      const SizedBox(
                        width: 24,
                      ),
                      showGenerator
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                backgroundColor: Colors.pink,
                              ),
                            )
                          : const SizedBox(
                              height: 0,
                            ),
                      const SizedBox(
                        width: 16,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  )
                ],
              )),
          // backgroundColor: Colors.brown[100],
          elevation: 1,
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
              ),
            ),
            IconButton(
                onPressed: () {
                  _getDashboardData();
                },
                icon: const Icon(
                  Icons.refresh,
                )),
          ]),
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              isLoading
                  ? Center(
                      child: SizedBox(
                        height: 60,
                        width: 260,
                        child: Card(
                          elevation: 8,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: const [
                                SizedBox(
                                  height: 4,
                                ),
                                Text('Loading dashboard ...', style: TextStyle(fontSize: 11),),
                                SizedBox(
                                  width: 24,
                                ),
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    backgroundColor: Colors.pink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(height: 0,),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeScaleTransition(
                        animation: _animationController,
                        child: child,
                      );
                    },
                    child: dashData == null? const SizedBox(height: 0,): DashGrid(
                      cardElevation: 4.0,
                      height: 120,
                      width: 240,
                      backgroundColor: Theme.of(context).backgroundColor,
                      gridColumns: 2,
                      captionTextStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.normal),
                      numberTextStyle: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                      dashboardData: dashData!,
                    ),
                  ),
                ),
              ),
            ],
          ),

          showTimeChooser
              ? Positioned(
                  left: 16,
                  top: 16,
                  child: TimeChooser(
                    elevation: 16,
                    backgroundColor: Colors.brown[100],
                    onSelected: onTimeSelected,
                  ))
              : const SizedBox(
                  height: 0,
                ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
          elevation: 8,
          currentIndex: 0,
          onTap: (value) {
            onNavTap(context, value);
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.list), label: 'Aggregates'),
            showGenerator
                ? const BottomNavigationBarItem(
                    icon: Icon(Icons.cancel_outlined), label: 'Cancel Gen.')
                : const BottomNavigationBarItem(
                    icon: Icon(Icons.access_alarm), label: 'Generator'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.cached),
              label: 'Cache',
            ),
          ]),
    );
  }

  void _cancelGeneration() {
    p('${Emoji.redDot} Sending Stop message to the cancel stream');
    generationMonitor.sendStopMessage();
    setState(() {
      showGenerator = false;
    });
  }

  void onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        navigateToAggregates(context);
        break;
      case 1:
        if (showGenerator) {
          _cancelGeneration();
        } else {
          _navigateToGenerator();
        }
        break;
      case 2:
        _navigateToACityList();
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

  void _navigateToACityList() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: const CacheManager()));


  }

  void _navigateToGenerator() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: const GenerationPage()));
  }

  onTimeSelected(double p1) {
    minutesAgo = p1.toInt();
    setState(() {
      showTimeChooser = false;
    });
    _getDashboardData();
  }
}
