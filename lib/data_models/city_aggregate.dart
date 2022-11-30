class CityAggregate {
  late double averageRating;
  late String cityId;
  late String cityName;
  late String date;
  late int numberOfEvents;
  late int hours;
  late double totalSpent;
  late int longDate;
  late double latitude, longitude;

  CityAggregate({
    required this.averageRating,
    required this.cityId,
    required this.cityName,
    required this.date,
    required this.numberOfEvents,
    required this.hours,
    required this.totalSpent,
    required this.longDate,
    required this.latitude,
    required this.longitude,
  });

  CityAggregate.fromJson(Map<String, dynamic> json) {
    hours = json['hours'];
    averageRating = json['averageRating'];
    cityId = json['cityId'];
    cityName = json['cityName'];
    date = json['date'];
    numberOfEvents = json['numberOfEvents'];
    totalSpent = json['totalSpent'];
    longDate = json['longDate'];
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'hours': hours,
        'averageRating': averageRating,
        'cityId': cityId,
        'cityName': cityName,
        'date': date,
        'numberOfEvents': numberOfEvents,
        'longDate': longDate,
        'totalSpent': totalSpent,
        'latitude': latitude,
        'longitude': longitude,
      };
}
