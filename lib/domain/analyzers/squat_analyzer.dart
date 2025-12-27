import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/domain/analyzers/exercise_analyzer.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/domain/helpers/pose_geometry.dart';

class SquatAnalyzer extends ExerciseAnalyzer {
  // Fault codes are stable identifiers (used for UI mapping / localization).
  static const String faultKneesForward = 'KNEES_FORWARD';
  static const String faultBackNotStraight = 'BACK_NOT_STRAIGHT';
  static const String faultInsufficientDepth = 'INSUFFICIENT_DEPTH';
  static const String faultUnevenHips = 'UNEVEN_HIPS';

  static const double _downThreshold = 120.0;
  static const double _upThreshold = 160.0;
  static const double _hysteresis = 8.0;

  // Tuning knobs for form validation.
  static const double _backAngleMax = 45.0;
  static const double _depthTargetAngle = 100.0;
  static const double _unevenHipsPercent = 0.08;

  // Tracks whether the target depth was reached within the current rep.
  bool _depthReachedInCurrentRep = false;

  @override
  ExerciseType get exerciseType => ExerciseType.squat;

  @override
  void analyzePose(Pose pose) {
    final landmarks = pose.landmarks;

    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    // Skip the frame if we can't compute angles for both sides.
    if (leftHip == null ||
        rightHip == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return;
    }

    final leftHipKneeAngle = PoseGeometry.calculateAngle(
      leftShoulder,
      leftHip,
      leftKnee,
    );
    final rightHipKneeAngle = PoseGeometry.calculateAngle(
      rightShoulder,
      rightHip,
      rightKnee,
    );
    final rawHipKneeAngle = (leftHipKneeAngle + rightHipKneeAngle) / 2;

    // Smoothing reduces jitter and makes phase transitions more stable.
    final hipKneeAngle =
        PoseGeometry.getSmoothedAngle('squat_hip_knee', rawHipKneeAngle);

    // Uncomment during calibration sessions.
    // print('SQUAT_LOG: Phase=$currentPhase, Angle=${hipKneeAngle.toStringAsFixed(1)}, Faults=$currentFaults');

    if (currentPhase == RepPhase.neutral || currentPhase == RepPhase.up) {
      if (hipKneeAngle < _downThreshold) {
        currentPhase = RepPhase.down;
        _depthReachedInCurrentRep = false;
      }
    }

    if (currentPhase == RepPhase.down) {
      _checkSquatFaults(pose, hipKneeAngle);

      // Hysteresis avoids bouncing between phases near the threshold.
      if (PoseGeometry.checkThresholdWithHysteresis(
        hipKneeAngle,
        _upThreshold,
        _hysteresis,
        false,
      )) {
        currentPhase = RepPhase.up;
        emitRepResult();
      }
    }
  }

  void _checkSquatFaults(Pose pose, double hipKneeAngle) {
    final landmarks = pose.landmarks;

    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;

    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final midHipY = (leftHip.y + rightHip.y) / 2;
    final torsoHeight = (midHipY - midShoulderY).abs();

    // This is intentionally relaxed to reduce false positives on deeper squats.
    final limit = torsoHeight * 1.5;

    final leftKneeDiff = (leftKnee.x - leftAnkle.x).abs();
    final rightKneeDiff = (rightKnee.x - rightAnkle.x).abs();

    if (leftKneeDiff > limit || rightKneeDiff > limit) {
      if (!currentFaults.contains(faultKneesForward)) {
        currentFaults.add(faultKneesForward);
      }
    }

    // Midpoints reduce left/right noise when estimating torso angle.
    final midHip = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      z: (leftHip.z + rightHip.z) / 2,
      likelihood: ((leftHip.likelihood) + (rightHip.likelihood)) / 2,
    );
    final midShoulder = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: (leftShoulder.x + rightShoulder.x) / 2,
      y: (leftShoulder.y + rightShoulder.y) / 2,
      z: (leftShoulder.z + rightShoulder.z) / 2,
      likelihood: ((leftShoulder.likelihood) + (rightShoulder.likelihood)) / 2,
    );

    final torsoAngle =
        PoseGeometry.calculateAngleFromVertical(midShoulder, midHip);

    if (torsoAngle > _backAngleMax) {
      if (!currentFaults.contains(faultBackNotStraight)) {
        currentFaults.add(faultBackNotStraight);
      }
    }

    // Depth is evaluated across the rep, not on a single frame.
    if (hipKneeAngle <= _depthTargetAngle) {
      _depthReachedInCurrentRep = true;
      currentFaults.remove(faultInsufficientDepth);
    }

    final isGoingUp = PoseGeometry.isIncreasing('squat_hip_knee');
    if (isGoingUp && !_depthReachedInCurrentRep) {
      if (!currentFaults.contains(faultInsufficientDepth)) {
        currentFaults.add(faultInsufficientDepth);
      }
    }

    final bodyHeight = PoseGeometry.getVerticalDistance(midShoulder, midHip) +
        PoseGeometry.getVerticalDistance(
          midHip,
          PoseLandmark(
            type: PoseLandmarkType.leftAnkle,
            x: (leftAnkle.x + rightAnkle.x) / 2,
            y: (leftAnkle.y + rightAnkle.y) / 2,
            z: (leftAnkle.z + rightAnkle.z) / 2,
            likelihood: 1.0,
          ),
        );

    final hipHeightDiff = PoseGeometry.getVerticalDistance(leftHip, rightHip);
    if (hipHeightDiff > bodyHeight * _unevenHipsPercent) {
      if (!currentFaults.contains(faultUnevenHips)) {
        currentFaults.add(faultUnevenHips);
      }
    }
  }

  @override
  void reset() {
    super.reset();
    PoseGeometry.clearHistoryForKey('squat_hip_knee');
  }
}
