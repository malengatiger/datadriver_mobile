import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';

class DashCard extends StatelessWidget {
  const DashCard({Key? key, required this.dashboardData}) : super(key: key);

  final DashboardData dashboardData;
  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.compact();
    return Card(
      elevation: 4,
      color: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Text(
              'Cities',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              f.format(dashboardData.cities),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.yellow),
            ),
            const SizedBox(
              width: 12,
            ),
            const Text(
              'Events',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              f.format(dashboardData.events),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.yellow),
            ),
            const SizedBox(
              width: 12,
            ),
            const Text(
              'Avg Rating',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              dashboardData.averageRating.toStringAsFixed(2),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.yellow),
            ),
            const SizedBox(
              width: 12,
            ),
            const Text(
              'Amount',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              f.format(dashboardData.amount),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.green),
            )
          ],
        ),
      ),
    );
  }
}
