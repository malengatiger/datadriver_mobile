class DashboardData {
  late int events;
  late int cities;
  late int places;
  late int users;
  late int minutesAgo;
  late double amount;
  late double averageRating;
  late String date;
  late int longDate;

/*
DashboardData {
    private long events, cities, places, users;
    private double amount, averageRating;
    private int minutesAgo;
    private long longDate;
    private String date; */
  DashboardData(
      {required this.events,
      required this.cities,
      required this.places,
      required this.users,
      required this.minutesAgo,
      required this.amount,
      required this.averageRating,
      required this.date,
      required this.longDate,});

  DashboardData.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    events = json['events'];
    cities = json['cities'];
    places = json['places'];
    users = json['users'];
    minutesAgo = json['minutesAgo'];
    longDate = json['longDate'];
    averageRating = json['averageRating'];
    date = json['date'];
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

      };
}
