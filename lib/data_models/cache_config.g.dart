// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheConfigAdapter extends TypeAdapter<CacheConfig> {
  @override
  final int typeId = 15;

  @override
  CacheConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheConfig(
      longDate: fields[0] as int,
      stringDate: fields[1] as String,
      elapsedSeconds: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CacheConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.longDate)
      ..writeByte(1)
      ..write(obj.stringDate)
      ..writeByte(2)
      ..write(obj.elapsedSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
