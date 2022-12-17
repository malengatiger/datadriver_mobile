import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_frontend/data_models/city_place.dart';
import 'package:universal_frontend/data_models/event.dart';

import '../data_models/city.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

abstract class AbstractDataRepository {
  Future<List<City>> getCities();
  Future<int> countCities();
  Future<int> countPlaces();
  Future<int> countUsers();
  Future<List<CityPlace>> getPlaces();
  Future<List<Event>> getEventsWithinMinutes({required int minutes});
  Future<List<Event>> getCityEventsWithinMinutes({required String cityId, required int minutes});
}

class DataRepository implements AbstractDataRepository {
  @override
  Future<List<Event>> getCityEventsWithinMinutes({required String cityId, required int minutes}) async {
    p('$blueDot $blueDot .... DataRepository getting Events in the last $minutes minutes from Firestore ..');
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
    p('$blueDot $blueDot .... DataRepository getting Events in the last $minutes minutes from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <Event>[];
    var date = DateTime.now().subtract(Duration(minutes: minutes));
    var data = await db
        .collection("flatEvents")
        .where("longDate", isGreaterThanOrEqualTo: date.millisecondsSinceEpoch)
        .orderBy('longDate', descending: true)
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
  Future<List<City>> getCities() async {
    p('$blueDot $blueDot .... DataRepository getting all Cities from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <City>[];
    var data = await db.collection("cities").orderBy('city', descending: false).get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      var city = City.fromJson(mJson);
      list.add(city);
    }
    p('$leaf $leaf $leaf Found ${list.length} cities on Firestore $leaf ${DateTime.now()}');
    return list;
  }

  @override
  Future<List<CityPlace>> getPlaces() async {
    p('$blueDot $blueDot .... DataRepository getting CityPlaces from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <CityPlace>[];
    var data = await db.collection("cityPlaces").orderBy('name', descending: false).get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      // p('$DIAMOND Event Json: $mJson');
      var event = CityPlace.fromJson(mJson);
      list.add(event);
    }
    p('$leaf $leaf $leaf Found ${list.length} places on Firestore $leaf ${DateTime.now()}');
    return list;
  }

  @override
  Future<int> countCities() async {
    p('$blueDot $blueDot .... DataRepository counting Cities from Firestore ..');
    var count = 0;
    try {
      var db = FirebaseFirestore.instance;
      var aggregateQuerySnapshot = await db.collection("cities").count().get();
      count = aggregateQuerySnapshot.count;
      p('$leaf $leaf $leaf Counted $count cities on Firestore $leaf ${DateTime
          .now()}');
    } catch (e) {
      p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot}');
      p(e);
      p('${Emoji.redDot} ${Emoji.redDot} ${Emoji.redDot}');
    }
    return count;
  }

  @override
  Future<int> countPlaces() async {
    p('$blueDot $blueDot .... DataRepository counting places from Firestore ..');
    var db = FirebaseFirestore.instance;
    var aggregateQuerySnapshot = await db.collection("cityPlaces").count().get();
    var count = aggregateQuerySnapshot.count;

    p('$leaf $leaf $leaf Counted $count places on Firestore $leaf ${DateTime.now()}');
    return count;
  }

  @override
  Future<int> countUsers() async {
    p('$blueDot $blueDot .... DataRepository counting users from Firestore ..');
    var db = FirebaseFirestore.instance;
    var aggregateQuerySnapshot = await db.collection("users").count().get();
    var count = aggregateQuerySnapshot.count;

    p('$leaf $leaf $leaf Counted $count users on Firestore $leaf ${DateTime.now()}');
    return count;
  }
}

final dataProvider = Provider<DataRepository>((ref) => DataRepository());
