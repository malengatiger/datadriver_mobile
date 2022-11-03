import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datadriver_mobile/emojis.dart';
import 'package:datadriver_mobile/services/util.dart';

import '../data_models/event.dart';

class DataService {

  late FirebaseFirestore db;
  init() {
   db = FirebaseFirestore.instance;
   p("$appleGreen  $appleGreen $appleGreen FirebaseFirestore.instance: "
       "${db.app.name} $appleRed DataService constructed, FirebaseFirestore instance created ");
  }

  DataService() {
    init();
  }
  Future<List<Event>>  getEvents({required int minutes})  async {
    p('$blueDot $blueDot .... DataService getting Events in the last $minutes minutes from Firestore ..');
    var list = <Event>[];
    var date = DateTime.now().subtract(Duration(minutes: minutes));
    var data = await db.collection("events")
        .where("longDate", isGreaterThanOrEqualTo: date.millisecondsSinceEpoch )
        .get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      // p('$DIAMOND Event Json: $mJson');
      var event = Event.fromJson(mJson);
      list.add(event);
    }
    p('$leaf $leaf $leaf Found ${list.length} events on Firestore $leaf ${DateTime.now()}');
    return list;
  }

  Future<int> getEventCount() async {
    var count = db.collection('events').count();
    var m = await count.get();
    p(' $heartBlue There are ${m.count} events in the Firestore collection  $heartBlue');
    return m.count;
  }
}