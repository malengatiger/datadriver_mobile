class CityAggregate {
  double? averageRating;
  String? cityId;
  String? cityName;
  String? date;
  int? numberOfEvents;
  int? hours;
  double? totalSpent;
  int? longDate;

  CityAggregate({
    required this.averageRating,
    required this.cityId,
    required this.cityName,
    required this.date,
    required this.numberOfEvents,
    required this.hours,
    required this.totalSpent,
    required this.longDate,
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
      };
}
