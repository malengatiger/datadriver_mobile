import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data_models/city.dart';
import '../data_models/city_place.dart';
import '../data_models/event.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';

class DataService {
  init() {
    var db = FirebaseFirestore.instance;
    p("$appleGreen  $appleGreen $appleGreen FirebaseFirestore.instance: "
        "${db.app
        .name} $appleRed DataService constructed, FirebaseFirestore instance created ");
  }

  DataService() {
    init();
    listenForAuth();
  }

  static void listenForAuth() {
    p('$heartBlue DataService: Firebase listenForAuth ...');

    FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user == null) {
        p('$redDot User is currently signed out! ');
        var m = await signInAnonymously();
        p(
            '$heartGreen $heartGreen $heartGreen user signed in with signInAnonymously');
      } else {
        var msg = '$appleGreen User is signed in! ';
        if (user.email == null) {
          p('$msg - anonymous user');
        } else {
          p('$msg 🍎 user: ${user.email}');
        }
      }
    });
  }

  static Future signInAnonymously() async {
    try {
      p('$appleGreen $appleGreen Firebase signInAnonymously started ...');
      var cred = await FirebaseAuth.instance.signInAnonymously();
      p('$redDot Signed in anonymously, $heartBlue cred:  $cred');
      // var m = await getEvents(minutes: 120);
      // p('$heartOrange events after signin: ${m.length}');
      return cred;
    } catch (e) {
      p('$redDot Unable to sign in: $e');
    }
  }

  static Future signIn(
      {required String email, required String password}) async {
    try {
      var cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      return cred;
    } catch (e) {
      p('$redDot Unable to sign in');
    }
  }

  static void signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      p('$redDot Unable to sign OUT');
    }
  }

  static Future<String> createUser() async {
    if (FirebaseAuth.instance.currentUser != null) {
      var email = getEmail();
      var pass = getPassword();
      if (email != null && pass != null) {
        var cred = await signIn(email: email, password: pass);
        p('User signed in $cred');
      } else {
        var msg = '$redDot $redDot Email and password not found in prefs';
        p(msg);
        return msg;
      }
    }
    String email = 'myemail${DateTime
        .now()
        .millisecondsSinceEpoch}@email.com';
    String password = 'datawarrior';

    try {
      var userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password);
      p(userCred);
      p('$heartGreen User created, will now sign in ... : ${userCred.user
          ?.email}');
      var xx = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      p(xx);
      p('$heartGreen User has signed in OK: ${xx.user?.email}');
      setEmail(email);
      setPassword(password);
      p('$heartGreen email and password saved in Prefs: ${userCred.user
          ?.email}');
      return email;
    } catch (e) {
      p(e);
      p('$redDot $redDot Error creating User $e');
      throw Exception('$redDot User could not be created: $e');
    }
  }

  static Future<List<Event>> getEvents({required int minutes}) async {
    p(
        '$blueDot $blueDot .... DataService getting Events in the last $minutes minutes from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <Event>[];
    var date = DateTime.now().subtract(Duration(minutes: minutes));
    var data =
    await db.collection("events")
        .where("longDate", isGreaterThanOrEqualTo: date.millisecondsSinceEpoch)
        .get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      var event = Event.fromJson(mJson);
      list.add(event);
    }
    p('$leaf $leaf $leaf Found ${list.length} '
        'events on Firestore $leaf ${DateTime.now()}');
    return list;
  }

  static Future<List<Event>> getCityEvents(
      {required String cityId, required int minutes}) async {
    p('$blueDot $blueDot .... DataService getting City Events '
        'in the last $minutes minutes from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <Event>[];
    var date = DateTime.now().subtract(Duration(minutes: minutes));
    var data =
    await db.collection("events")
        .where('cityId', isEqualTo: cityId)
        .where("longDate", isGreaterThanOrEqualTo: date.millisecondsSinceEpoch)
        .orderBy('longDate', descending: true)
        .get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      var event = Event.fromJson(mJson);
      list.add(event);
    }
    p('$leaf $leaf $leaf Found ${list.length} '
        'city events on Firestore $leaf ${DateTime.now()}');
    return list;
  }

  static Future<List<CityPlace>> getCityPlaces({required String cityId}) async {
    p(
        '$blueDot $blueDot .... DataService getting City places from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <CityPlace>[];
    var data =
    await db.collection("cityPlaces")
        .where('cityId', isEqualTo: cityId)
        .orderBy('name')
        .get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      var event = CityPlace.fromJson(mJson);
      list.add(event);
    }
    p('$leaf $leaf $leaf Found ${list.length} '
        'city places on Firestore $leaf ${DateTime.now()}');
    return list;
  }

  static Future<List<City>> getCities() async {
    p('$blueDot $blueDot .... DataService getting Cities from Firestore ..');
    var db = FirebaseFirestore.instance;
    var list = <City>[];
    var data = await db.collection("cities").orderBy('city').get();
    for (var doc in data.docs) {
      var mJson = doc.data();
      // p('$DIAMOND Event Json: $mJson');
      var city = City.fromJson(mJson);
      list.add(city);
    }
    p('$leaf $leaf $leaf Found ${list
        .length} cities on Firestore $leaf ${DateTime.now()}');
    return list;
  }

  static Future<City?> getCity({required String cityId}) async {
    p('$blueDot $blueDot .... DataService getting City from Firestore ..');
    City? city;
    var db = FirebaseFirestore.instance;
    var data = await db.collection("cities")
        .where('id', isEqualTo: cityId)
        .get();

    for (var doc in data.docs) {
      var mJson = doc.data();
      city = City.fromJson(mJson);
    }
    if (city != null) {
      p('$leaf $leaf $redDot Found city ${city
          .city} on Firestore $redDot ${DateTime
          .now()}');
      p(city.toJson());
    }
    return city;
  }

  static Future<int> getEventCount() async {
    p('$heartBlue .... DataService getting Total Events from Firestore ..');
    var db = FirebaseFirestore.instance;

    var count = db.collection('events').count();
    var m = await count.get();
    p('$heartBlue $heartBlue  $heartBlue There are ${m
        .count} events in the Firestore collection  $heartBlue');
    return m.count;
  }

  static Future<EventBag> getPaginatedEvents({
    required String cityId,
    required int days, required int limit, DocumentSnapshot? lastDocument}) async {
    var db = FirebaseFirestore.instance;
    p('${Emoji.blueDot}${Emoji.blueDot} getPaginatedEvents ...');
    DateTime dt = DateTime.now().subtract(Duration(days: days));
    late QuerySnapshot<Map<String,dynamic>> querySnapshot;
    if (lastDocument == null) {
      querySnapshot = await db
          .collection('events')
          .where("cityId", isEqualTo: cityId)
          .where("longDate", isGreaterThanOrEqualTo: dt.millisecondsSinceEpoch)
          .orderBy('longDate', descending: true)
          .limit(limit)
          .get();
    } else {
      querySnapshot = await db
          .collection('events')
          .where("longDate", isGreaterThanOrEqualTo: dt.millisecondsSinceEpoch)
          .orderBy('longDate', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();
    }

    var list = <Event>[];
    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];
      p('${Emoji.blueDot}${Emoji.blueDot} Found ${querySnapshot.docs
          .length} events in querySnapshot in the last $days days');


      for (var doc in querySnapshot.docs) {
        var mJson = doc.data();
        var m = Event.fromJson(mJson);
        list.add(m);
      }
      p('${Emoji.blueDot}${Emoji.blueDot} Found ${list
          .length} events in the last $days days');
      p('${Emoji.blueDot}${Emoji.blueDot} Last document id: ${lastDocument
          .id}');
    }

      var bag = EventBag(list, lastDocument);

    return bag;
  }

}

class EventBag {
  late List<Event> events;
  late DocumentSnapshot? lastDocument;

  EventBag(this.events, this.lastDocument);
}

