import 'package:flutter/material.dart';

import '../dashboard/widgets/dashboard_grid.dart';

class DashboardDesktop extends StatelessWidget {
  const DashboardDesktop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: const [
          DashboardGrid(
            cardElevation: 4.0,
            height: 300,
            width: 300,
            gridColumns: 3,
            captionTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            numberTextStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
