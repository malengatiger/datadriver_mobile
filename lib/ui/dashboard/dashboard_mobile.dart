import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/ui/dashboard/widgets/minutes_widget.dart';

import '../../utils/providers.dart';
import '../../utils/util.dart';
import '../dashboard/widgets/dashboard_grid.dart';

class DashboardMobile extends ConsumerWidget {
  const DashboardMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var minutes = 0;
    void refresh(int min) {
      p('Refreshing dashboard mobile .............');
      ref.refresh(myEventsFutureProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [
        IconButton(
            onPressed: () {
              if (minutes == 0) {
                refresh(30);
              } else {
                refresh(minutes);
              }
            },
            icon: const Icon(Icons.refresh)),
      ]),
      backgroundColor: Colors.amber.shade100,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: MinutesWidget(
                  min: 0,
                  max: 10,
                  divisions: 10,
                  elevation: 8,
                  onChanged: (value) {
                    minutes = value;
                    refresh(minutes);
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: DashboardGrid(
                    cardElevation: 4.0,
                    height: 200,
                    width: 220,
                    backgroundColor: Colors.amber.shade100,
                    gridColumns: 2,
                    captionTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    numberTextStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    minutes: minutes,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
