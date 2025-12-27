import 'package:equatable/equatable.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/domain/analyzers/exercise_analyzer.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class StartWorkout extends WorkoutEvent {
  final ExerciseType exerciseType;
  final int targetReps;
  final String languageCode;

  const StartWorkout({
    required this.exerciseType,
    required this.targetReps,
    required this.languageCode,
  });

  @override
  List<Object?> get props => [exerciseType, targetReps, languageCode];
}

class StopWorkout extends WorkoutEvent {
  const StopWorkout();
}

class PoseDetected extends WorkoutEvent {
  final Pose pose;

  const PoseDetected(this.pose);

  @override
  List<Object?> get props => [pose];
}

class RepCompleted extends WorkoutEvent {
  final RepResult result;

  const RepCompleted(this.result);

  @override
  List<Object?> get props => [result];
}

// Used to clear transient rep feedback from the UI.
class ClearRepFeedback extends WorkoutEvent {
  const ClearRepFeedback();
}
