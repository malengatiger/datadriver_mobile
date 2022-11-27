import 'package:flutter/material.dart';
import 'package:universal_frontend/home/widgets/bar.dart';

import '../utils/emojis.dart';
import '../utils/util.dart';

class HomeTablet extends StatefulWidget {
  const HomeTablet({Key? key}) : super(key: key);

  @override
  State<HomeTablet> createState() => _HomeTabletState();
}

class _HomeTabletState extends State<HomeTablet> {
  @override
  Widget build(BuildContext context) {
    p('Building Tablet  view ... $heartBlue');
    var body = Container(
      color: Colors.green,
    );
    return Bar(
      title: 'Tablet DataDriver',
      body: body,
    );
  }
}
