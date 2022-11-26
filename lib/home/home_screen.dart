import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'home_desktop.dart';
import 'home_mobile.dart';
import 'home_tablet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: const HomeMobile(),
      desktop: const HomeDesktop(),
      tablet: const HomeTablet(),
    );
  }
}
