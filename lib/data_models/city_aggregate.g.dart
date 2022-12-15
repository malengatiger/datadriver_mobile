// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_aggregate.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CityAggregateAdapter extends TypeAdapter<CityAggregate> {
  @override
  final int typeId = 1;

  @override
  CityAggregate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CityAggregate(
      averageRating: fields[0] as double,
      cityId: fields[1] as String,
      cityName: fields[2] as String,
      date: fields[3] as String,
      numberOfEvents: fields[4] as int,
      minutesAgo: fields[5] as int,
      totalSpent: fields[6] as double,
      longDate: fields[7] as int,
      latitude: fields[8] as double,
      longitude: fields[9] as double,
      elapsedSeconds: fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CityAggregate obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.averageRating)
      ..writeByte(1)
      ..write(obj.cityId)
      ..writeByte(2)
      ..write(obj.cityName)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.numberOfEvents)
      ..writeByte(5)
      ..write(obj.minutesAgo)
      ..writeByte(6)
      ..write(obj.totalSpent)
      ..writeByte(7)
      ..write(obj.longDate)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.elapsedSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityAggregateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
