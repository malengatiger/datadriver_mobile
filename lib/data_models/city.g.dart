// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CityAdapter extends TypeAdapter<City> {
  @override
  final int typeId = 7;

  @override
  City read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return City(
      id: fields[11] as String?,
      city: fields[0] as String?,
      country: fields[3] as String?,
      adminName: fields[5] as String?,
      lat: fields[1] as String?,
      lng: fields[2] as String?,
      latitude: fields[8] as double?,
      longitude: fields[9] as double?,
      pop: fields[10] as int?,
      populationProper: fields[6] as String?,
      capital: fields[7] as String?,
    )..iso2 = fields[4] as String?;
  }

  @override
  void write(BinaryWriter writer, City obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.city)
      ..writeByte(1)
      ..write(obj.lat)
      ..writeByte(2)
      ..write(obj.lng)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.iso2)
      ..writeByte(5)
      ..write(obj.adminName)
      ..writeByte(6)
      ..write(obj.populationProper)
      ..writeByte(7)
      ..write(obj.capital)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.pop)
      ..writeByte(11)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
