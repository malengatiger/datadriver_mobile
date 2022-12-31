import 'dart:async';
import 'dart:collection';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_frontend/ui/city/city_places_map.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../../data_models/city.dart';
import '../../data_models/event.dart';
import '../../utils/hive_util.dart';

class CityDetailsPage extends StatefulWidget {
  const CityDetailsPage({Key? key, required this.numberOfDays, required this.city}) : super(key: key);

  final int numberOfDays;
  final City city;
  @override
  CityDetailsPageState createState() => CityDetailsPageState();
}

class CityDetailsPageState extends State<CityDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  var events = <Event>[];
  var placeAggregates = <Details>[];
  bool busy = false;
  int elapsedSeconds = 0;
  final fm = NumberFormat.decimalPattern();

  @override
  void initState() {
    _animationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 4000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    super.initState();
    _getEvents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Timer? timer;
  void _startTimer() {
   timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (mounted) {
        setState(() {
          elapsedSeconds = timer.tick;
        });
      }
    });
  }

  void _getEvents() async {
    _startTimer();
    setState(() {
        busy = true;
    });
    events = await hiveUtil.getCityEventsAll(cityId: widget.city.id!);
    events.sort((a,b) => b.longDate.compareTo(a.longDate));
    _processEvents();
    setState(() {
      busy = false;
    });

  }

  void _processEvents() {
    //bunch up by place ....
    _animationController.reset();
    var map = HashMap<String,Details>();
    for (var event in events) {
      if (map.containsKey(event.placeId)) {
        var det = map[event.placeId];
        det?.numberOfEvents++;
        map[event.placeId] = det!;
      } else {
         var det = Details(numberOfEvents: 1, placeId: event.placeId, placeName: event.placeName,
             latitude: event.latitude, longitude: event.longitude);
         map[event.placeId] = det;
      }
    }
    placeAggregates = map.values.toList();
    placeAggregates.sort((a,b) => a.placeName.compareTo(b.placeName));
    if (timer != null) {
      timer!.cancel();
    }
    setState(() {

    });
    _animationController.forward();
  }
  bool _sortedByEvents = true;
  void _sort() {
    if (_sortedByEvents) {
      _sortByName();
    } else {
      _sortByEvents();
    }
  }
  void _sortByEvents() {
    placeAggregates.sort((a,b) => b.numberOfEvents.compareTo(a.numberOfEvents));
    _sortedByEvents = true;
    setState(() {

    });
    _scrollToTop();
  }
  void _sortByName() {
    placeAggregates.sort((a,b) => a.placeName.compareTo(b.placeName));
    _sortedByEvents = false;
    setState(() {

    });
    _scrollToTop();
  }
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.minScrollExtent;
      _scrollController.animateTo(
        position,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: Text('${widget.city.city}',style: GoogleFonts.secularOne(
            textStyle: Theme.of(context).textTheme.bodyLarge,
            fontWeight: FontWeight.w900),),
        actions: [
          IconButton(onPressed: (){
            _navigateToCityPlacesMap();
          }, icon: const Icon(Icons.location_on))
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16,),
                Row(
                  children: [
                     Text('Total Places', style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w300),),
                    const SizedBox(width: 8,),
                    Text('${placeAggregates.length}', style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                        fontWeight: FontWeight.w900),),
                  ],
                ),
                Row(
                  children: [
                    Text('Total Events', style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w300),),
                    const SizedBox(width: 8,),
                    Text(fm.format(events.length), style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                        fontWeight: FontWeight.w900),),
                  ],
                ),
                const SizedBox(height: 8,),
                Row(
                  children: [
                     Text('Data represents', style: GoogleFonts.lato(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        fontWeight: FontWeight.normal)),
                    const SizedBox(width: 8,),
                    Text('${widget.numberOfDays}', style: GoogleFonts.secularOne(
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                        fontWeight: FontWeight.w900),),
                    const SizedBox(width: 8,),
                     Text('days data', style: GoogleFonts.lato(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        fontWeight: FontWeight.normal)),
                  ],
                ),
                const SizedBox(height: 24,),
                Expanded(child: AnimatedBuilder(animation: _animationController,
                  builder: (BuildContext context, Widget? child) {
                  return FadeScaleTransition(animation: _animationController, child: child,);
                  },
                  child: ListView.builder(
                      itemCount: placeAggregates.length,
                      controller: _scrollController,
                      itemBuilder: (_, index){
                        var agg = placeAggregates.elementAt(index);
                        return GestureDetector(
                          onTap: _sort,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                   SizedBox(width: 48,
                                     child: Text(fm.format(agg.numberOfEvents), style: GoogleFonts.secularOne(
                                         textStyle: Theme.of(context).textTheme.bodyMedium,
                                         fontWeight: FontWeight.w900),),),
                                   SizedBox(width: 16, child: Text(Emoji.appleRed),),
                                   const SizedBox(width: 8,),
                                   Flexible(
                                     child: Text(agg.placeName, style: GoogleFonts.lato(
                                         textStyle: Theme.of(context).textTheme.bodySmall,
                                         fontWeight: FontWeight.normal),),
                                   ),

                                ],
                              ),
                            ),
                          ),
                        );
                  }),
                ),
                ),
              ],
            ),
          ),
          busy? Center(
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(width: 280,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children:  [
                         Text('Loading ...', style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal)),
                        const SizedBox(width: 16,),
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
                          strokeWidth: 4, backgroundColor: Colors.pink,
                        ),
                        ),
                        const SizedBox(width: 16,),
                         Text('Elapsed', style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal),),
                        const SizedBox(width: 4,),
                        Text('$elapsedSeconds',style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                            fontWeight: FontWeight.w900)),
                        const SizedBox(width: 4,),
                         Text('seconds',style: GoogleFonts.lato(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontWeight: FontWeight.normal)),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ): const SizedBox()
        ],
      ),
    ));
  }
  void _navigateToCityPlacesMap() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.scale,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 1000),
            child: CityPlacesMap(details: placeAggregates, city: widget.city)));
  }
}

class Details {
  late int numberOfEvents;
  late String placeId, placeName;
  late double latitude, longitude;

  Details({required this.numberOfEvents, required this.placeId,
    required this.latitude, required this.longitude,
    required this.placeName});
}
