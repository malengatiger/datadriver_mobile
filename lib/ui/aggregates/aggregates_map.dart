import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'dart:ui' as ui;
import '../../utils/util.dart';
import '../dashboard/widgets/minutes_ago_widget.dart';

class AggregatesMap extends StatefulWidget {
  const AggregatesMap({
    super.key,
    required this.aggregates,
  });

  final List<CityAggregate> aggregates;

  @override
  State<AggregatesMap> createState() => AggregatesMapState();
}

class AggregatesMapState extends State<AggregatesMap>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _topAnimationController;
  // final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? googleMapController;

  static const CameraPosition _inTheAtlanticOcean = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 14,
  );

  bool isLoading = false;
  late CityAggregate firstAggregate;

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    _topAnimationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    firstAggregate = widget.aggregates.first;
    _calculate();
  }
  @override
  void dispose() {
    _animationController.stop(canceled: true);
    _topAnimationController.stop(canceled: true);
    super.dispose();

  }

  var totalCityAmount = 0.0;
  var totalCityRating = 0.0;
  var averageCityRating = 0.0;
  var totalEvents = 0;

  void _calculate() {
    for (var agg in widget.aggregates) {
      totalCityAmount += agg.totalSpent;
      totalCityRating += agg.averageRating;
      totalEvents += agg.numberOfEvents;
    }
    averageCityRating = totalCityRating / widget.aggregates.length;
    setState(() {});
    _topAnimationController.forward();
  }

  Future<void> _putAggregateMarkersOnMap() async {
    if (googleMapController == null) {
      p('$diamond $diamond AggregatesMap: ... googleMapController is null $redDot');
      return;
    }
    p('$diamond $diamond AggregatesMap: ... putting aggregate markers on map, '
        'aggregates:: ${widget.aggregates.length}');
    final Uint8List markIcon = await getImage(images[2], 100);
    _markers.clear();
    for (var agg in widget.aggregates) {
      var marker = Marker(
        markerId: MarkerId(agg.cityId),
        // icon: BitmapDescriptor.fromBytes(markIcon),
        position: LatLng(agg.latitude, agg.longitude),
        infoWindow: InfoWindow(
            title: agg.cityName,
            onTap: () {
              p('tapped ${agg.cityName} $redDot $redDot in InfoWindow');
              _showCityAggregateCard(agg);
            }),
      );
      _markers.add(marker);
    }
    var latLng = LatLng(
        widget.aggregates.first.latitude, widget.aggregates.first.longitude);
    googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 5));
    p('$diamond $diamond AggregatesMap: ... finished putting agg markers on map');
    setState(() {});
    _animationController.forward();
  }

  bool _showCityAggregate = false;
  CityAggregate? aggregate;

  _showCityAggregateCard(CityAggregate c) async {
    aggregate = c;
    _animationController.reset();
    setState(() {
      _showCityAggregate = true;
    });
    _animationController.forward();

  }

  _closeCityAggregateCard() {

    _animationController.reverse().then((value) {
      setState(() {
        _showCityAggregate = false;
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
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        title: isLoading
            ? const Text(
                'Aggregate Map Loading ...',
                style: TextStyle(fontSize: 12),
              )
            : Text(
                'City Aggregate Map',
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).primaryColor),
              ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  AnimatedBuilder(animation: _topAnimationController,
                      builder: (context, child){
                        return FadeScaleTransition(
                            animation: _topAnimationController,
                            child: child);

                      },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Events',
                                  style: TextStyle(fontSize: 10),
                                ),
                                const SizedBox(
                                  width: 2,
                                ),
                                Text(numberFormat.format(totalEvents),
                                    style:
                                    const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(
                                  width: 8,
                                ),
                                const Text(
                                  'Rating',
                                  style: TextStyle(fontSize: 10),
                                ),
                                const SizedBox(
                                  width: 2,
                                ),
                                Text(averageCityRating.toStringAsFixed(2),
                                    style:
                                    const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(
                                  width: 8,
                                ),
                                const Text(
                                  'Amount',
                                  style: TextStyle(fontSize: 10),
                                ),
                                const SizedBox(
                                  width: 2,
                                ),
                                Text(numberFormat.format(totalCityAmount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900))
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),

                             MinutesAgoWidget(date: DateTime.parse(firstAggregate.date).toLocal()),
                            const SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8,)
                ],
              )
            ),
        ),
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
              _putAggregateMarkersOnMap();
            },
          ),
          isLoading
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
                )
              : const SizedBox(
                  height: 0,
                ),
          _showCityAggregate
              ? aggregate == null
                  ? const SizedBox(
                      height: 0,
                    )
                  : Positioned(
                      right: 8,
                      top: 8,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return FadeScaleTransition(
                            animation: _animationController,
                            child: child,
                          );
                        },
                        child: CityAggregateCard(
                          backgroundColor: Colors.black26,
                          cityAggregate: aggregate!,
                          onClose: () {
                            _closeCityAggregateCard();
                          },
                        ),
                      ))
              : const SizedBox(
                  height: 0,
                ),
        ],
      ),
    );
  }
}

class CityAggregateCard extends StatelessWidget {
  const CityAggregateCard(
      {Key? key,
      required this.cityAggregate,
      required this.onClose,
      this.backgroundColor})
      : super(key: key);
  final CityAggregate cityAggregate;
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
      height: 240,
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
                      icon: const Icon(
                        Icons.close,
                        color: Colors.yellow,
                      )),
                  const SizedBox(width: 0),
                ],
              ),
              Text(
                cityAggregate.cityName,
                style: GoogleFonts.secularOne(
                    textStyle: Theme.of(context).textTheme.headline6,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Total Spent:',
                      style: GoogleFonts.lato(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          fontWeight: FontWeight.normal,
                          color: Colors.white),
                    ),
                  ),
                  Text(
                    numberFormat.format(cityAggregate.totalSpent),
                    style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(
                height: 4,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Total Events:',
                      style: GoogleFonts.lato(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          fontWeight: FontWeight.normal,
                          color: Colors.white),
                    ),
                  ),
                  Text(
                    numberFormat.format(cityAggregate.numberOfEvents),
                    style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(
                height: 4,
              ),
              Row(
                children: [
                  SizedBox(
                      width: 120,
                      child: Text(
                        'Average Rating:',
                        style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal,
                            color: Colors.white),
                      )),
                  Text(
                    cityAggregate.averageRating.toStringAsFixed(2),
                    style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
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
