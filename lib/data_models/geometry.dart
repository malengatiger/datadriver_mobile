import 'package:hive/hive.dart';

import 'location.dart';

// part 'geometry.g.dart';
part 'geometry.g.dart';

@HiveType(typeId: 12)
class Geometry {
  @HiveField(0)
  Location? location;


  Geometry({
    required this.location,
  });

  Geometry.fromJson(Map<String, dynamic> json) {

    if (json['location'] != null) {
      location = Location.fromJson(json['location']);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'location': location == null? null:location!.toJson(),
      };
}
