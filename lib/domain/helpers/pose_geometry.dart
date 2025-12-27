import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Small geometry helpers used by analyzers.
// Keeps math + smoothing logic out of the exercise classes.
class PoseGeometry {
  static final Map<String, List<double>> _angleHistory = {};
  static final Map<String, List<double>> _distanceHistory = {};

  // A short moving window is usually enough to stabilize ML Kit jitter without adding lag.
  static const int _smoothingFrames = 6;

  static double calculateAngle(
    PoseLandmark pointA,
    PoseLandmark pointB,
    PoseLandmark pointC,
  ) {
    final double baX = pointA.x - pointB.x;
    final double baY = pointA.y - pointB.y;

    final double bcX = pointC.x - pointB.x;
    final double bcY = pointC.y - pointB.y;

    final double dot = baX * bcX + baY * bcY;

    final double magBA = sqrt(baX * baX + baY * baY);
    final double magBC = sqrt(bcX * bcX + bcY * bcY);

    // Guard for degenerate vectors (rare but possible with missing/unstable landmarks).
    if (magBA == 0 || magBC == 0) return 0.0;

    final double cosAngle = dot / (magBA * magBC);
    final double clampedCos = cosAngle.clamp(-1.0, 1.0);

    final double angleRadians = acos(clampedCos);
    return angleRadians * 180.0 / pi;
  }

  static double calculateDistance(
    PoseLandmark pointA,
    PoseLandmark pointB,
  ) {
    final double dx = pointA.x - pointB.x;
    final double dy = pointA.y - pointB.y;
    return sqrt(dx * dx + dy * dy);
  }

  static double getSmoothedAngle(String key, double currentAngle) {
    if (!_angleHistory.containsKey(key)) {
      _angleHistory[key] = [];
    }

    _angleHistory[key]!.add(currentAngle);

    if (_angleHistory[key]!.length > _smoothingFrames) {
      _angleHistory[key]!.removeAt(0);
    }

    final sum = _angleHistory[key]!.reduce((a, b) => a + b);
    return sum / _angleHistory[key]!.length;
  }

  static double getSmoothedDistance(String key, double currentDistance) {
    if (!_distanceHistory.containsKey(key)) {
      _distanceHistory[key] = [];
    }

    _distanceHistory[key]!.add(currentDistance);

    if (_distanceHistory[key]!.length > _smoothingFrames) {
      _distanceHistory[key]!.removeAt(0);
    }

    final sum = _distanceHistory[key]!.reduce((a, b) => a + b);
    return sum / _distanceHistory[key]!.length;
  }

  // Simple hysteresis helper to avoid rapid toggling near thresholds.
  static bool checkThresholdWithHysteresis(
    double value,
    double threshold,
    double hysteresis,
    bool wasAbove,
  ) {
    if (wasAbove) {
      return value > (threshold - hysteresis);
    } else {
      return value > (threshold + hysteresis);
    }
  }

  // Clears all internal smoothing/trend buffers.
  static void clearHistory() {
    _angleHistory.clear();
    _distanceHistory.clear();
  }

  // Clears buffers for a specific key without affecting others.
  static void clearHistoryForKey(String key) {
    _angleHistory.remove(key);
    _distanceHistory.remove(key);
  }

  static double getVerticalDistance(
    PoseLandmark pointA,
    PoseLandmark pointB,
  ) {
    return (pointA.y - pointB.y).abs();
  }

  static double getHorizontalDistance(
    PoseLandmark pointA,
    PoseLandmark pointB,
  ) {
    return (pointA.x - pointB.x).abs();
  }

  // Returns absolute tilt from vertical (0 = perfectly vertical).
  static double calculateAngleFromVertical(
    PoseLandmark topPoint,
    PoseLandmark bottomPoint,
  ) {
    final double dx = topPoint.x - bottomPoint.x;
    final double dy = topPoint.y - bottomPoint.y;

    final double angleFromHorizontal = atan2(dy.abs(), dx.abs()) * 180.0 / pi;
    return 90.0 - angleFromHorizontal;
  }

  // Uses recent samples to decide whether the signal is trending up.
  static bool isIncreasing(String key) {
    final history = _angleHistory[key] ?? _distanceHistory[key];
    if (history == null || history.length < 3) return false;

    int increases = 0;
    for (int i = 1; i < history.length; i++) {
      if (history[i] > history[i - 1]) increases++;
    }

    return (increases / (history.length - 1)) > 0.7;
  }

  // Uses recent samples to decide whether the signal is trending down.
  static bool isDecreasing(String key) {
    final history = _angleHistory[key] ?? _distanceHistory[key];
    if (history == null || history.length < 3) return false;

    int decreases = 0;
    for (int i = 1; i < history.length; i++) {
      if (history[i] < history[i - 1]) decreases++;
    }

    return (decreases / (history.length - 1)) > 0.7;
  }
}
