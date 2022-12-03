import 'location.dart';
import 'photo.dart';

/*
geometry
location
lat
-23.9179342
lng
29.440845
viewport
northeast
lat
-23.9165508197085
lng
29.4421410302915
southwest
lat
-23.9192487802915
lng
29.4394430697085
 */
class CityPlace {
  late String icon;
  late String name;
  late List<Photo> photos;
  late String placeId;
  late List<dynamic> types;
  late String vicinity;
  late String cityId;
  late String cityName;
  late String province;
  late Location location;

  CityPlace.fromJson(Map<String, dynamic> map) {
    icon = map['icon'];
    cityId = map['cityId'];
    cityName = map['cityName'];
    vicinity = map['vicinity'];
    placeId = map['place_id'];
    province = map['province'];
    name = map['name'];
    types = map['types'];
    location = Location.fromJson(map['geometry']['location']);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'icon': icon,
        'placeId': placeId,
        'cityId': cityId,
        'cityName': cityName,
        'province': province,
        'vicinity': vicinity,
        'name': name,
        'types': types,
        'location': location.toJson(),
      };
}
