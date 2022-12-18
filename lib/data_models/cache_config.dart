import 'package:hive/hive.dart';

part 'cache_config.g.dart';

@HiveType(typeId: 15)
class CacheConfig {
  @HiveField(0)
  late int longDate;
  @HiveField(1)
  late String stringDate;
  @HiveField(2)
  late double elapsedSeconds;

  CacheConfig(
      {required this.longDate,
      required this.stringDate,
      required this.elapsedSeconds});

  CacheConfig.fromJson(Map<String, dynamic> json) {
    longDate = json['longDate'];
    stringDate = json['stringDate'];
    longDate = json['longDate'];

    if (json['elapsedSeconds'] != null) {
      elapsedSeconds = json['elapsedSeconds'];
    }

  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'longDate': longDate,
        'stringDate': stringDate,
        'elapsedSeconds': elapsedSeconds,
      };
}
