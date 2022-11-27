import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_frontend/ui/dashboard/dashboard_desktop.dart';
import 'package:universal_frontend/ui/dashboard/dashboard_tablet.dart';

import 'dashboard_mobile.dart';

class DashboardMain extends StatelessWidget {
  const DashboardMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const DashboardMobile(),
      desktop: const DashboardDesktop(),
      tablet: const DashboardTablet(),
    );
  }
}
