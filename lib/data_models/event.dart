import 'package:hive/hive.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../utils/util.dart';

part 'event.g.dart';

@HiveType(typeId: 5)
class Event {
  @HiveField(0)
  late String eventId;
  @HiveField(1)
  late String cityId;
  @HiveField(2)
  late String cityName;
  @HiveField(3)
  late String placeId;
  @HiveField(4)
  late String placeName;
  @HiveField(5)
  late double amount;
  @HiveField(6)
  late int rating;
  @HiveField(7)
  late double latitude;
  @HiveField(8)
  late double longitude;
  @HiveField(9)
  late String date;

  @HiveField(10)
  late String types;
  @HiveField(11)
  late String vicinity;
  @HiveField(12)
  late String userId;
  @HiveField(13)
  late String firstName;
  @HiveField(14)
  late String lastName;
  @HiveField(15)
  late String middleInitial;
  @HiveField(16)
  late int longDate;

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
      required this.vicinity,
      required this.firstName,
      required this.lastName,
      required this.middleInitial,
      required this.userId});

  Event.fromJson(Map<String, dynamic> json) {
    // p(json);
    if (json['amount'] == null) {
      p('${Emoji.appleRed} ---------- amount is null, wtf?  cityId: ${json['cityId']} city: ${json['cityName']}');
      p(json);
    } else {
      amount = json['amount'];
    }
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
    userId = json['userId'];
    firstName = json['firstName'];
    middleInitial = json['middleInitial'];
    lastName = json['lastName'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amount': amount,
        'lastName': lastName,
        'middleInitial': middleInitial,
        'firstName': firstName,
        'userId': userId,
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
