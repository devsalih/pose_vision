import 'package:hive/hive.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

part 'workout_session.g.dart';

// Persistent summary of a completed workout session.
@HiveType(typeId: 0)
class WorkoutSession {
  @HiveField(0)
  final String id;

  // Exercise performed during this session.
  @HiveField(1)
  final ExerciseType exerciseType;

  // Target repetition count selected at session start.
  @HiveField(2)
  final int targetReps;

  // Total repetitions detected during the session.
  @HiveField(3)
  final int totalReps;

  // Repetitions completed without any faults.
  @HiveField(4)
  final int correctReps;

  // Repetitions completed with at least one fault.
  @HiveField(5)
  final int wrongReps;

  // Accuracy percentage captured at session end.
  @HiveField(6)
  final double accuracy;

  // Timestamp when the session started.
  @HiveField(7)
  final DateTime startTime;

  // Timestamp when the session ended.
  @HiveField(8)
  final DateTime endTime;

  WorkoutSession({
    required this.id,
    required this.exerciseType,
    required this.targetReps,
    required this.totalReps,
    required this.correctReps,
    required this.wrongReps,
    required this.accuracy,
    required this.startTime,
    required this.endTime,
  });
}
