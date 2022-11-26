class User {
  String? userId;
  String? cityId;
  String? cityName;
  String? firstName;
  String? lastName;
  String? middleInitial;
  String? dateRegistered;
  int? longDateRegistered;

  User(
      {required this.userId,
      required this.cityId,
      required this.cityName,
      required this.firstName,
      required this.lastName,
      required this.middleInitial,
      required this.dateRegistered,
      required this.longDateRegistered,
      });

  User.fromJson(Map<String, dynamic> json) {
    middleInitial = json['middleInitial'];
    userId = json['userId'];
    cityId = json['cityId'];
    cityName = json['cityName'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    dateRegistered = json['dateRegistered'];
    longDateRegistered = json['longDateRegistered'];

  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'middleInitial': middleInitial,
        'userId': userId,
        'cityId': cityId,
        'cityName': cityName,
        'firstName': firstName,
        'lastName': lastName,
        'longDateRegistered': longDateRegistered,
        'dateRegistered': dateRegistered,

      };
}
