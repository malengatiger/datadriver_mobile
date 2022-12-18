import 'dart:collection';
import 'dart:convert';

import 'package:universal_frontend/data_models/city_aggregate.dart';
import 'package:universal_frontend/data_models/city_place.dart';
import 'package:universal_frontend/data_models/dashboard_data.dart';
import 'package:universal_frontend/data_models/event.dart';
import 'package:universal_frontend/data_models/city.dart';


class CacheBag {
  late String date;
  late double elapsedSeconds;
  late List<City> cities;
  late List<CityPlace> places;
  late List<DashboardData> dashboards;
  late List<CityAggregate> aggregates;
  late List<Event> events;


  CacheBag(
      {required this.cities,
      required this.date,
      required this.elapsedSeconds,
      required this.places,
      required this.dashboards,
      required this.aggregates,
      required this.events});

  CacheBag.fromJson(Map<String, dynamic> json) {
    cities = [];
    if (json['cities']!= null) {
      List list = json['cities'];
      for (var value in list) {
        cities.add(City.fromJson(value));
      }
    }

    dashboards = [];
    if (json['dashboards']!= null) {
      List list = json['dashboards'];
      for (var value in list) {
        dashboards.add(DashboardData.fromJson(value));
      }
    }
    aggregates = [];
    if (json['aggregates']!= null) {
      List list = json['aggregates'];
      for (var value in list) {
        aggregates.add(CityAggregate.fromJson(value));
      }
    }
    events = [];
    if (json['events']!= null) {
      List list = json['events'];
      for (var value in list) {
        events.add(Event.fromJson(value));
      }
    }

    date = json['date'];
    if (json['elapsedSeconds'] != null) {
      elapsedSeconds = json['elapsedSeconds'];
    }
    places = [];
    if (json['places']!= null) {
      List list = json['places'];
      for (var value in list) {
        places.add(CityPlace.fromJson(value));
      }
    }

  }

  Map<String, dynamic> toJson() {
       var mainMap = <String,dynamic>{};
       var citiesList = <dynamic>[];
       for (var value in cities) {
         citiesList.add(value.toJson());
       }
       var dashList = <dynamic>[];
       for (var value in dashboards) {
         dashList.add(value.toJson());
       }
       var aggList = <dynamic>[];
       for (var value in aggregates) {
         aggList.add(value.toJson());
       }
       var placesList = <dynamic>[];
       for (var value in places) {
         placesList.add(value.toJson());
       }
       var eventsList = <dynamic>[];
       for (var value in events) {
         eventsList.add(value.toJson());
       }

       mainMap['date'] =  date;
       mainMap['elapsedSeconds'] =  elapsedSeconds;
       mainMap['aggregates'] = aggList;
       mainMap['events'] = eventsList;
       mainMap['dashboards'] = dashList;
       mainMap['places'] = placesList;
       mainMap['cities'] = citiesList;

    return mainMap;
      }
}
