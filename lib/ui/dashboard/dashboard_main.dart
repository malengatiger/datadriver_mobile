import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'dash_desktop.dart';
import 'dashboard_desktop.dart';
import 'dashboard_mobile.dart';

class DashboardMain extends StatelessWidget {
  const DashboardMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const DashboardMobile(),
      desktop: const DashDesktop(),
      tablet: const DashDesktop(),
    );
  }
}
