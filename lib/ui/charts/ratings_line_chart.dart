import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/hive_util.dart';

import '../../data_models/dashboard_data.dart';
import '../../utils/util.dart';
import 'chart_title.dart';
import 'events_line_chart.dart';

class RatingsLineChart extends StatefulWidget {
  const RatingsLineChart({Key? key})
      : super(key: key);

  @override
  RatingsLineChartState createState() => RatingsLineChartState();
}

class RatingsLineChartState extends State<RatingsLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  var _dashboards = <DashboardData>[];
  LineChartData? data;
  var dataBags = <DataBag>[];
  int lowestValue = 0;
  int highestValue = 0;
  String mHour = '00', mDay = '00', mWeekDay = '00', mMin = '00', mKey = '0000';


  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _getData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int days = 0;
  void _getData() async {
    _dashboards = await hiveUtil.getDashboardDataList(date: DateTime.now().subtract(Duration(days: days)));
    _dashboards.sort((a, b) => a.longDate.compareTo(b.longDate));
    _buildLineChartData();
    setState(() {});
  }
  void _onDaysSelected(int days) {
    this.days = days;
    _getData();
  }

  LineChartData _buildLineChartData() {
    var list = <FlSpot>[];
    _prepareData(list);

    var data = LineChartData(
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
              color: Colors.teal,
              // isStepLineChart: true,
              // isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              lineChartStepData: LineChartStepData(
                  stepDirection: LineChartStepData.stepDirectionMiddle),
              shadow: const Shadow(blurRadius: 16.0),
              barWidth: 4,
              isCurved: true,
              show: true,
              // aboveBarData: BarAreaData(show: true, color: Colors.orange),
              // curveSmoothness: 2.0,
              spots: list),
        ]);

    p('${Emoji.blueDot} .... Prepared List of chart FlSpots: ${list.length}');
    return data;
  }

  void _prepareData(List<FlSpot> list) {
    dataBags.clear();
    //pick latest dashboard within the hour
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
        p('Bags in newList : ????key: ${bag.key} ????avg rating: ${bag.dashboardData.averageRating.toStringAsFixed(2)}');
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

    p('???????????? DataBags - each represents one hour in one day, '
        'total hours: ${newList.length}');
    var fm = NumberFormat.decimalPattern();
    newList.sort((a, b) => a.key.compareTo(b.key));
    for (var mBag in newList) {
      p('${Emoji.blueDot}${Emoji.blueDot}${Emoji.blueDot}'
          ' DataBag: key: ${mBag.key} ???? avg rating: '
          '${mBag.dashboardData.averageRating.toStringAsFixed(2)} '
          '\tat dashboard date: ${mBag.dashboardData.date}');

      //create FlSpots -
      var hour = mBag.key.substring(2, 4);
      list.add(FlSpot(
          double.parse(hour), double.parse('${mBag.dashboardData.averageRating}')));
    }
    for (var value in list) {
      p('????????????FlSpot: x: ${value.x} - y: ${value.y}');
    }
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
          String hour = '';
          int b = value.toInt();
          switch (b) {
            case 1:
              hour = '01';
              break;
            case 2:
              hour = '02';
              break;
            case 3:
              hour = '03';
              break;
            case 4:
              hour = '04';
              break;
            case 5:
              hour = '05';
              break;
            case 6:
              hour = '06';
              break;
            case 7:
              hour = '07';
              break;
            case 8:
              hour = '08';
              break;
            case 9:
              hour = '09';
              break;
            case 10:
              hour = '10';
              break;
            case 11:
              hour = '11';
              break;
            case 12:
              hour = '12';
              break;
            case 13:
              hour = '13';
              break;
            case 14:
              hour = '14';
              break;
            case 15:
              hour = '15';
              break;
            case 16:
              hour = '16';
              break;
            case 17:
              hour = '17';
              break;
            case 18:
              hour = '18';
              break;
            case 19:
              hour = '19';
              break;
            case 20:
              hour = '20';
              break;
            case 21:
              hour = '21';
              break;
            case 22:
              hour = '22';
              break;
            case 23:
              hour = '23';
              break;
            case 0:
              hour = '00';
              break;
          }

          return Text(
            hour,
            style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodySmall,
                fontWeight: FontWeight.bold,
                fontSize: 9),
          );
        },
      );

  SideTitles get _leftTitles => SideTitles(
        showTitles: true,
        reservedSize: 48.0,
        getTitlesWidget: (value, meta) {
          var incomingValue = value.toInt();
          var fm = NumberFormat.compact();

          return Text(
            fm.format(incomingValue),
            style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodySmall,
                fontWeight: FontWeight.normal,
                fontSize: 9),
          );
        },
      );

  bool isPortrait = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        appBar: AppBar(
          title: ChartTitle(days: days, onSelected: _onDaysSelected, title: 'Ratings Chart'),
          actions: [
            IconButton(
                onPressed: () {
                  if (isPortrait) {
                    SystemChrome.setPreferredOrientations(
                      [
                        DeviceOrientation.landscapeRight,
                        DeviceOrientation.landscapeLeft
                      ],
                    );
                    isPortrait = false;
                  } else {
                    SystemChrome.setPreferredOrientations(
                      [
                        DeviceOrientation.portraitDown,
                        DeviceOrientation.portraitUp
                      ],
                    );
                    isPortrait = true;
                  }
                },
                icon: const Icon(Icons.settings)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AspectRatio(
            aspectRatio: isPortrait ? 2 : 4,
            child: LineChart(
              _buildLineChartData(),
              swapAnimationDuration:
                  const Duration(milliseconds: 500), // Optional
              swapAnimationCurve: Curves.linear,
            ),
          ),
        ),
      ),
    );
  }

}


