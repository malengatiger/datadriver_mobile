class Location {
  double? latitude;
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
