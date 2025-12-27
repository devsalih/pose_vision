import 'dart:async';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

// Result object produced after a repetition is finalized.
class RepResult {
  final bool isValid;
  final List<String> faults;
  final DateTime timestamp;

  RepResult({
    required this.isValid,
    required this.faults,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RepResult(isValid: $isValid, faults: $faults, timestamp: $timestamp)';
  }
}

// Shared repetition phases used across all analyzers.
enum RepPhase {
  up,
  down,
  neutral,
}

// Base class that handles repetition bookkeeping and result emission.
abstract class ExerciseAnalyzer {
  // Identifies the exercise handled by this analyzer.
  ExerciseType get exerciseType;

  RepPhase currentPhase = RepPhase.neutral;

  int totalReps = 0;
  int correctReps = 0;
  int wrongReps = 0;

  // Collected faults for the currently active repetition.
  final List<String> currentFaults = [];

  // Broadcast stream so multiple consumers can react to rep results.
  final StreamController<RepResult> _repController =
      StreamController<RepResult>.broadcast();

  Stream<RepResult> get repStream => _repController.stream;

  // Called for every processed pose frame.
  void analyzePose(Pose pose);

  // Clears all runtime state before starting a new session.
  void reset() {
    currentPhase = RepPhase.neutral;
    totalReps = 0;
    correctReps = 0;
    wrongReps = 0;
    currentFaults.clear();
  }

  // Computes accuracy based on completed repetitions.
  double getAccuracy() {
    if (totalReps == 0) return 0.0;
    return (correctReps / totalReps) * 100.0;
  }

  // Finalizes the current repetition and pushes the result to listeners.
  void emitRepResult() {
    final isValid = currentFaults.isEmpty;
    final faults = List<String>.from(currentFaults);

    totalReps++;
    if (isValid) {
      correctReps++;
    } else {
      wrongReps++;
    }

    _repController.add(
      RepResult(
        isValid: isValid,
        faults: faults,
        timestamp: DateTime.now(),
      ),
    );

    currentFaults.clear();
  }

  // Releases the stream when the analyzer is disposed.
  void dispose() {
    _repController.close();
  }
}
