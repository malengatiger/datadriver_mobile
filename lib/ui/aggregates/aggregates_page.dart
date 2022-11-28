import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AggregatesPage extends StatefulWidget {
  const AggregatesPage({
    Key? key,
  }) : super(key: key);

  @override
  AggregatesPageState createState() => AggregatesPageState();
}

class AggregatesPageState extends State<AggregatesPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var showBusy = false;
  List<CityAggregate> aggregates = <CityAggregate>[];
  final NetworkService networkService = NetworkService();
  final DataService dataService = DataService();
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    p('$redDot AggregatesPageState: initState to aggPage with ${aggregates.length} aggregates');
    getCityAggregates();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void closeKeyboard() {
    txtController = TextEditingController();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  late Timer timer;
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsed = timer.tick;
      });
    });
  }

  void stopTimer() {
    timer.cancel();
    elapsed = 0;
  }

  int minutes = 10;
  void getCityAggregates() async {
    p('$heartOrange ... getting city aggregates ...');
    closeKeyboard();
    setState(() {
      showBusy = true;
    });

    if (txtController.value.text.isNotEmpty) {
      minutes = int.parse(txtController.value.text);
    }
    startTimer();
    aggregates = await networkService.getCityAggregates(minutes: minutes);
    setState(() {
      showBusy = false;
    });
    stopTimer();
    if (aggregates.isNotEmpty) {
      p('$heartGreen first aggregate: ${aggregates.first.toJson()}');
      p('$heartGreen last aggregate: ${aggregates.last.toJson()}');
    }
    p('$heartOrange $heartOrange $heartOrange total city aggregates: ${aggregates.length}');
  }

  var txtController = TextEditingController();
  int elapsed = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('City Aggregate'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: txtController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    onChanged: (value) {
                      setState(() {
                        minutes = int.parse(value);
                      });
                    },
                    decoration: InputDecoration(
                        hintText: 'Enter number of minutes',
                        label: Text(
                          '$minutes Minutes',
                          style: const TextStyle(color: Colors.white),
                        ),
                        icon: const Icon(
                          Icons.lock_clock,
                          color: Colors.yellow,
                        )),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                IconButton(
                    onPressed: getCityAggregates,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    )),
                showBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Colors.blue,
                        ),
                      )
                    : Container(),
                const SizedBox(
                  width: 12,
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            )
          ]),
        ),
      ),
      backgroundColor: Colors.purple[50],
      body: Column(children: [
        SizedBox(
          height: showBusy ? 60 : 40,
          child: Column(
            children: [
              const SizedBox(
                height: 8,
              ),
              showBusy
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Elapsed Time: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            '$elapsed',
                            style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Text('seconds')
                        ],
                      ),
                    )
                  : Container(),
              const SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Row(
                  children: const [
                    SizedBox(width: 60, child: Text('Rating', style: TextStyle(fontWeight: FontWeight.w900))),
                    SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w900))),
                    Text('City', style: TextStyle(fontWeight: FontWeight.w900))
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
              itemCount: aggregates.length,
              itemBuilder: (_, index) {
                var agg = aggregates.elementAt(index);
                var fm = NumberFormat.compactCurrency(symbol: 'R');
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 60,
                              child: Text('${agg.averageRating?.toStringAsFixed(1)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          SizedBox(
                              width: 80,
                              child:
                                  Text(fm.format(agg.totalSpent), style: const TextStyle(fontWeight: FontWeight.w900))),
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
                );
              }),
        ),
      ]),
    );
  }
}
//