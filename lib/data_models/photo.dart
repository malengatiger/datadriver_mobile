import 'package:hive/hive.dart';

part 'photo.g.dart';

@HiveType(typeId: 10)
class Photo {
   @HiveField(0)
   late int height;
   @HiveField(1)
   late List<String> html_attributions;
   @HiveField(2)
   late String photo_reference;
   @HiveField(3)
   late int width;
}