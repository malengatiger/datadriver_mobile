// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 5;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      eventId: fields[0] as String,
      cityId: fields[1] as String,
      cityName: fields[2] as String,
      placeId: fields[3] as String,
      placeName: fields[4] as String,
      amount: fields[5] as double,
      rating: fields[6] as int,
      latitude: fields[7] as double,
      longitude: fields[8] as double,
      date: fields[9] as String,
      longDate: fields[16] as int,
      types: fields[10] as String,
      vicinity: fields[11] as String,
      firstName: fields[13] as String,
      lastName: fields[14] as String,
      middleInitial: fields[15] as String,
      userId: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.cityId)
      ..writeByte(2)
      ..write(obj.cityName)
      ..writeByte(3)
      ..write(obj.placeId)
      ..writeByte(4)
      ..write(obj.placeName)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.types)
      ..writeByte(11)
      ..write(obj.vicinity)
      ..writeByte(12)
      ..write(obj.userId)
      ..writeByte(13)
      ..write(obj.firstName)
      ..writeByte(14)
      ..write(obj.lastName)
      ..writeByte(15)
      ..write(obj.middleInitial)
      ..writeByte(16)
      ..write(obj.longDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
