// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DashboardDataAdapter extends TypeAdapter<DashboardData> {
  @override
  final int typeId = 0;

  @override
  DashboardData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DashboardData(
      events: fields[0] as int,
      cities: fields[1] as int,
      places: fields[2] as int,
      users: fields[3] as int,
      minutesAgo: fields[4] as int,
      amount: fields[5] as double,
      averageRating: fields[6] as double,
      date: fields[7] as String,
      longDate: fields[8] as int,
      elapsedSeconds: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DashboardData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.events)
      ..writeByte(1)
      ..write(obj.cities)
      ..writeByte(2)
      ..write(obj.places)
      ..writeByte(3)
      ..write(obj.users)
      ..writeByte(4)
      ..write(obj.minutesAgo)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.averageRating)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.longDate)
      ..writeByte(9)
      ..write(obj.elapsedSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
