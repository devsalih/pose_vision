import 'package:equatable/equatable.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

class WorkoutInProgress extends WorkoutState {
  final ExerciseType exerciseType;
  final int targetReps;
  final int currentReps;
  final int correctReps;
  final int wrongReps;
  final List<String> currentFaults;
  final Pose? pose;
  final bool? lastRepIsCorrect;
  final DateTime? lastRepTimestamp;

  const WorkoutInProgress({
    required this.exerciseType,
    required this.targetReps,
    required this.currentReps,
    required this.correctReps,
    required this.wrongReps,
    required this.currentFaults,
    this.pose,
    this.lastRepIsCorrect,
    this.lastRepTimestamp,
  });

  @override
  List<Object?> get props => [
        exerciseType,
        targetReps,
        currentReps,
        correctReps,
        wrongReps,
        currentFaults,
        pose,
        lastRepIsCorrect,
        lastRepTimestamp,
      ];

  // Used to update live workout data while keeping the state immutable.
  WorkoutInProgress copyWith({
    ExerciseType? exerciseType,
    int? targetReps,
    int? currentReps,
    int? correctReps,
    int? wrongReps,
    List<String>? currentFaults,
    Pose? pose,
    bool? lastRepIsCorrect,
    DateTime? lastRepTimestamp,
    bool clearLastRep = false,
  }) {
    return WorkoutInProgress(
      exerciseType: exerciseType ?? this.exerciseType,
      targetReps: targetReps ?? this.targetReps,
      currentReps: currentReps ?? this.currentReps,
      correctReps: correctReps ?? this.correctReps,
      wrongReps: wrongReps ?? this.wrongReps,
      currentFaults: currentFaults ?? this.currentFaults,
      pose: pose ?? this.pose,
      lastRepIsCorrect:
          clearLastRep ? null : (lastRepIsCorrect ?? this.lastRepIsCorrect),
      lastRepTimestamp:
          clearLastRep ? null : (lastRepTimestamp ?? this.lastRepTimestamp),
    );
  }
}

class WorkoutCompleted extends WorkoutState {
  final WorkoutSession session;

  const WorkoutCompleted(this.session);

  @override
  List<Object?> get props => [session];
}

class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
