import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';
import 'package:universal_frontend/utils/emojis.dart';
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
  var _dashboards = <DashboardData>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();

  }

  void _getData() async {
    _dashboards = await hiveUtil.getDashboardDataList(24);
    //process events, break into hours and events spots
    _dashboards.sort((a,b) => a.longDate.compareTo(b.longDate));
    _buildLineChartData();
    setState(() {});
  }

  LineChartData? data;
  var dataBags = <DataBag>[];
  int lowestValue = 0;
  int highestValue = 0;
  String mHour = '00', mDay = '00', mWeekDay = '00', mMin = '00', mKey = '0000';

  LineChartData _buildLineChartData() {
    var list = <FlSpot>[];
    dataBags.clear();
    //bunch dashboard into the latest within the hour
    p('${Emoji.blueDot}${Emoji.blueDot}_buildLineChartData starting .... '
        '${Emoji.blueDot} _dashboards: ${_dashboards.length}');

    _dashboards.sort((a, b) => a.longDate.compareTo(b.longDate));
    var map = HashMap<String, DataBag>();
    for (var dashboard in _dashboards) {
      DataBag bag = _createDashboardBag(dashboard);
      if (!map.containsKey(mKey)) {
        map[mKey] = bag;
      }
    }

    dataBags = map.values.toList();
    dataBags.sort((a, b) => a.key.compareTo(b.key));
    var nMap = HashMap<String, DataBag>();
    for (var mBag in dataBags) {
      if (!nMap.containsKey(mBag.key)) {
        nMap[mBag.key] = mBag;
      }
    }
    var newList = nMap.values.toList();
    newList.sort((a, b) => b.key.compareTo(a.key));

    //find highest and lowest events
    if (newList.isNotEmpty) {
      lowestValue = newList.first.dashboardData.events;
      highestValue = newList.first.dashboardData.events;
      for (var bag in newList) {
        p('Bags in newList : 🍊key: ${bag.key} 🍊events: ${bag.dashboardData.events}');
        if (bag.dashboardData.events < lowestValue) {
          lowestValue = bag.dashboardData.events;
        }
        if (bag.dashboardData.events >= highestValue) {
          highestValue = bag.dashboardData.events;
        }
      }
    }
    p('${Emoji.leaf}${Emoji.leaf} '
        'Filtered list of dataBags: ${newList.length} lowest: $lowestValue highest: $highestValue}');

    p('🍊🍊🍊 DataBags - each represents one hour in one day, '
        'total hours: ${newList.length}');
    var fm = NumberFormat.decimalPattern();
    var cnt = 0;
    newList.sort((a,b) => a.key.compareTo(b.key));
    for (var mBag in newList) {
      p('${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot}'
          ' DataBag: key: ${mBag.key} 🍊 events: '
          '${fm.format(mBag.dashboardData.events)} '
          '\tat dashboard date: ${mBag.dashboardData.date}');

      //create FlSpots - limit to 12 for now
      if (cnt < 12) {
        var hour = mBag.key.substring(2,4);
        list.add(FlSpot(double.parse(hour),
            double.parse('${mBag.dashboardData.events}')));
      }
      cnt++;
    }
    for (var value in list) {
      p('🍐🍐🍐FlSpot: x: ${value.x} - y: ${value.y}');
    }

    var data = LineChartData(
        // backgroundColor: Colors.teal,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: _bottomTitles),
          leftTitles: AxisTitles(sideTitles: _leftTitles),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),

        borderData: FlBorderData(
            border: const Border(bottom: BorderSide(), left: BorderSide())),
        lineBarsData: [
          LineChartBarData(
              color: Colors.pink,
              // isStepLineChart: true,
              // isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              lineChartStepData: LineChartStepData(
                  stepDirection: LineChartStepData.stepDirectionMiddle),
              shadow: const Shadow(blurRadius: 8.0),
              show: true,
              // aboveBarData: BarAreaData(show: true, color: Colors.orange),
              // curveSmoothness: 2.0,
              spots: list),
        ]);

    p('${Emoji.blueDot} .... List of chart spots: ${list.length}');
    return data;
  }

  DataBag _createDashboardBag(DashboardData dash) {
    var date = DateTime.parse(dash.date);
    mDay = '00';
    if (date.day < 10) {
      mDay = '0${date.day}';
    } else {
      mDay = '${date.day}';
    }
    mWeekDay = '00';
    if (date.weekday < 10) {
      mWeekDay = '0${date.weekday}';
    } else {
      mWeekDay = '${date.weekday}';
    }
    mHour = '00';
    if (date.hour < 10) {
      mHour = '0${date.hour}';
    } else {
      mHour = '${date.hour}';
    }
     mMin = '00';
    if (date.minute < 10) {
      mMin = '0${date.minute}';
    } else {
      mMin = '${date.minute}';
    }
    mKey = '$mDay$mHour';
    var bag = DataBag(
        key: mKey,
        minute: mMin,
        hour: mHour,
        weekDay: mWeekDay,
        day: mDay,
        dashboardData: dash);
    return bag;
  }

  SideTitles get _bottomTitles => SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) {

      String text = '';
      int b = value.toInt();
      switch (b) {
        case 1:
          text = '01';
          break;
        case 2:
          text = '02';
          break;
        case 3:
          text = '03';
          break;
        case 4:
          text = '04';
          break;
        case 5:
          text = '05';
          break;
        case 6:
          text = '06';
          break;
        case 7:
          text = '07';
          break;
        case 8:
          text = '08';
          break;
        case 9:
          text = '09';
          break;
        case 10:
          text = '10';
          break;
        case 11:
          text = '11';
          break;
        case 12:
          text = '12';
          break;
        case 13:
          text = '13';
          break;
        case 14:
          text = '14';
          break;
        case 15:
          text = '15';
          break;
        case 16:
          text = '16';
          break;
        case 17:
          text = '17';
          break;
        case 18:
          text = '18';
          break;
        case 19:
          text = '19';
          break;
        case 20:
          text = '20';
          break;
        case 21:
          text = '21';
          break;
        case 22:
          text = '22';
          break;
        case 23:
          text = '23';
          break;
        case 0:
          text = '00';
          break;
      }

      return Text(text,style: GoogleFonts.lato(
          textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.normal, fontSize: 10),);
    },
  );

  SideTitles get _leftTitles => SideTitles(
    showTitles: true,
    reservedSize: 36.0,
    getTitlesWidget: (value, meta) {
      //lowest: 2591 highest: 55107}
      var m = value.toInt();
      var delta = highestValue - lowestValue;
      //break delta into units of 10,000
      var valueOfEachUnit = delta ~/ 10;
      int divisor = 100;
      int result = (valueOfEachUnit ~/ divisor) * divisor;
      // p('🍊🍊🍊result: $result - each unit on left side is this much');

      var units = <int>[];
      for (var i = 0; i < 10; i++) {
        //round to nearest thousand ...
        units.add(result * (i+1));
      }
      //p(' 🔴 units: $units');
//flutter: 🔴 🔴 units: [5200, 10400, 15600, 20800, 26000, 31200, 36400, 41600, 46800, 52000]
      var fm = NumberFormat.compact();
      // m = 8,000 - what unit value fits?
      var unitValue = 0;
      for (var value1 in units) {
        if (m <= value1) {
          unitValue = value1;
            break;
        }
        unitValue++;

      }
      // p(unitValue);
      return Text(fm.format(unitValue), style: GoogleFonts.lato(
          textStyle: Theme.of(context).textTheme.bodyMedium,
          fontWeight: FontWeight.normal, fontSize: 9),);
    },
  );

  bool isPortrait = false;

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        appBar: AppBar(
          title: const Text('Aggregates Chart', style: TextStyle(fontSize: 12),),
          actions: [
            IconButton(onPressed: () {
              if (isPortrait) {
                SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft],
                );
                isPortrait = false;
              } else {
                SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp],
                );
                isPortrait = true;
              }
            }, icon: const Icon(Icons.settings)),
          ],

        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: isPortrait? 2:4,
            child: LineChart(
              _buildLineChartData(),
              swapAnimationDuration:const Duration(milliseconds: 500), // Optional
              swapAnimationCurve: Curves.linear,
            ),
          ),
        ),
      ),
    );
  }

  Widget getTitleWidget(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.black,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.toInt().toString(), style: style),
    );
  }
}

class DataBag {
  late String key;
  late String day;
  late String hour;
  late String minute;
  late String weekDay;

  late DashboardData dashboardData;

  DataBag(
      {required this.key,
      required this.day,
      required this.hour,
      required this.weekDay,
      required this.minute,
      required this.dashboardData});

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['key'] = key;
    map['day'] = day;
    map['hour'] = hour;
    map['weekDay'] = weekDay;
    map['dashboardData'] = dashboardData.toJson();

    return map;
  }
}
