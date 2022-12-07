import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/services/api_service.dart';
import 'package:universal_frontend/ui/dashboard/widgets/aggregate_table.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/providers.dart';
import 'package:animations/animations.dart';
import 'package:badges/badges.dart';
import '../../services/timer_generation.dart';
import '../../utils/util.dart';
import '../city/city_map.dart';
import '../dashboard/widgets/minutes_ago_widget.dart';
import 'aggregates_map.dart';

class AggregatePage extends StatefulWidget {
  const AggregatePage({Key? key, this.onSelected}) : super(key: key);

  final Function(CityAggregate)? onSelected;
  @override
  AggregatePageState createState() => AggregatePageState();
}

class AggregatePageState extends State<AggregatePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  var aggregates = <CityAggregate>[];
  final apiService = ApiService();
  var isLoading = false;
  var showStop = false;
  var minutes = minutesAgo;
  var sortBy = 0;

  @override
  void initState() {
    _animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 1500),
      reverseDuration: const Duration(milliseconds: 75),
      vsync: this,
    )..addStatusListener((AnimationStatus status) {
        setState(() {
          // setState needs to be called to trigger a rebuild because
          // the 'HIDE FAB'/'SHOW FAB' button needs to be updated based
          // the latest value of [_controller.status].
        });
      });
    super.initState();
    p('.... initState inside AggregatePage $redDot');
    _getAggregates();
  }

  void _getAggregates() async {
    p('$brocolli ... getting aggregates ...');
    setState(() {
      isLoading = true;
    });
    _animationController.reverse();
    aggregates = await apiService.getCityAggregates(minutes: minutesAgo);
    setState(() {
      isLoading = false;
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void navigateToCityMap({required CityAggregate agg}) {
    p('$appleGreen $appleGreen Navigating to city map:  ${agg.cityName} ...');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: CityMap(
              cityId: agg.cityId,
            )));
  }

  void showTimerSnack({
    required TimerMessage message,
  }) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(
        'Events: ${message.events} - ${message.cityName} ',
        style: const TextStyle(fontSize: 12),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _sortByAmount() {
    p('$redDot sorting aggregates by totalSpent');
    aggregates.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    setState(() {});
  }

  _sortByRating() {
    p('$redDot sorting aggregates by rating');
    aggregates.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    setState(() {});
  }

  _sortByName() {
    p('$redDot sorting aggregates by cityName');
    aggregates.sort((a, b) => a.cityName.compareTo(b.cityName));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final thinStyle = GoogleFonts.lato(
        textStyle: Theme.of(context).textTheme.bodySmall,
        fontWeight: FontWeight.normal);
    var total = 0.0;
    var events = 0;
    for (var element in aggregates) {
      total += element.totalSpent;
      events += element.numberOfEvents;
    }

    // var currencyFormat =
    //     NumberFormat.compactCurrency(locale: Platform.localeName)
    //         .currencySymbol;
    var f = NumberFormat.compact();
    final fe = NumberFormat.compact();
    var amt = f.format(total);
    var formattedEvents = fe.format(events);
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).secondaryHeaderColor,
              title: Text(
                'Aggregates',
                style: TextStyle(
                    fontSize: 14, color: Theme.of(context).primaryColor),
              ),
              bottom: PreferredSize(
                  preferredSize: aggregates.isEmpty
                      ? const Size.fromHeight(120)
                      : const Size.fromHeight(130),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: AnimatedBuilder(animation: _animationController,
                            builder: (BuildContext context, Widget? child) {
                              return FadeScaleTransition(
                                animation: _animationController,
                                child: child,
                              );
                            },
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            // color: Colors.brown[50],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                          width: 100,
                                          child: Text(
                                            'Total Cities:',
                                            style: TextStyle(fontSize: 12),
                                          )),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text(
                                        '${aggregates.length}',
                                        style: const TextStyle(
                                          // color: Colors.indigo,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                          width: 100,
                                          child: Text(
                                            'Total Amount:',
                                            style: TextStyle(fontSize: 12),
                                          )),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text(
                                        amt,
                                        style: const TextStyle(
                                          // color: Colors.teal,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                          width: 100,
                                          child: Text(
                                            'Total Events:',
                                            style: TextStyle(fontSize: 12),
                                          )),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text(
                                        formattedEvents,
                                        style: const TextStyle(
                                          // color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      InkWell(
                        onTap: _getAggregates,
                        child: const MinutesAgoWidget(),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  )),
              actions: [
                IconButton(
                    onPressed: _getAggregates, icon: const Icon(Icons.refresh)),
              ],
            ),
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          elevation: 8,
          color: Theme.of(context).secondaryHeaderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                isLoading
                    ? Center(
                        child: SizedBox(
                          height: 48,
                          width: 200,
                          child: Card(
                            elevation: 16,
                            // color: Colors.brown[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Text(
                                      'Calculating ...',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 28,
                                  ),
                                  Center(
                                    child: SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 8,
                                        backgroundColor: Colors.pink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          kIsWeb //todo check!!!
                              ? const SizedBox(
                                  height: 80,
                                  child: MinutesAgoWidget(),
                                )
                              : const SizedBox(
                                  height: 0,
                                ),
                          aggregates.isEmpty
                              ? Center(
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 60,
                                      ),
                                      const Text(
                                        'No aggregate data',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text('Tap'),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                          IconButton(
                                              onPressed: _getAggregates,
                                              icon: const Icon(Icons.refresh)),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                          const Text('to refresh data'),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Expanded(
                                  child: kIsWeb
                                      ? CityAggregateTable(
                                          aggregates: aggregates,
                                          sortBy: sortBy,
                                          onSelected: (cityAggregate) {
                                            p('$brocolli city aggregate selected: ${cityAggregate.toJson()}');
                                            if (widget.onSelected != null) {
                                              widget.onSelected!(cityAggregate);
                                            }
                                          },
                                        )
                                      : AnimatedBuilder(
                                          animation: _animationController,
                                          builder: (BuildContext context,
                                              Widget? child) {
                                            return FadeScaleTransition(
                                              animation: _animationController,
                                              child: child,
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 2.0),
                                            child: Badge(
                                              elevation: 8,
                                              toAnimate: true,
                                              badgeContent: Text(
                                                '${aggregates.length}',
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              child: ListView.builder(
                                                  itemCount: aggregates.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    var agg = aggregates
                                                        .elementAt(index);
                                                    var fm =
                                                        NumberFormat.compact();
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 4),
                                                      child: PopupMenuButton(
                                                        elevation: 8,
                                                        // color: Colors.brown[50],
                                                        onSelected: (value) {
                                                          p('$redDot PopupMenuButton: onSelected: $value');
                                                        },
                                                        itemBuilder: (context) {
                                                          return [
                                                            PopupMenuItem(
                                                              value: 'goToMap',
                                                              onTap: () {
                                                                p('$redDot PopupMenuItem: city menu item tapped, goToMap: ${agg.cityName}');
                                                                navigateToCityMap(
                                                                    agg: agg);
                                                              },
                                                              child: ListTile(
                                                                title: Text(
                                                                  'Go to Map',
                                                                  style:
                                                                      thinStyle,
                                                                ),
                                                                leading: const Icon(
                                                                    Icons
                                                                        .location_on),
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value:
                                                                  'sortByAmount',
                                                              onTap: () {
                                                                p('$redDot PopupMenuItem: Sort By Amount tapped');
                                                                _sortByAmount();
                                                              },
                                                              child: ListTile(
                                                                leading: const Icon(
                                                                    Icons
                                                                        .sort_by_alpha),
                                                                title: Text(
                                                                  'Sort By Amount',
                                                                  style:
                                                                      thinStyle,
                                                                ),
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value:
                                                                  'sortByName',
                                                              onTap: () {
                                                                p('$redDot PopupMenuItem: Sort By Name tapped');
                                                                _sortByName();
                                                              },
                                                              child: ListTile(
                                                                leading: const Icon(
                                                                    Icons
                                                                        .sort_by_alpha),
                                                                title: Text(
                                                                  'Sort By Name',
                                                                  style:
                                                                      thinStyle,
                                                                ),
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value:
                                                                  'sortByRating',
                                                              onTap: () {
                                                                p('$redDot PopupMenuItem: Sort By Rating tapped');
                                                                _sortByRating();
                                                              },
                                                              child: ListTile(
                                                                leading: const Icon(
                                                                    Icons
                                                                        .sort_by_alpha),
                                                                title: Text(
                                                                  'Sort By Rating',
                                                                  style:
                                                                      thinStyle,
                                                                ),
                                                              ),
                                                            ),
                                                          ];
                                                        },
                                                        child: Card(
                                                          elevation: 1,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Row(
                                                              children: [
                                                                SizedBox(
                                                                    width: 40,
                                                                    child: Text(
                                                                        agg.averageRating
                                                                            .toStringAsFixed(
                                                                                1),
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Colors.blue))),
                                                                // SizedBox(
                                                                //     width: 60,
                                                                //     child: Text(
                                                                //         f.format(agg.numberOfEvents),
                                                                //         style: const TextStyle(
                                                                //             fontWeight: FontWeight
                                                                //                 .bold))),
                                                                SizedBox(
                                                                    width: 80,
                                                                    child: Text(
                                                                        fm.format(agg
                                                                            .totalSpent),
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w900))),
                                                                Flexible(
                                                                  child: Text(
                                                                    agg.cityName,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                            ),
                                          ),
                                        ),
                                ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: aggregates.isEmpty
          ? null
          : BottomNavigationBar(
              elevation: 8,
              currentIndex: 0,
              onTap: (value) {
                onNavTap(context, value);
              },
              items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.area_chart_sharp), label: 'Charts'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.location_on), label: 'Maps'),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_rounded),
                    label: 'Cities',
                  ),
                ]),
    );
  }

  void onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        navigateToCharts();
        break;
      case 1:
        navigateToMap(context);
        break;
      case 2:
        navigateToCityList();
    }
  }

  void navigateToMap(BuildContext context) {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: AggregatesMap(
              aggregates: aggregates,
            )));
  }

  void navigateToCityList() {}

  void navigateToCharts() {}
}
