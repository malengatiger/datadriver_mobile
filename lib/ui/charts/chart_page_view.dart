import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_frontend/ui/charts/events_line_chart.dart';
import 'package:universal_frontend/ui/charts/ratings_line_chart.dart';

import 'money_line_chart.dart';

class ChartPageView extends StatefulWidget {
  const ChartPageView({Key? key}) : super(key: key);

  @override
  ChartPageViewState createState() => ChartPageViewState();
}

class ChartPageViewState extends State<ChartPageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final PageController _pageController = PageController();


  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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


  final _pages = <Widget>[

    const Center(child:MoneyLineChart(),),
    const Center(child:EventsLineChart(),),
    const Center(child:RatingsLineChart(),)];


  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(

      body: PageView(
        scrollDirection: Axis.horizontal,
        controller: _pageController,
        children: _pages,

      ),
    ));
  }
}
