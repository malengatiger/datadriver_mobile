import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/providers.dart';

import '../utils/util.dart';

class EventsList extends ConsumerWidget {
  const EventsList({required this.showHeader, Key? key}) : super(key: key);
  final bool showHeader;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myEventsFutureProvider);

    return Scaffold(
        backgroundColor: Colors.brown[100],
        body: data.when(data: (data) {
          var list = data.map((e) => e).toList();
          return Column(
            children: [
              const SizedBox(height: 48),
              showHeader
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Card(
                        elevation: 8,
                        color: Colors.amber.shade200,
                        child: ListTile(
                          title: Text(
                            'Events in last few minutes',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Colors.pink[400],
                            ),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('Number of Events: ${list.length}'),
                              const SizedBox(
                                width: 48,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                      onPressed: () {
                                        p('$appleGreen ... Refreshing the provider myEventsFutureProvider $appleGreen');
                                        ref.refresh(myEventsFutureProvider);
                                      },
                                      icon: const Icon(Icons.refresh_sharp)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(),
              const SizedBox(
                height: 16,
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      var event = list.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Card(
                          child: ListTile(
                            title: Text(event.placeName),
                            subtitle: Row(
                              children: [
                                Text('rating: ${event.rating} amount: ${event.amount.toStringAsFixed(2)}'),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text('${DateTime.fromMillisecondsSinceEpoch(event.longDate).toIso8601String()} '),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              )
            ],
          );
        }, error: (err, s) {
          return Center(
            child: Text('We have a problem: ${err.toString()}'),
          );
        }, loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }));
  }
}
