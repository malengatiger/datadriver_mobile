import 'package:hive/hive.dart';
import '../utils/emojis.dart';
import '../utils/util.dart';
import 'geometry.dart';
import 'photo.dart';
part 'city_place.g.dart';

@HiveType(typeId: 8)
class CityPlace {
  @HiveField(0)
  String? icon;
  @HiveField(1)
  String? name;
  @HiveField(2)
  List<Photo>? photos;
  @HiveField(3)
  String? placeId;
  @HiveField(4)
  List<dynamic>? types;
  @HiveField(5)
  String? vicinity;
  @HiveField(6)
  String? cityId;
  @HiveField(7)
  String? cityName;
  @HiveField(8)
  String? province;
  @HiveField(9)
  Geometry? geometry;

  CityPlace(this.icon, this.name, this.photos, this.placeId, this.types,
      this.vicinity, this.cityId, this.cityName, this.province, this.geometry);

  CityPlace.fromJson(Map<String, dynamic> map) {
    // p("🧡🧡🧡🧡🧡🧡 cityPlace, look for placeId ... $map");
    icon = map['icon'];
    cityId = map['cityId'];
    cityName = map['cityName'];
    vicinity = map['vicinity'];
    province = map['province'];
    name = map['name'];
    types = map['types'];
    if (map['geometry'] != null) {
      geometry = Geometry.fromJson(map['geometry']);
    } else {
      p("${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}"
          " cityPlace fromJson, geometry is null! wtf?: "
          "${Emoji.redDot} $name - $cityName");
    }
    if (map['placeId'] != null) {
      placeId = map['placeId'];
      // p("${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}${Emoji.appleGreen}"
      //     " cityPlace fromJson, placeId is NOT null");
    }
    if (map['place_id'] != null) {
      placeId = map['place_id'];
    }
    if (placeId == null) {
      p("${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}${Emoji.redDot}"
          " cityPlace fromJson, placeId is null");
    }
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
        'geometry': geometry == null? null: geometry!.toJson(),
      };
}
