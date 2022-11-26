class City {
  late String city;
  late String lat;
  late String lng;
  late String country;
  late String iso2;
  late String adminName;
  late String populationProper;
  late String capital;
  late double latitude;
  late double longitude;
  late int pop;
  late String id;
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
    lat = map['lat'];
    id = map['id'];
    city = map['city'];
    country = map['country'];
    adminName = map['admin_name'];
    latitude = map['latitude'];
    populationProper = map['population_proper'];
    lng = map['lng'];
    capital = map['capital'];
    latitude = map['latitude'];
    longitude = map['longitude'];
    pop = map['pop'];
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
