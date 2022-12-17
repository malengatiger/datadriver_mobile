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
import 'package:universal_frontend/ui/city/city_map_header.dart';
import 'package:universal_frontend/ui/dashboard/widgets/minutes_ago_widget.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/hive_util.dart';
import 'package:universal_frontend/utils/providers.dart';
import 'dart:ui' as ui;
import '../../data_models/city.dart';
import '../../data_models/city_place.dart';
import '../../utils/util.dart';

class CityMap extends StatefulWidget {
  const CityMap({super.key, required this.aggregate});

  final CityAggregate aggregate;

  @override
  State<CityMap> createState() => CityMapState();
}

class CityMapState extends State<CityMap> with SingleTickerProviderStateMixin {
  // final Completer<GoogleMapController> _mapController = Completer();
  late GoogleMapController googleMapController;
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  late AnimationController _animationController;

  static const CameraPosition _inTheAtlanticOcean = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 4,
  );

  City? city;

  var events = <Event>[];
  var places = <CityPlace>[];
  var placeAggregates = <PlaceAggregate>[];

  bool isLoading = false;
  bool _showPlace = false;
  PlaceAggregate? placeAggregate;

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

  Future<void> _getData() async {
    setState(() {
      isLoading = true;
    });

    await _getCity();
    await _getPlaces();
    await _getEvents();

    placeAggregates.clear();
    if (events.isNotEmpty) {
      HashMap<String, List<Event>> hash = _buildHashMap();
      _processHashMap(hash);
    }
    p('${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}'
        ' PlaceAggregates calculated: ${placeAggregates.length}');

    setState(() {
      isLoading = false;
    });
    _putPlaceMarkersOnMap();
  }

  _getCity() async {
    //get city from hive first
    city = await hiveUtil.getCity(cityId: widget.aggregate.cityId);
    city ??= await DataService.getCity(cityId: widget.aggregate.cityId);
  }

  _getEvents() async {
    events = await hiveUtil.getCityEventsMinutesAgo(
        cityId: widget.aggregate.cityId,
        minutesAgo: minutesAgo);
    if (events.isEmpty) {
      p('...... getting cityEvents via DataService ... cityId: ${widget
          .aggregate.cityId} ${Emoji.brocolli}');
      events = await DataService.getCityEvents(
          cityId: widget.aggregate.cityId, minutesAgo: minutesAgo);
      p('$diamond $diamond CityMap: Found ${events
          .length} events on Firestore');
    }

  }

  var totalCityAmount = 0.0;
  var totalCityRating = 0;
  var averageCityRating = 0.0;

  void _processHashMap(HashMap<String, List<Event>> hash) {
    totalCityAmount = 0.0;
    totalCityRating = 0;
    hash.forEach((key, list) {
      var totalAmount = 0.0;
      var totalRating = 0;
      for (var value in list) {
        totalAmount += value.amount;
        totalRating += value.rating;
        totalCityAmount += value.amount;
        totalCityRating += value.rating;
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

    averageCityRating =
        double.parse('$totalCityRating') / double.parse('${events.length}');

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
    places = await hiveUtil.getCityPlaces(cityId: widget.aggregate.cityId);
    if (places.isEmpty) {
      places = await DataService.getCityPlaces(cityId: widget.aggregate.cityId);
    }
    p('$diamond $diamond CityMap: Found ${places.length} city places cached or not');
  }

  Future<void> _putPlaceMarkersOnMap() async {
    p('$diamond $diamond CityMap: ... putting place aggregate markers on map, '
        'aggregates:: ${placeAggregates.length}');
    final Uint8List markIcon = await getImage(images[2], 100);
    _markers.clear();

    if (placeAggregates.isEmpty) {
      for (var place in places) {
        var marker = Marker(
          markerId: MarkerId(place.placeId!),
          // icon: BitmapDescriptor.fromBytes(markIcon),
          position: LatLng(place.geometry!.location!.latitude!,
              place.geometry!.location!.longitude!),

          infoWindow: InfoWindow(
              title: place.name,
              onTap: () {
                p('tapped ${place.name} ${Emoji.redDot} ${Emoji.redDot} in InfoWindow');
                _showPlaceCard(place);
              }),
        );
        _markers.add(marker);
      }
      var latLng = LatLng(places.first.geometry!.location!.latitude!,
          places.first.geometry!.location!.longitude!);
      googleMapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
    } else {
      for (var agg in placeAggregates) {
        if (agg.events > 0) {
          var marker = Marker(
            markerId: MarkerId(agg.placeId),
            // icon: BitmapDescriptor.fromBytes(markIcon),
            position: LatLng(agg.latitude, agg.longitude),

            infoWindow: InfoWindow(
                title: agg.name,
                onTap: () {
                  p('tapped ${agg.name} ${Emoji.redDot} ${Emoji.redDot} in InfoWindow');
                  _showPlaceAggregate(agg);
                }),
          );
          _markers.add(marker);
        }
      }
      var latLng = LatLng(
          placeAggregates.first.latitude, placeAggregates.first.longitude);
      googleMapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      p('$diamond $diamond CityMap: ... finished putting place aggregate markers on map');
    }
    setState(() {});
  }

  CityPlace? selectedCityPlace;
  _showPlaceCard(CityPlace place) {
    p("${Emoji.redDot} Selected place: ${place.name} - ${place.cityName}");
    _animationController.reset();
    setState(() {
      selectedCityPlace = place;
      _showPlace = true;
    });
    _animationController.forward();
  }

  bool _showAgg = false;

  _showPlaceAggregate(PlaceAggregate agg) {
    _animationController.reset();
    setState(() {
      placeAggregate = agg;
      _showAgg = true;
    });
    _animationController.forward();
  }

  _closePlaceAggregate() {
    _animationController.reverse().then((value)  {
      setState(() {
        placeAggregate = null;
        _showAgg = false;
      });
    });


  }

  _closePlaceCard() {
    _animationController.reverse().then((value) {
      setState(() {
        selectedCityPlace = null;
        _showPlace = false;
      });
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
      appBar: AppBar(
        title: isLoading
            ? const Text(
                'City Map Loading ...',
                style: TextStyle(fontSize: 12),
              )
            : Text(
                '${city?.city}, ${city?.adminName}',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
        actions: [
          IconButton(onPressed: _getData, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              children: [
                CityMapHeader(
                  events: widget.aggregate.numberOfEvents,
                  averageRating: widget.aggregate.averageRating,
                  onRequestRefresh: () {
                    _getData();
                  },
                  totalAmount: widget.aggregate.totalSpent,
                ),
                const SizedBox(
                  height: 8,
                ),
                MinutesAgoWidget(date: DateTime.parse(widget.aggregate.date)),
                const SizedBox(
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
              _getData();
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
                    child: PlaceCard(
                        place: selectedCityPlace!,
                        onClose: () {
                          _closePlaceCard();
                        }),
                  ))
              : const SizedBox(
                  height: 0,
                ),
          _showAgg
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
                    child: PlaceAggregateCard(
                      aggregate: placeAggregate!,
                      onClose: _closePlaceAggregate,
                    ),
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

class PlaceAggregateCard extends StatelessWidget {
  const PlaceAggregateCard(
      {Key? key, required this.aggregate, required this.onClose})
      : super(key: key);
  final PlaceAggregate aggregate;
  final Function onClose;

  @override
  Widget build(BuildContext context) {
    // var currencyFormat =
    //     NumberFormat.compactCurrency(locale: Platform.localeName)
    //         .currencySymbol;
    var numberFormat = NumberFormat.compact();

    return SizedBox(
      width: 260,
      height: 220,
      child: Card(
        elevation: 16,
        color: Colors.black38,
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
                      icon: const Icon(Icons.close)),
                  const SizedBox(width: 0),
                ],
              ),
              Text(
                aggregate.name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  SizedBox(
                      width: 80,
                      child: Text(
                        'Events:',
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal,
                            fontSize: 12),
                      )),
                  Text(
                    '${aggregate.events}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Rating:',
                      style: GoogleFonts.lato(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          fontWeight: FontWeight.normal,
                          fontSize: 12),
                    ),
                  ),
                  Text(
                    aggregate.averageRating.toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  SizedBox(
                      width: 80,
                      child: Text(
                        'Amount:',
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal,
                            fontSize: 12),
                      )),
                  Text(
                    numberFormat.format(aggregate.totalSpent),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({Key? key, required this.place, required this.onClose})
      : super(key: key);
  final CityPlace place;
  final Function onClose;

  @override
  Widget build(BuildContext context) {
    // var currencyFormat =
    //     NumberFormat.compactCurrency(locale: Platform.localeName)
    //         .currencySymbol;
    var numberFormat = NumberFormat.compact();

    return SizedBox(
      width: 260,
      height: 160,
      child: Card(
        elevation: 16,
        color: Colors.black38,
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
                      icon: const Icon(Icons.close)),
                  const SizedBox(width: 0),
                ],
              ),
              Text(
                place.name!,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  SizedBox(
                      width: 80,
                      child: Text(
                        'Vicinity:',
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal,
                            fontSize: 12),
                      )),
                  Text(
                    '${place.vicinity}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Province:',
                      style: GoogleFonts.lato(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          fontWeight: FontWeight.normal,
                          fontSize: 12),
                    ),
                  ),
                  Text(
                    place.province!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
