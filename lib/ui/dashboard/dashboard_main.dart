import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'dashboard_mobile.dart';

class DashboardMain extends StatelessWidget {
  const DashboardMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const DashboardMobile(),
    );
  }
}
