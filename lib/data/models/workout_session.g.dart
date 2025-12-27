// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 0;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String,
      exerciseType: fields[1] as ExerciseType,
      targetReps: fields[2] as int,
      totalReps: fields[3] as int,
      correctReps: fields[4] as int,
      wrongReps: fields[5] as int,
      accuracy: fields[6] as double,
      startTime: fields[7] as DateTime,
      endTime: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseType)
      ..writeByte(2)
      ..write(obj.targetReps)
      ..writeByte(3)
      ..write(obj.totalReps)
      ..writeByte(4)
      ..write(obj.correctReps)
      ..writeByte(5)
      ..write(obj.wrongReps)
      ..writeByte(6)
      ..write(obj.accuracy)
      ..writeByte(7)
      ..write(obj.startTime)
      ..writeByte(8)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
