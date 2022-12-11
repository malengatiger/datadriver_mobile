// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_bag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventBagAdapter extends TypeAdapter<EventBag> {
  @override
  final int typeId = 6;

  @override
  EventBag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventBag(
      list: (fields[0] as List).cast<Event>(),
      date: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EventBag obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.list)
      ..writeByte(1)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
