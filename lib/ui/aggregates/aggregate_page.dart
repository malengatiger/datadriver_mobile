import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/services/api_service.dart';
import 'package:universal_frontend/ui/dashboard/widgets/aggregate_table.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/providers.dart';

import '../../services/timer_generation.dart';
import '../../utils/util.dart';
import '../city/city_map.dart';
import '../dashboard/widgets/minutes_ago_widget.dart';

class AggregatePage extends StatefulWidget {
  const AggregatePage({Key? key, this.onSelected}) : super(key: key);

  final Function(CityAggregate)? onSelected;
  @override
  AggregatePageState createState() => AggregatePageState();
}

class AggregatePageState extends State<AggregatePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var aggregates = <CityAggregate>[];
  final apiService = ApiService();
  var isLoading = false;
  var showStop = false;
  var minutes = minutesAgo;
  var sortBy = 0;


  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    p('.... initState inside AggregatePage $redDot');
    _getAggregates();
    _listen();
  }

  void _getAggregates() async {
    p('$brocolli ... getting aggregates ...');
    setState(() {
      isLoading = true;
    });
    aggregates = await apiService.getCityAggregates(minutes: minutesAgo);
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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

  bool isGenerating = false;
  void _startGenerator() {
    if (isGenerating) {
      return;
    }
    TimerGeneration.start(intervalInSeconds: 15, upperCount: 200, max: 10);
    showSnack(message: 'Streaming Generator started!');
    setState(() {
      isGenerating = true;
      showStop = true;
    });
  }

  void showSnack({
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
    showSnack(message: 'Streaming Generator stopped!!');
    setState(() {
      isGenerating = false;
      showStop = false;
    });
  }

  void _listen() {
    TimerGeneration.stream.listen((timerMessage) {
      p('$appleGreen $appleGreen $appleGreen $appleGreen  Aggregate Page listen()'
          '\nTimerGeneration message arrived, statusCode: ${timerMessage.statusCode} '
          'msg: ${timerMessage.message} $appleRed city: ${timerMessage.cityName}');
      if (mounted) {
        showTimerSnack(message: timerMessage);
        if (timerMessage.statusCode == finished) {
          setState(() {
            isGenerating = false;
            showStop = false;
          });
          _getAggregates();
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
        'Events: ${message.events} - ${message.cityName} ',
        style: const TextStyle(fontSize: 12),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _sortByAmount() {
    p('$redDot sorting aggregates by totalSpent');
    aggregates.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    if (aggregates.isNotEmpty) {
      p('$appleRed $appleRed ${aggregates.first.totalSpent} - ${aggregates.first.cityName}');
      p('$appleGreen $appleGreen ${aggregates.last.totalSpent} - ${aggregates.last.cityName}');
    }
    setState(() {});
  }

  _sortByName() {
    p('$redDot sorting aggregates by cityName');
    aggregates.sort((a, b) => a.cityName.compareTo(b.cityName));
    if (aggregates.isNotEmpty) {
      p('$appleRed $appleRed ${aggregates.first.totalSpent} - ${aggregates.first.cityName}');
      p('$appleGreen $appleGreen ${aggregates.last.totalSpent} - ${aggregates.last.cityName}');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: Colors.brown[100],
              title: const Text(
                'Aggregates',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              bottom: PreferredSize(
                  preferredSize: aggregates.isEmpty
                      ? const Size.fromHeight(120)
                      : const Size.fromHeight(130),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Card(
                          elevation: 4,
                          color: Colors.brown[50],
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
                                          color: Colors.indigo,
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
                                          color: Colors.teal,
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
                                          color: Colors.black,
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
                      const SizedBox(
                        height: 12,
                      ),
                      InkWell(
                        onTap: _getAggregates,
                        child: const MinutesAgoWidget(),
                      ),
                    ],
                  )),
              actions: [
                IconButton(
                    onPressed: _getAggregates, icon: const Icon(Icons.refresh)),
                isGenerating
                    ? Container()
                    : IconButton(
                        onPressed: _startGenerator,
                        icon: const Icon(Icons.settings)),
                showStop
                    ? IconButton(
                        onPressed: _stopGenerator, icon: const Icon(Icons.stop))
                    : Container(),
              ],
            ),
      backgroundColor: Colors.brown[100],
      body: Stack(
        children: [
          isLoading
              ? Center(
                  child: SizedBox(
                    height: 200,
                    width: 260,
                    child: Card(
                      elevation: 16,
                      color: Colors.brown[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Center(
                        child: Column(
                          children: const [
                            SizedBox(
                              height: 60,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'Aggregate calculations ...',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12),
                              ),
                            ),
                            SizedBox(
                              height: 24,
                            ),
                            Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
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
                    kIsWeb
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                            child: kIsWeb? CityAggregateTable(aggregates: aggregates,
                              sortBy: sortBy, onSelected: (cityAggregate ) {
                                p('$brocolli city aggregate selected: ${cityAggregate.toJson()}');
                                if (widget.onSelected != null) {
                                  widget.onSelected!(cityAggregate);
                                }
                                },) : ListView.builder(
                                itemCount: aggregates.length,
                                itemBuilder: (context, index) {
                                  var agg = aggregates.elementAt(index);
                                  var fm =
                                      NumberFormat.compactCurrency(symbol: 'R');
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: GestureDetector(
                                      onTap: () {
                                        navigateToCityMap(agg: agg);
                                      },
                                      child: Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                  width: 60,
                                                  child: Text(
                                                      agg.averageRating
                                                          .toStringAsFixed(1),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.blue))),
                                              SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                      f.format(agg.numberOfEvents),
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                      fm.format(agg.totalSpent),
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight
                                                              .w900))),
                                              Text(
                                                agg.cityName,
                                                style: const TextStyle(
                                                  fontSize: 12,
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
            child: const AggregatePage()));
  }

  void navigateToCityList() {}
  void navigateToCharts() {}
}
