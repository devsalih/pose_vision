// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rep_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepRecordAdapter extends TypeAdapter<RepRecord> {
  @override
  final int typeId = 1;

  @override
  RepRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepRecord(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      exerciseType: fields[3] as ExerciseType,
      isValid: fields[4] as bool,
      faults: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, RepRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.exerciseType)
      ..writeByte(4)
      ..write(obj.isValid)
      ..writeByte(5)
      ..write(obj.faults);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
