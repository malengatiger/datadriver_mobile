import 'package:flutter/material.dart';
import 'package:universal_frontend/data_models/city.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/services/data_service.dart';

class CityPage extends StatefulWidget {
  const CityPage({Key? key, required this.aggregate}) : super(key: key);
  final CityAggregate aggregate;
  @override
  CityPageState createState() => CityPageState();
}

class CityPageState extends State<CityPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  City? city;
  bool isLoading = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getCity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _getCity() async {
    city = await DataService.getCity(cityId: widget.aggregate.cityId);
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.aggregate.cityName,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Container(
        color: Colors.teal,
      ),
    );
  }
}
