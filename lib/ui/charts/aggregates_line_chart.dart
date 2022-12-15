import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_frontend/utils/hive_util.dart';

import '../../data_models/city_aggregate.dart';
import '../../data_models/dashboard_data.dart';
import '../../utils/util.dart';

class AggregatesLineChart extends StatefulWidget {
  const AggregatesLineChart({Key? key, required this.aggregates})
      : super(key: key);
  final List<CityAggregate> aggregates;

  @override
  AggregatesLineChartState createState() => AggregatesLineChartState();
}

class AggregatesLineChartState extends State<AggregatesLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var myData = <DashboardData>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }
  void _getData() async {
    myData = await hiveUtil.getDashboardDataList();
    //process events, break into hours and events spots
    setState(() {

    });

  }

  LineChartData? data;
  LineChartData _buildLineChartData() {
    var list = <FlSpot>[];
    int count = 0;
    for (var value in myData) {
      if (count < 60) {
        list.add(FlSpot(

            double.parse('$count'), double.parse('${value.events}')));
      }
      count++;
    }

    var data = LineChartData(
        backgroundColor: Colors.teal,
        titlesData: FlTitlesData(show: true,
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 5,
                    getTitlesWidget: getTitleWidget
                    // textStyle: yearTextStyle,
                    ),
                axisNameWidget: const Text('my bottom'),),
            topTitles: AxisTitles(axisNameWidget: const Text('My Chart'))),
        borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide.none)),
        lineBarsData: [
      LineChartBarData(

          color: Colors.pink,
          isStepLineChart: true,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          lineChartStepData: LineChartStepData(stepDirection: LineChartStepData.stepDirectionMiddle),
          shadow: const Shadow(blurRadius: 8.0),
          aboveBarData: BarAreaData(show: true, color: Colors.orange),

          curveSmoothness: 2.0,

          spots: list),

    ]);

    p('List of spots: ${list.length}');
    return data;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Aggregates Line Chart'),
      ),
      body: AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            const SizedBox(
              height: 12,
            ),
             SizedBox(height: 300,
                    child: LineChart(
                      _buildLineChartData(),

                      swapAnimationDuration:
                          const Duration(milliseconds: 150), // Optional
                      swapAnimationCurve: Curves.linear,
                    ),
                  ), // Optional)),
          ],
        ),
      ),
    );
  }

  Widget getTitleWidget(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold, fontSize: 24,
      color: Colors.black,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.toInt().toString(), style: style),
    );
  }
}
