import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/data_models/event.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/ui/dashboard/widgets/dash_card.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/providers.dart';
import 'dart:ui' as ui;
import '../../data_models/city.dart';
import '../../data_models/city_place.dart';
import '../../utils/util.dart';
import '../dashboard/widgets/minutes_ago_widget.dart';

class CitiesMap extends StatefulWidget {
  const CitiesMap({super.key, this.dashboardData, });

  final DashboardData? dashboardData;

  @override
  State<CitiesMap> createState() => CitiesMapState();
}

class CitiesMapState extends State<CitiesMap> {
  // final Completer<GoogleMapController> _mapController = Completer();
   GoogleMapController? googleMapController;

  static const CameraPosition _inTheAtlanticOcean = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 14,
  );

  var cities = <City>[];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

  }

  Future<void> _getData() async {
    setState(() {
      isLoading = true;
    });

    await _getCities();

    setState(() {
      isLoading = false;
    });
  }

  _getCities() async {
    cities = await DataService.getCities();
    p('$diamond $diamond CitiesMap: Found ${cities.length} cities on Firestore');
    _putCityMarkersOnMap();
  }


  var totalCityAmount = 0.0;
  var totalCityRating = 0;
  var averageCityRating = 0.0;


  Future<void> _putCityMarkersOnMap() async {
    if (googleMapController == null) {
      p('$diamond $diamond CitiesMap: ... googleMapController is null $redDot');
      return;
    }
    p('$diamond $diamond CitiesMap: ... putting city markers on map, '
        'cities:: ${cities.length}');
    final Uint8List markIcon = await getImage(images[2], 100);
    _markers.clear();
    for (var city in cities) {
      var marker = Marker(
        markerId: MarkerId(city.id),
        // icon: BitmapDescriptor.fromBytes(markIcon),
        position: LatLng(city.latitude, city.longitude),
        infoWindow: InfoWindow(
            title: city.city,
            onTap: () {
              p('tapped ${city.city} $redDot $redDot in InfoWindow');
              _showCityCard(city);
            }),
      );
      _markers.add(marker);
    }
    var latLng =
        LatLng(cities.first.latitude, cities.first.longitude);
    googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 6));
    p('$diamond $diamond CitiesMap: ... finished putting city markers on map');
    setState(() {});
  }
  bool _showCity = false;
  City? city;

  _showCityCard(City c) {
    city = c;
    setState(() {
      _showCity = true;
    });
  }

  _closeCityCard() {
    setState(() {
      _showCity = false;
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
  final numberFormat = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.brown[100],
      //   title: isLoading
      //       ? const Text(
      //           'Cities Map Loading ...',
      //           style: TextStyle(fontSize: 12),
      //         )
      //       : const Text(
      //           'Cities Map',
      //           style: TextStyle(fontSize: 12, color: Colors.black),
      //         ),
      //   actions: [
      //     IconButton(onPressed: _getData, icon: const Icon(Icons.refresh)),
      //   ],
      //   bottom: PreferredSize(
      //       preferredSize: const Size.fromHeight(80),
      //       child: Column(
      //         children: [
      //           Row(
      //             mainAxisAlignment: MainAxisAlignment.center,
      //             children: [
      //               const Text(
      //                 'Events',
      //                 style: TextStyle(fontSize: 10),
      //               ),
      //               const SizedBox(
      //                 width: 4,
      //               ),
      //               Text(numberFormat.format(cities.length),
      //                   style: const TextStyle(fontWeight: FontWeight.bold)),
      //               const SizedBox(
      //                 width: 8,
      //               ),
      //               const Text(
      //                 'Average Rating',
      //                 style: TextStyle(fontSize: 10),
      //               ),
      //               const SizedBox(
      //                 width: 4,
      //               ),
      //               Text(averageCityRating.toStringAsFixed(2),
      //                   style: const TextStyle(fontWeight: FontWeight.bold)),
      //             ],
      //           ),
      //           const SizedBox(height: 4,),
      //           Row(
      //             mainAxisAlignment: MainAxisAlignment.center,
      //             children: [
      //               const SizedBox(
      //                 width: 8,
      //               ),
      //               const Text(
      //                 'Amount',
      //                 style: TextStyle(fontSize: 10),
      //               ),
      //               const SizedBox(
      //                 width: 4,
      //               ),
      //               Text(numberFormat.format(totalCityAmount),
      //                   style: const TextStyle(
      //                       fontSize: 16, fontWeight: FontWeight.w900))
      //             ],
      //           ),
      //           const SizedBox(
      //             height: 8,
      //           ),
      //           GestureDetector(
      //               onTap: _getData, child: const MinutesAgoWidget()),
      //           const SizedBox(
      //             height: 12,
      //           )
      //         ],
      //       )),
      // ),
      backgroundColor: Colors.brown[100],
      body: Stack(
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
                    googleMapController = controller;
                    _getData();
                  },
                ),
                isLoading? Center(
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
                          SizedBox(
                            height: 80,
                          ),
                          Text('Loading data ...'),
                          SizedBox(
                            height: 24,
                          ),
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 8,
                              backgroundColor: Colors.pink,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ): const SizedBox(height: 0,),
                _showCity
                    ? Positioned(
                        right: 8,
                        top: 80,
                        child: CityCard(
                            backgroundColor: Colors.black26,
                            city: city!,
                            onClose: () {
                              _closeCityCard();
                            }))
                    : const SizedBox(
                        height: 0,
                      ),
                widget.dashboardData == null? const SizedBox(height: 0,):
                      Positioned(
                        right: 8, top: 8,
                        child: DashCard(dashboardData: widget.dashboardData!)),
              ],
            ),
    );
  }
}

class CityCard extends StatelessWidget {
  const CityCard({Key? key, required this.city, required this.onClose, this.backgroundColor})
      : super(key: key);
  final City city;
  final Function onClose;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // var currencyFormat =
    //     NumberFormat.compactCurrency(locale: Platform.localeName)
    //         .currencySymbol;
    var numberFormat = NumberFormat.compact();

    return SizedBox(
      width: 240,
      height: 200,
      child: Card(
        elevation: 16,
        color: backgroundColor ?? Colors.brown[100],
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
                  IconButton(
                      onPressed: () {
                        onClose();
                      },
                      icon: const Icon(Icons.close, color: Colors.yellow,)),
                  const SizedBox(width: 0),
                ],
              ),
              Text(
                city.city,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('Province:', style: TextStyle(
                    color: Colors.white
                  ),)),
                  Text(
                    city.adminName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(
                height: 4,
              ),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('Population:', style: TextStyle(
                      color: Colors.white
                  ))),
                  Text(
                    city.populationProper,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold, ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),

            ],
          ),
        ),
      ),
    );
  }
}


