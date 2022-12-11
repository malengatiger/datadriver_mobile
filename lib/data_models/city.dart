import 'package:hive/hive.dart';

import '../utils/util.dart';

part 'city.g.dart';

@HiveType(typeId: 7)
class City {
  @HiveField(0)
  String? city;
  @HiveField(1)
  String? lat;
  @HiveField(2)
  String? lng;
  @HiveField(3)
  String? country;
  @HiveField(4)
  String? iso2;
  @HiveField(5)
  String? adminName;
  @HiveField(6)
  String? populationProper;
  @HiveField(7)
  String? capital;
  @HiveField(8)
  double? latitude;
  @HiveField(9)
  double? longitude;
  @HiveField(10)
  int? pop;
  @HiveField(11)
  String? id;
  City(
      {required this.id,
      required this.city,
      required this.country,
      required this.adminName,
      required this.lat,
      required this.lng,
      required this.latitude,
      required this.longitude,
      required this.pop,
      required this.populationProper,
      required this.capital});

  City.fromJson(Map<String, dynamic> map) {
    // p(map);
    lat = map['lat'];
    id = map['id'];
    city = map['city'];
    country = map['country'];
    latitude = map['latitude'];
    populationProper = map['populationProper'];
    lng = map['lng'];
    capital = map['capital'];
    latitude = map['latitude'];
    longitude = map['longitude'];
    pop = map['pop'];
    if (map['adminMame'] != null) {
      adminName = map['adminMame'];
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': lat,
        'id': id,
        'city': city,
        'country': country,
        'adminName': adminName,
        'latitude': latitude,
        'longitude': longitude,
        'pop': pop,
        'populationProper': populationProper,
        'lng': lng,
        'capital': capital,
      };
}
