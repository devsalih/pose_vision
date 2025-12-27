import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/domain/analyzers/exercise_analyzer.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/domain/helpers/pose_geometry.dart';

class LateralRaiseAnalyzer extends ExerciseAnalyzer {
  // Fault codes are stable identifiers (used for UI mapping / localization).
  static const String faultArmsNotParallel = 'ARMS_NOT_PARALLEL';
  static const String faultElbowBent = 'ELBOW_BENT';
  static const String faultInsufficientHeight = 'INSUFFICIENT_HEIGHT';
  static const String faultTorsoLean = 'TORSO_LEAN';

  // Allows a natural, slight elbow bend instead of enforcing a perfectly straight arm.
  static const double _minElbowAngle = 125.0;

  // Tolerance for torso tilt before flagging leaning/cheating.
  static const double _maxTorsoAngle = 35.0;

  @override
  ExerciseType get exerciseType => ExerciseType.lateralRaise;

  @override
  void analyzePose(Pose pose) {
    final landmarks = pose.landmarks;

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    // Skip the frame if we can't reliably compute symmetry and torso measurements.
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null ||
        leftHip == null ||
        rightHip == null) {
      return;
    }

    // Positive value means elbows are above shoulders (screen-space Y grows downward).
    final leftElbowHeight = leftShoulder.y - leftElbow.y;
    final rightElbowHeight = rightShoulder.y - rightElbow.y;
    final avgElbowHeight = (leftElbowHeight + rightElbowHeight) / 2;

    // Elbow height is smoothed to avoid phase flapping on minor pose jitter.
    final smoothedElbowHeight = PoseGeometry.getSmoothedDistance(
      'lateral_elbow_height',
      avgElbowHeight,
    );

    if (currentPhase == RepPhase.neutral || currentPhase == RepPhase.down) {
      if (smoothedElbowHeight > 0) {
        currentPhase = RepPhase.up;
      }
    }

    if (currentPhase == RepPhase.up) {
      _checkLateralRaiseFaults(pose);

      // Hysteresis scales with body size by normalizing against shoulder width.
      final shoulderWidth =
          PoseGeometry.calculateDistance(leftShoulder, rightShoulder);
      final hysteresisLimit = -shoulderWidth * 0.2;

      if (smoothedElbowHeight < hysteresisLimit) {
        currentPhase = RepPhase.down;
        emitRepResult();
      }
    }
  }

  void _checkLateralRaiseFaults(Pose pose) {
    final landmarks = pose.landmarks;

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final leftElbow = landmarks[PoseLandmarkType.leftElbow]!;
    final rightElbow = landmarks[PoseLandmarkType.rightElbow]!;
    final leftWrist = landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = landmarks[PoseLandmarkType.rightWrist]!;
    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;

    final armHeightDiff = (leftElbow.y - rightElbow.y).abs();

    // Symmetry check is normalized so it behaves consistently across different camera distances.
    final shoulderWidth =
        PoseGeometry.calculateDistance(leftShoulder, rightShoulder);
    final symmetryLimit = shoulderWidth * 0.4;

    if (armHeightDiff > symmetryLimit) {
      if (!currentFaults.contains(faultArmsNotParallel)) {
        currentFaults.add(faultArmsNotParallel);
      }
    }

    final leftElbowAngle = PoseGeometry.calculateAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    final rightElbowAngle = PoseGeometry.calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );
    final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    if (avgElbowAngle < _minElbowAngle) {
      if (!currentFaults.contains(faultElbowBent)) {
        currentFaults.add(faultElbowBent);
      }
    }

    final leftElbowHeight = leftShoulder.y - leftElbow.y;
    final rightElbowHeight = rightShoulder.y - rightElbow.y;
    final avgElbowHeight = (leftElbowHeight + rightElbowHeight) / 2;

    // The "insufficient height" warning is only meaningful once the user starts lowering.
    final isLowering = PoseGeometry.isDecreasing('lateral_elbow_height');
    if (isLowering && avgElbowHeight < -5) {
      if (!currentFaults.contains(faultInsufficientHeight)) {
        currentFaults.add(faultInsufficientHeight);
      }
    } else if (avgElbowHeight >= 0) {
      currentFaults.remove(faultInsufficientHeight);
    }

    // Midpoints reduce left/right noise when estimating torso lean.
    final midShoulder = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: (leftShoulder.x + rightShoulder.x) / 2,
      y: (leftShoulder.y + rightShoulder.y) / 2,
      z: (leftShoulder.z + rightShoulder.z) / 2,
      likelihood: 1.0,
    );
    final midHip = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      z: (leftHip.z + rightHip.z) / 2,
      likelihood: 1.0,
    );

    final torsoAngle =
        PoseGeometry.calculateAngleFromVertical(midShoulder, midHip);

    if (torsoAngle > _maxTorsoAngle) {
      if (!currentFaults.contains(faultTorsoLean)) {
        currentFaults.add(faultTorsoLean);
      }
    }
  }

  @override
  void reset() {
    super.reset();
    PoseGeometry.clearHistoryForKey('lateral_elbow_height');
  }
}
