// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_place.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CityPlaceAdapter extends TypeAdapter<CityPlace> {
  @override
  final int typeId = 8;

  @override
  CityPlace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CityPlace(
      fields[0] as String?,
      fields[1] as String?,
      (fields[2] as List?)?.cast<Photo>(),
      fields[3] as String?,
      (fields[4] as List?)?.cast<dynamic>(),
      fields[5] as String?,
      fields[6] as String?,
      fields[7] as String?,
      fields[8] as String?,
      fields[9] as Geometry?,
    );
  }

  @override
  void write(BinaryWriter writer, CityPlace obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.icon)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.photos)
      ..writeByte(3)
      ..write(obj.placeId)
      ..writeByte(4)
      ..write(obj.types)
      ..writeByte(5)
      ..write(obj.vicinity)
      ..writeByte(6)
      ..write(obj.cityId)
      ..writeByte(7)
      ..write(obj.cityName)
      ..writeByte(8)
      ..write(obj.province)
      ..writeByte(9)
      ..write(obj.geometry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityPlaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
