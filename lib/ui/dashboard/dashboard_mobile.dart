import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/services/api_service.dart';
import 'package:universal_frontend/ui/dashboard/widgets/minutes_ago_widget.dart';
import 'package:universal_frontend/ui/dashboard/widgets/time_chooser.dart';
import 'package:universal_frontend/ui/generation/generation_page.dart';

import '../../services/timer_generation.dart';
import '../../utils/emojis.dart';
import '../../utils/providers.dart';
import '../../utils/util.dart';
import '../aggregates/aggregate_page.dart';
import '../dashboard/widgets/dash_grid.dart';

class DashboardMobile extends StatefulWidget {
  const DashboardMobile({Key? key}) : super(key: key);

  @override
  State<DashboardMobile> createState() => DashboardMobileState();
}

class DashboardMobileState extends State<DashboardMobile> {
  bool showStop = false;
  bool isRefresh = false, isLoading = false;
  bool isGenerating = false;
  DashboardData? dashData;
  var apiService = ApiService();
  @override
  void initState() {
    super.initState();
    _getDashboardData();
  }

  void _getDashboardData() async {
    p('$redDot $redDot getting dashboard data .............');
    setState(() {
      isLoading = true;
    });
    dashData = await apiService.getDashboardData(minutesAgo: minutesAgo);
    setState(() {
      isLoading = false;
    });
  }

  bool showTimeChooser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'DataDriver+',
            style: TextStyle(
                fontSize: 18, color: Colors.brown, fontWeight: FontWeight.w900),
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(20), child: Column(
            children: const [
              MinutesAgoWidget(),
              SizedBox(height: 12,)
            ],
          )),
          backgroundColor: Colors.brown[100],
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

          ]),
      backgroundColor: Colors.brown.shade100,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              isLoading? SizedBox(
                height: 100,
                width: 200,
                child: Center(
                  child: Card(
                    color: Colors.brown[100],
                    elevation: 16,
                    child: Column(
                      children: const [
                        SizedBox(
                          height: 16,
                        ),
                        Text('Loading data ...'),
                        SizedBox(
                          height: 8,
                        ),
                        Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                backgroundColor: Colors.pink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ) : Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: DashGrid(
                          cardElevation: 4.0,
                          height: 120,
                          width: 240,
                          backgroundColor: Colors.brown.shade100,
                          gridColumns: 2,
                          captionTextStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.normal),
                          numberTextStyle: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900),
                          dashboardData: dashData!,
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
                    height: 60,
                    width: 160,
                    child: Card(
                      color: Colors.brown[100],
                      elevation: 16,
                      child: Center(
                        child: Column(
                          children: const [
                            Text(
                              'Generating events ...',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 6,
                                backgroundColor: Colors.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(
                  height: 0,
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
      bottomNavigationBar: dashData?.events == 0? const SizedBox(): BottomNavigationBar(
          elevation: 8,
          currentIndex: 0,
          onTap: (value) {
            onNavTap(context, value);
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.list), label: 'Aggregates'),
            BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm), label: 'Generator'),
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
        _navigateToGenerator();
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

  void _navigateToACityList() {}

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
