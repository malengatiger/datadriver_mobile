import 'dart:async';
import 'dart:collection';

import 'package:animations/animations.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/data_models/event.dart';
import 'package:universal_frontend/services/data_service.dart';
import 'package:universal_frontend/ui/city/city_details_page.dart';
import 'package:universal_frontend/ui/city/city_map_header.dart';
import 'package:universal_frontend/ui/dashboard/widgets/minutes_ago_widget.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/hive_util.dart';
import 'package:universal_frontend/utils/providers.dart';
import 'dart:ui' as ui;
import '../../data_models/city.dart';
import '../../data_models/city_place.dart';
import '../../utils/util.dart';

class CityPlacesMap extends StatefulWidget {
  const CityPlacesMap({super.key, required this.details, required this.city});

  final List<Details> details;
  final City city;

  @override
  State<CityPlacesMap> createState() => CityMapState();
}

class CityMapState extends State<CityPlacesMap> with SingleTickerProviderStateMixin {
  // final Completer<GoogleMapController> _mapController = Completer();
  late GoogleMapController googleMapController;
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  late AnimationController _animationController;

  static const CameraPosition _inTheAtlanticOcean = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 12,
  );

  City? city;

  bool isLoading = false;
  bool _showPlace = false;

  @override
  void initState() {
    _animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 3000),
      reverseDuration: const Duration(milliseconds: 2000),
      vsync: this,
    )..addStatusListener((AnimationStatus status) {
        setState(() {

        });
      });
    super.initState();
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  var totalCityAmount = 0.0;
  var totalCityRating = 0;
  var averageCityRating = 0.0;

  Future<void> _putPlaceMarkersOnMap() async {
    p('$diamond $diamond CityPlacesMap: ... putting place aggregate markers on map, '
        'aggregates:: ${widget.details.length}');
    final Uint8List markIcon = await getImage(images[2], 100);
    _markers.clear();

      for (var place in widget.details) {
        var marker = Marker(
          markerId: MarkerId(place.placeId!),
          // icon: BitmapDescriptor.fromBytes(markIcon),
          position: LatLng(place.latitude!,
              place.longitude!),

          infoWindow: InfoWindow(
              title: place.placeName,
              onTap: () {
                p('tapped ${place.placeName} ${Emoji.redDot} ${Emoji.redDot} in InfoWindow');
                //_showPlaceCard(place);
              }),
        );
        _markers.add(marker);
      }
      var latLng = LatLng(widget.details.first.latitude!,
          widget.details.first.longitude!);
      googleMapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));

    setState(() {});
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
      appBar: AppBar(
        title: isLoading
            ? const Text(
                'City Places Map Loading ...',
                style: TextStyle(fontSize: 12),
              )
            : Text(
                '${widget.city.city}',
                style: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    fontWeight: FontWeight.w900),
              ),

        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              children: const [
                SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: 16,
                ),
              ],
            )),
      ),
      // backgroundColor: Colors.brown[100],
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
              p('${Emoji.brocolli} ${Emoji.brocolli} onMapCreated: map is created and ready for markers!');
              googleMapController = controller;
              _putPlaceMarkersOnMap();
            },
          ),
          isLoading
              ? Positioned(
                  left: 48,
                  top: 200,
                  child: Center(
                    child: SizedBox(
                      width: 240,
                      height: 60,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                height: 80,
                              ),
                              Text('Loading data ...'),
                              SizedBox(
                                width: 24,
                              ),
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 8,
                                  backgroundColor: Colors.pink,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(
                  height: 0,
                ),
          _showPlace
              ? Positioned(
                  right: 8,
                  top: 8,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (BuildContext context, Widget? child) {
                      return FadeScaleTransition(
                        animation: _animationController,
                        child: child,
                      );
                    },
                    child: const Card(
                      child: Text('Some work to be done here'),
                    )
                  ),
          )
              : const SizedBox(
                  height: 0,
                ),

        ],
      ),
    );
  }
}


