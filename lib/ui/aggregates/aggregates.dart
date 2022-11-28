import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';

import '../../utils/providers.dart';
import '../../utils/util.dart';

class Aggregates extends ConsumerWidget {
  const Aggregates({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var asyncValue = ref.watch(myCityAggregateFutureProvider);

    return Scaffold(
      body: asyncValue.when(
          data: (data) {
            List<CityAggregate> list = data.map((e) => e).toList();
            p('Aggregates: City aggregates found : ${list.length}');
            return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  var agg = list.elementAt(index);
                  var fm = NumberFormat.compactCurrency(symbol: 'R');
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 60,
                                child: Text('${agg.averageRating?.toStringAsFixed(1)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                            SizedBox(
                                width: 80,
                                child: Text(fm.format(agg.totalSpent),
                                    style: const TextStyle(fontWeight: FontWeight.w900))),
                            Text(
                              '${agg.cityName}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
          },
          error: (err, s) {
            return Card(
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${err.toString()}'),
              ),
            );
          },
          loading: () => const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.pink,
                ),
              )),
    );
  }
}
