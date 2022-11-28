import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/ui/dashboard/widgets/minutes_widget.dart';

import '../../utils/providers.dart';
import '../../utils/util.dart';
import '../dashboard/widgets/dashboard_grid.dart';

class DashboardDesktop extends ConsumerWidget {
  const DashboardDesktop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int minutes = 0;
    void refresh(int min) {
      p('Refreshing dashboard desktop .............');
      ref.refresh(myEventsFutureProvider);
    }

    return Scaffold(
      appBar: AppBar(actions: [
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
      backgroundColor: Colors.indigo.shade100,
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
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: DashboardGrid(
                  cardElevation: 4.0,
                  height: 300,
                  width: 300,
                  backgroundColor: Colors.indigo.shade100,
                  gridColumns: 3,
                  captionTextStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  numberTextStyle: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                  minutes: minutes,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
