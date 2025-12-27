import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/domain/analyzers/exercise_analyzer.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/domain/helpers/pose_geometry.dart';

class BicepsCurlAnalyzer extends ExerciseAnalyzer {
  // Fault codes are stable identifiers (used for UI mapping / localization).
  static const String faultElbowMoving = 'ELBOW_MOVING';
  static const String faultIncompleteCurl = 'INCOMPLETE_CURL';
  static const String faultSwinging = 'SWINGING';
  static const String faultTooFast = 'TOO_FAST';

  // Angle thresholds in degrees (shoulder–elbow–wrist).
  // Smaller angle => more flexion (curling up).
  static const double _upThreshold = 70.0;
  static const double _downThreshold = 160.0;
  static const double _hysteresis = 12.0;

  // Tuning knobs for form validation.
  static const double _elbowMovementPercent = 0.25;
  static const double _torsoSwingAngle = 20.0;
  static const double _minRepDuration = 1.0;

  // Rep-scoped state.
  DateTime? _repStartTime;
  double? _baselineElbowDistance;
  double? _baselineTorsoAngle;

  @override
  ExerciseType get exerciseType => ExerciseType.bicepsCurl;

  @override
  void analyzePose(Pose pose) {
    final landmarks = pose.landmarks;

    // Right arm is used as the reference to keep the logic deterministic.
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    // Skip the frame if we can't reliably compute angles.
    if (rightShoulder == null ||
        rightElbow == null ||
        rightWrist == null ||
        rightHip == null) {
      return;
    }

    final rawElbowAngle = PoseGeometry.calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );

    // Smooth raw angle to reduce jitter around thresholds.
    final elbowAngle =
        PoseGeometry.getSmoothedAngle('biceps_elbow', rawElbowAngle);

    // Phase progression:
    // - down/neutral -> up when elbow flexes enough (angle drops)
    // - up -> down when elbow extends back (angle rises with hysteresis)
    if (currentPhase == RepPhase.neutral || currentPhase == RepPhase.down) {
      if (elbowAngle < _upThreshold) {
        if (currentPhase == RepPhase.down) {
          // Rep starts when the user leaves the "down" position.
          _repStartTime = DateTime.now();
          _initializeBaselines(pose);
        }
        currentPhase = RepPhase.up;
      }
    }

    if (currentPhase == RepPhase.up) {
      _checkCurlFaults(pose, elbowAngle);

      // Hysteresis prevents rapid toggling when the angle hovers near the threshold.
      if (PoseGeometry.checkThresholdWithHysteresis(
        elbowAngle,
        _downThreshold,
        _hysteresis,
        false,
      )) {
        // Guard against "half reps" caused by fast/unstable detections.
        if (_repStartTime != null) {
          final duration = DateTime.now().difference(_repStartTime!);
          if (duration.inMilliseconds < _minRepDuration * 1000) {
            if (!currentFaults.contains(faultTooFast)) {
              currentFaults.add(faultTooFast);
            }
          }
        }

        currentPhase = RepPhase.down;
        emitRepResult();

        // Reset per-rep state after emitting the result.
        _repStartTime = null;
        _baselineElbowDistance = null;
        _baselineTorsoAngle = null;
      }
    }
  }

  void _initializeBaselines(Pose pose) {
    final landmarks = pose.landmarks;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final rightElbow = landmarks[PoseLandmarkType.rightElbow]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;

    // Shoulder↔elbow distance is used as a simple proxy for upper-arm stability.
    _baselineElbowDistance =
        PoseGeometry.calculateDistance(rightShoulder, rightElbow);

    // Torso tilt relative to vertical helps detect momentum / swinging.
    _baselineTorsoAngle =
        PoseGeometry.calculateAngleFromVertical(rightShoulder, rightHip);
  }

  void _checkCurlFaults(Pose pose, double elbowAngle) {
    final landmarks = pose.landmarks;

    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final rightElbow = landmarks[PoseLandmarkType.rightElbow]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;

    if (_baselineElbowDistance != null) {
      final currentDistance =
          PoseGeometry.calculateDistance(rightShoulder, rightElbow);
      final distanceChange = (currentDistance - _baselineElbowDistance!).abs();
      final changePercent = distanceChange / _baselineElbowDistance!;

      // If the elbow drifts significantly, the user is likely moving the upper arm.
      if (changePercent > _elbowMovementPercent) {
        if (!currentFaults.contains(faultElbowMoving)) {
          currentFaults.add(faultElbowMoving);
        }
      }
    }

    // If the elbow angle starts increasing early, the user is lowering before reaching full flexion.
    final isDecreasingHeight = PoseGeometry.isIncreasing('biceps_elbow');
    if (isDecreasingHeight && elbowAngle > _upThreshold + 15) {
      if (!currentFaults.contains(faultIncompleteCurl)) {
        currentFaults.add(faultIncompleteCurl);
      }
    } else if (elbowAngle <= _upThreshold) {
      // Clear if they actually reached the expected top range.
      currentFaults.remove(faultIncompleteCurl);
    }

    if (_baselineTorsoAngle != null) {
      final currentTorsoAngle =
          PoseGeometry.calculateAngleFromVertical(rightShoulder, rightHip);
      final torsoChange = (currentTorsoAngle - _baselineTorsoAngle!).abs();

      // Large torso deviation usually means swinging / cheating with momentum.
      if (torsoChange > _torsoSwingAngle) {
        if (!currentFaults.contains(faultSwinging)) {
          currentFaults.add(faultSwinging);
        }
      }
    }
  }

  @override
  void reset() {
    super.reset();
    _repStartTime = null;
    _baselineElbowDistance = null;
    _baselineTorsoAngle = null;

    // Analyzer-specific history key used by smoothing/trend helpers.
    PoseGeometry.clearHistoryForKey('biceps_elbow');
  }
}
