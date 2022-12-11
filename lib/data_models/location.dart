import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 9)
class Location {
  @HiveField(0)
  double? latitude;
  @HiveField(1)
  double? longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  Location.fromJson(Map<String, dynamic> json) {
    latitude = json['lat'];
    longitude = json['lng'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
      };
}
