import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:universal_frontend/data_models/event.dart';
import 'package:universal_frontend/services/data_service.dart';

import '../../data_models/city.dart';
import '../../data_models/city_place.dart';
import '../../utils/util.dart';

class CityMap extends StatefulWidget {
  const CityMap({super.key, required this.cityId});

  final String cityId;

  @override
  State<CityMap> createState() => CityMapState();
}

class CityMapState extends State<CityMap> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  City? city;
  var events = <Event>[];
  var places = <CityPlace>[];
  var aggregates = <PlaceAggregate>[];

  @override
  void initState() {
    super.initState();
    _getCity();
    _getEvents();
    _getPlaces();
  }
  _getCity() async {
    city = await DataService.getCity(cityId: widget.cityId);
  }
  _getEvents() async {
    events = await DataService.getCityEvents(cityId: widget.cityId,
        minutes: 60);
    HashMap<String, List<Event>> hash = _buildHashMap();
    processHashMap(hash);
    _placeEventSummaryMarkers();
  }

  void processHashMap(HashMap<String, List<Event>> hash) {
     hash.forEach((key, list) {
      var totalAmount = 0.0;
      var totalRating = 0;
      for (var value in list) {
        totalAmount += value.amount;
        totalRating += value.rating;
      }
      Event? event;
      var avg = double.parse('$totalRating') / double.parse('${list.length}');
      if (list.isNotEmpty) {
        event = list.first;
      }
      if (event != null) {
        var agg = PlaceAggregate(placeId: event.placeId,
            name: event.placeName,
            latitude: event.latitude, longitude: event.longitude,
            totalSpent: totalAmount, averageRating: avg, events: list.length);
        aggregates.add(agg);
      }
    });
  }

  HashMap<String, List<Event>> _buildHashMap() {
    var hash = HashMap<String, List<Event>>();
    for (var e in events) {
      if (hash.containsKey(e.placeId)) {
        var list = hash[e.placeId];
        if (list != null) {
          list.add(e);
        }
      } else {
        var list = <Event>[];
        list.add(e);
        hash[e.placeId] = list;
      }
    }
    return hash;
  }
  _getPlaces() async {
    places = await DataService.getCityPlaces(cityId: widget.cityId);
  }
  _placeCityMarker() {

  }
  _placeEventSummaryMarkers() {

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          p('map is created!');
          _controller.complete(controller);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}

class PlaceAggregate {
  late final String placeId, name;
  late final double latitude, longitude;
  late final double totalSpent;
  late final double averageRating;
  late final int events;

  PlaceAggregate({required this.placeId, required this.name, required this.latitude, required this.longitude,
    required this.totalSpent, required this.averageRating, required this.events});
}