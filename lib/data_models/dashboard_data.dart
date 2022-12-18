import 'package:hive/hive.dart';

part 'dashboard_data.g.dart';

@HiveType(typeId: 0)
class DashboardData {
  @HiveField(0)
  late int events;
  @HiveField(1)
  late int cities;
  @HiveField(2)
  late int places;
  @HiveField(3)
  late int users;
  @HiveField(4)
  late int minutesAgo;
  @HiveField(5)
  late double amount;
  @HiveField(6)
  late double averageRating;
  @HiveField(7)
  late String date;
  @HiveField(8)
  late int longDate;
  @HiveField(9)
  late double elapsedSeconds;

  DashboardData(
      {required this.events,
      required this.cities,
      required this.places,
      required this.users,
      required this.minutesAgo,
      required this.amount,
      required this.averageRating,
      required this.date,
      required this.longDate,
      required this.elapsedSeconds});

  DashboardData.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    events = json['events'];
    cities = json['cities'];
    places = json['places'];
    users = json['users'];
    if (json['minutesAgo'] != null) {
      minutesAgo = json['minutesAgo'];
    }

    longDate = json['longDate'];
    averageRating = json['averageRating'];
    date = json['date'];
    if (json['elapsedSeconds'] != null) {
      elapsedSeconds = json['elapsedSeconds'];
    }

  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'amount': amount,
        'events': events,
        'cities': cities,
        'places': places,
        'users': users,
        'minutesAgo': minutesAgo,
        'averageRating': averageRating,
        'date': date,
        'longDate': longDate,
        'elapsedSeconds': elapsedSeconds,
      };
}
