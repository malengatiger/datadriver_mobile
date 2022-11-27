import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/data_models/event.dart';

import '../utils/emojis.dart';
import '../utils/util.dart';

abstract class EventRepository {
  Future<List<Event>> getEventsWithinMinutes({required int minutes});
  Future<List<Event>> getCityEventsWithinMinutes({required String cityId, required int minutes});
}

class MyEventRepository implements EventRepository {
  @override
  Future<List<Event>> getCityEventsWithinMinutes({required String cityId, required int minutes}) async {
    p('$blueDot $blueDot .... MyEventRepository getting Events in the last $minutes minutes from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <Event>[];
    var date = DateTime.now().subtract(Duration(minutes: minutes));
    var data = await db
        .collection("flatEvents")
        .where('cityId', isEqualTo: cityId)
        .where("longDate", isGreaterThanOrEqualTo: date.millisecondsSinceEpoch)
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

  @override
  Future<List<Event>> getEventsWithinMinutes({required int minutes}) async {
    p('$blueDot $blueDot .... MyEventRepository getting Events in the last $minutes minutes from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <Event>[];
    var date = DateTime.now().subtract(Duration(minutes: minutes));
    var data = await db
        .collection("flatEvents")
        .where("longDate", isGreaterThanOrEqualTo: date.millisecondsSinceEpoch)
        .orderBy('longDate', descending: true)
        .limit(100)
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
}

final eventProvider = Provider<MyEventRepository>((ref) => MyEventRepository());
