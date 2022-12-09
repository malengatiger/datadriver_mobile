import 'package:hive/hive.dart';
part 'city_aggregate.g.dart';

@HiveType(typeId: 1)
class CityAggregate {
  @HiveField(0)
  late double averageRating;
  @HiveField(1)
  late String cityId;
  @HiveField(2)
  late String cityName;
  @HiveField(3)
  late String date;
  @HiveField(4)
  late int numberOfEvents;
  @HiveField(5)
  late int hours;
  @HiveField(6)
  late double totalSpent;
  @HiveField(7)
  late int longDate;
  @HiveField(8)
  late double latitude;
  @HiveField(9)
  late double longitude;

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
/*
@HiveType(typeId: 0)
class Person extends HiveObject {

  @HiveField(0)
  String name;

  @HiveField(1)
  int age;
}
 */