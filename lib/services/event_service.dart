import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data_models/event.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

class EventService extends AsyncNotifier {
  late FirebaseFirestore db;
  var events = <Event>[];

  initialize() {
    db = FirebaseFirestore.instance;
    p("$appleGreen  $appleGreen $appleGreen FirebaseFirestore.instance: "
        "${db.app.name} $appleRed EventService initialized, "
        "FirebaseFirestore instance created ");
  }

  void getEventsWithinMinutes({required int minutes}) async {
    state = (await _getEvents(minutes: minutes)) as AsyncValue;
  }

  Future<List<Event>> _getEvents({required int minutes}) async {
    p('$blueDot $blueDot .... EventService getting Events in the last $minutes minutes from Firestore ..');
    db = FirebaseFirestore.instance;
    var date = DateTime.now().subtract(Duration(minutes: minutes));
    var data =
        await db.collection("flatEvents").where("longDate", isGreaterThanOrEqualTo: date.millisecondsSinceEpoch).get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      // p('$DIAMOND Event Json: $mJson');
      var event = Event.fromJson(mJson);
      events.add(event);
    }
    p('$leaf $leaf $leaf Found ${events.length} events on Firestore $leaf ${DateTime.now()}');
    return events;
  }

  @override
  FutureOr build() {
    // TODO: implement build
    throw UnimplementedError();
  }
}
