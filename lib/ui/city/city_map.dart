import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/event.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart' as phone_locale;


import '../../data_models/city.dart';
import '../../data_models/city_place.dart';
import '../../utils/providers.dart';
import '../../utils/util.dart';
import '../dashboard/widgets/minutes_ago_widget.dart';

class CityMap extends StatefulWidget {
  const CityMap({super.key, required this.cityId});

  final String cityId;

  @override
  State<CityMap> createState() => CityMapState();
}

class CityMapState extends State<CityMap> {
  // final Completer<GoogleMapController> _mapController = Completer();
  late GoogleMapController _mapController;

  static const CameraPosition _inTheAtlanticOcean = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 14,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  City? city;
  var events = <Event>[];
  var places = <CityPlace>[];
  var placeAggregates = <PlaceAggregate>[];
  bool isLoading = false;
  bool _showPlace = false;
  PlaceAggregate? placeAggregate;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    setState(() {
      isLoading = true;
    });

    await _getCity();
    await _getPlaces();
    await _getEvents();

    HashMap<String, List<Event>> hash = _buildHashMap();
    processHashMap(hash);
    _putPlaceAggregateMarkersOnMap();

    setState(() {
      isLoading = false;
    });
  }

  _getCity() async {
    city = await DataService.getCity(cityId: widget.cityId);
    if (city != null) {
      p('$diamond $diamond CityMap: Found ${city?.city} on Firestore');
    }
  }

  _getEvents() async {
    events =
        await DataService.getCityEvents(cityId: widget.cityId, minutes: 240);
    p('$diamond $diamond CityMap: Found ${events.length} events on Firestore');

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
        var agg = PlaceAggregate(
            placeId: event.placeId,
            name: event.placeName,
            latitude: event.latitude,
            longitude: event.longitude,
            totalSpent: totalAmount,
            averageRating: avg,
            events: list.length);
        placeAggregates.add(agg);
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
    p('$diamond $diamond CityMap: Found ${places.length} city places on Firestore');
  }

  Future<void> _putPlaceAggregateMarkersOnMap() async {
    p('$diamond $diamond CityMap: ... putting place aggregate markers on map, '
        'aggregates:: ${placeAggregates.length}');
    final Uint8List markIcon = await getImage(images[1], 100);
    _markers.clear();
    for (var agg in placeAggregates) {
      var marker = Marker(
        markerId: MarkerId(agg.placeId),
        icon: BitmapDescriptor.fromBytes(markIcon),
        position: LatLng(agg.latitude, agg.longitude),
        infoWindow: InfoWindow(
            title: agg.name,
            onTap: () {
              p('tapped ${agg.name} $redDot $redDot in InfoWindow');
              _showPlaceAggregate(agg);
            }),
      );
      _markers.add(marker);
    }
    var latLng =
        LatLng(placeAggregates.first.latitude, placeAggregates.first.longitude);
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    p('$diamond $diamond CityMap: ... finished putting place aggregate markers on map');
    setState(() {

    });
  }

  _showPlaceAggregate(PlaceAggregate agg) {
    setState(() {
      placeAggregate = agg;
      _showPlace = true;
    });
  }
  _closePlaceAggregate() {
    setState(() {
      placeAggregate = null;
      _showPlace = false;
    });
  }

  Future<Uint8List> getImage(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  List<String> images = [
    'assets/map/location.png',
    'assets/map/location_yellow.png',
    'assets/map/location2.png',
    'assets/map/marker1.png',
    'assets/map/people.webp',
    'assets/map/people48.png',
  ];

  final List<Marker> _markers = <Marker>[];
  var numberFormat = NumberFormat.compactCurrency();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[100],
        title: isLoading? const Text('City Map Loading ...', style: TextStyle(fontSize: 12),) :
        Text('${city?.city}, ${city?.adminName}', style: const TextStyle(fontSize: 12, color: Colors.black),),
        actions: [
          IconButton(onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(20), child: Column(
          children:  [
            GestureDetector(
                onTap: _getData,
                child: const MinutesAgoWidget()),
            const SizedBox(height: 12,)
          ],
        )),
      ),
      backgroundColor: Colors.brown[100],
      body: isLoading
          ? Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: Card(
                  elevation: 8,
                  color: Colors.brown[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    children: const [
                      SizedBox(height: 80,),
                      Text('Loading data ...'),
                      SizedBox(
                        height: 24,
                      ),
                      SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 8,
                          backgroundColor: Colors.pink,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition: _inTheAtlanticOcean,
                  markers: Set<Marker>.of(_markers),
                  buildingsEnabled: true,
                  compassEnabled: true,
                  trafficEnabled: true,
                  mapToolbarEnabled: true,
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    p('$brocolli $brocolli onMapCreated: map is created and ready for markers!');
                    _mapController = controller;
                  },
                ),
                _showPlace? Positioned(
                    right: 8, top: 16,
                    child:  PlaceCard(aggregate: placeAggregate!,
                      onClose: () {
                        _closePlaceAggregate();
                      })) : const SizedBox(height: 0,),
              ],
            ),

    );
  }


}

class PlaceAggregate {
  late final String placeId, name;
  late final double latitude, longitude;
  late final double totalSpent;
  late final double averageRating;
  late final int events;

  PlaceAggregate(
      {required this.placeId,
      required this.name,
      required this.latitude,
      required this.longitude,
      required this.totalSpent,
      required this.averageRating,
      required this.events});
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({Key? key, required this.aggregate, required this.onClose}) : super(key: key);
  final PlaceAggregate aggregate;
  final Function onClose;

  @override
  Widget build(BuildContext context) {
    var currencyFormat = NumberFormat.compactCurrency(locale: Platform.localeName).currencySymbol;
    var numberFormat = NumberFormat.compactCurrency(symbol: currencyFormat);

    return SizedBox(width: 300, height: 280,
      child: Card(
        elevation: 16,
        color: Colors.brown[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(onPressed: () {
                    onClose();
                  }, icon: const Icon(Icons.close)),
                  const SizedBox(width: 0),
                ],
              ),
              Text(aggregate.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),),
              const SizedBox(height: 16,),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('Events:')),
                  Text('${aggregate.events}', style: const TextStyle(fontSize:16, fontWeight: FontWeight.bold),),
                ],
              ),

              const SizedBox(height: 4,),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('Average Rating:')),
                  Text(aggregate.averageRating.toStringAsFixed(2),
                    style:  TextStyle(
                        color: aggregate.averageRating < 3.0? Colors.pink[700]:Colors.black,
                        fontSize:16, fontWeight: FontWeight.bold),),
                ],
              ),
              const SizedBox(height: 24,),
              Row(
                children: [
                  const SizedBox(width:80, child: Text('Amount:')),
                  Text(numberFormat.format(aggregate.totalSpent),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}

