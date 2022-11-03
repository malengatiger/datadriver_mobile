class Event {
  String? eventId;
  String? cityId;
  String? cityName;
  String? placeId;
  String? placeName;
  double? amount;
  int? rating;
  double? latitude;
  double? longitude;
  String? date;
  int? longDate;
  String? types;
  String? vicinity;

  Event(
      {required this.eventId,
      required this.cityId,
      required this.cityName,
      required this.placeId,
      required this.placeName,
      required this.amount,
      required this.rating,
      required this.latitude,
      required this.longitude,
      required this.date,
      required this.longDate,
      required this.types,
      required this.vicinity});

  Event.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    eventId = json['eventId'];
    cityId = json['cityId'];
    cityName = json['cityName'];
    placeId = json['placeId'];
    placeName = json['placeName'];
    longDate = json['longDate'];
    rating = json['rating'];
    types = json['types'];
    vicinity = json['vicinity'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amount': amount,
        'eventId': eventId,
        'cityId': cityId,
        'cityName': cityName,
        'placeId': placeId,
        'placeName': placeName,
        'latitude': latitude,
        'longitude': longitude,
        'date': date,
        'longDate': longDate,
        'rating': rating,
        'types': types,
        'vicinity': vicinity,
      };
}
