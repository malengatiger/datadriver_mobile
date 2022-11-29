import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as phoneLocale;
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/services/network_service.dart';
import 'package:universal_frontend/ui/city/city_page.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../../services/timer_generation.dart';
import '../../utils/util.dart';

class AggregatePage extends StatefulWidget {
  const AggregatePage({Key? key}) : super(key: key);

  @override
  AggregatePageState createState() => AggregatePageState();
}

class AggregatePageState extends State<AggregatePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var aggregates = <CityAggregate>[];
  final apiService = ApiService();
  var isLoading = false;
  var minutes = 60;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    p('.... initState inside AggregatePage $redDot');
    _getAggregates();
  }

  void _getAggregates() async {
    p('$brocolli ... getting aggregates ...');
    setState(() {
      isLoading = true;
    });
    aggregates = await apiService.getCityAggregates(minutes: minutes);
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateToCity({required CityAggregate agg}) {
    p('$appleGreen $appleGreen Navigating to city:  ${agg.cityName!} ...');
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: CityPage(
              aggregate: agg,
            )));
  }

  bool isGenerating = false;
  void _startGenerator() {
    if (isGenerating) {
      stopGenerator();
      return;
    }
    TimerGeneration.start(intervalInSeconds: 15, upperCount: 500, max: 5);
    showSnack(message: 'Streaming Generator started!');
  }

  void showSnack({
    required String message,
  }) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      content: Text(message),
    );
    isGenerating = true;

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void stopGenerator() {
    TimerGeneration.stop();
    isGenerating = false;
    showSnack(message: 'Streaming Generator stopped!!');
  }

  @override
  Widget build(BuildContext context) {
    var total = 0.0;
    var events = 0;
    for (var element in aggregates) {
      total += element.totalSpent!;
      events += element.numberOfEvents!;
    }
    var locale = phoneLocale.Intl.getCurrentLocale();

    final f = NumberFormat.compactCurrency(locale: locale);
    final fe = NumberFormat.compact();

    var amt = f.format(total);
    var formattedEvents = fe.format(events);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'City Aggregates',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(onPressed: _getAggregates, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _startGenerator, icon: const Icon(Icons.settings)),
        ],
      ),
      backgroundColor: Colors.brown[100],
      body: Stack(
        children: [
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.pink,
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Card(
                        elevation: 8,
                        color: Colors.pink[50],
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
                                        color: Colors.indigo, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
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
                                    style:
                                        const TextStyle(color: Colors.teal, fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                ],
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
                                    style:
                                        const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: aggregates.length,
                          itemBuilder: (context, index) {
                            var agg = aggregates.elementAt(index);
                            var fm = NumberFormat.compactCurrency(symbol: 'R');
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: GestureDetector(
                                onTap: () {
                                  navigateToCity(agg: agg);
                                },
                                child: Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            width: 60,
                                            child: Text('${agg.averageRating?.toStringAsFixed(1)}',
                                                style:
                                                    const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                                        SizedBox(
                                            width: 80,
                                            child: Text(fm.format(agg.totalSpent),
                                                style: const TextStyle(fontWeight: FontWeight.w900))),
                                        Text(
                                          '${agg.cityName}',
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
                )
        ],
      ),
    );
  }
}
