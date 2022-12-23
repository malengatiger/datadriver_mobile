import 'package:hive/hive.dart';
import 'package:universal_frontend/utils/emojis.dart';

import '../utils/util.dart';
part 'city_aggregate.g.dart';

@HiveType(typeId: 1)
class CityAggregate {
  @HiveField(0)
  double? averageRating;
  @HiveField(1)
  String? cityId;
  @HiveField(2)
  String? cityName;
  @HiveField(3)
  String? date;
  @HiveField(4)
  int? numberOfEvents;
  @HiveField(5)
  int? minutesAgo;
  @HiveField(6)
  double? totalSpent;
  @HiveField(7)
  int? longDate;
  @HiveField(8)
  double? latitude;
  @HiveField(9)
  double? longitude;
  @HiveField(10)
  double? elapsedSeconds;

  CityAggregate({
    required this.averageRating,
    required this.cityId,
    required this.cityName,
    required this.date,
    required this.numberOfEvents,
    required this.minutesAgo,
    required this.totalSpent,
    required this.longDate,
    required this.latitude,
    required this.longitude,
    required this.elapsedSeconds,
  });

  CityAggregate.fromJson(Map<String, dynamic> json) {

    try {
      if (json['minutesAgo'] != null) {
        minutesAgo = json['minutesAgo'];
      }
      if (json['elapsedSeconds'] != null) {
        elapsedSeconds = json['elapsedSeconds'];
      } else {
        elapsedSeconds = 0.0;
      }
      averageRating = 0.0;
      try {
        if (json['averageRating'] == double.nan) {
          p("${Emoji.redDot} avg rating is NaN: ${json['averageRating']}");
        }
        if (json['averageRating'] is double) {
          averageRating = json['averageRating'];
          //p("${Emoji.leaf} avg rating is COOL!: ${Emoji.leaf} averageRating: ${json['averageRating']}");
        }
      } catch (e) {
        p('${Emoji.redDot} ${Emoji.redDot} $e');
        p('${Emoji.redDot} ${Emoji.redDot} city aggregate json: check average rating $json');
      }
      cityId = json['cityId'];
      cityName = json['cityName'];
      date = json['date'];
      numberOfEvents = json['numberOfEvents'];
      totalSpent = json['totalSpent'];
      longDate = json['longDate'];
      latitude = json['latitude'];
      longitude = json['longitude'];

    } catch (e) {
      p(e);
      p('\n\n${Emoji.redDot}${Emoji.redDot} WHY DO WE FALL DOWN ??? json: $json');
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'minutesAgo': minutesAgo,
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
