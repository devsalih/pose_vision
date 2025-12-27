import 'package:flutter/material.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

// Immutable configuration object bound to a specific exercise.
class ExerciseConfig {
  final ExerciseType type;
  final String iconAsset;
  final String nameKey;
  final String descriptionKey;
  final List<Color> gradient;

  const ExerciseConfig({
    required this.type,
    required this.iconAsset,
    required this.nameKey,
    required this.descriptionKey,
    required this.gradient,
  });
}

// Central lookup for exercise-related UI configuration.
class ExerciseConstants {
  ExerciseConstants._();

  static const String squatIcon = 'assets/squat.png';
  static const String bicepsCurlIcon = 'assets/biceps_curl.png';
  static const String lateralRaiseIcon = 'assets/lateral_raise.png';

  static const Map<ExerciseType, ExerciseConfig> configs = {
    ExerciseType.squat: ExerciseConfig(
      type: ExerciseType.squat,
      iconAsset: squatIcon,
      nameKey: 'exercise_squat',
      descriptionKey: 'exercise_squat_desc',
      gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    ),
    ExerciseType.bicepsCurl: ExerciseConfig(
      type: ExerciseType.bicepsCurl,
      iconAsset: bicepsCurlIcon,
      nameKey: 'exercise_biceps_curl',
      descriptionKey: 'exercise_biceps_curl_desc',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    ExerciseType.lateralRaise: ExerciseConfig(
      type: ExerciseType.lateralRaise,
      iconAsset: lateralRaiseIcon,
      nameKey: 'exercise_lateral_raise',
      descriptionKey: 'exercise_lateral_raise_desc',
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
  };

  static ExerciseConfig getConfig(ExerciseType type) {
    return configs[type]!;
  }

  static String getIconAsset(ExerciseType type) {
    return configs[type]!.iconAsset;
  }

  static List<Color> getGradient(ExerciseType type) {
    return configs[type]!.gradient;
  }

  static String getNameKey(ExerciseType type) {
    return configs[type]!.nameKey;
  }

  static String getDescriptionKey(ExerciseType type) {
    return configs[type]!.descriptionKey;
  }
}
