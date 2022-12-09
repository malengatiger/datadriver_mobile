// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aggregate_bag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AggregateBagAdapter extends TypeAdapter<AggregateBag> {
  @override
  final int typeId = 3;

  @override
  AggregateBag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AggregateBag(
      list: (fields[0] as List).cast<CityAggregate>(),
      date: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AggregateBag obj) {
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
      other is AggregateBagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
