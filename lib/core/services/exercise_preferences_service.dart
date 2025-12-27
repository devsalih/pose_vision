import 'package:shared_preferences/shared_preferences.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

// Manages per-exercise user preferences stored in SharedPreferences.
class ExercisePreferencesService {
  static const String _squatTargetRepsKey = 'squat_target_reps';
  static const String _bicepsCurlTargetRepsKey = 'biceps_curl_target_reps';
  static const String _lateralRaiseTargetRepsKey = 'lateral_raise_target_reps';
  static const String _voiceAnnouncementsKey = 'voice_announcements_enabled';

  static const int _defaultTargetReps = 10;

  final SharedPreferences _prefs;

  ExercisePreferencesService(this._prefs);

  // Returns the stored target reps, falling back to a sensible default.
  int getTargetReps(ExerciseType exerciseType) {
    final key = _getKeyForExerciseType(exerciseType);
    return _prefs.getInt(key) ?? _defaultTargetReps;
  }

  // Persists the target reps selected by the user.
  Future<bool> setTargetReps(ExerciseType exerciseType, int reps) async {
    final key = _getKeyForExerciseType(exerciseType);
    return await _prefs.setInt(key, reps);
  }

  bool isVoiceAnnouncementsEnabled() {
    return _prefs.getBool(_voiceAnnouncementsKey) ?? true;
  }

  Future<bool> setVoiceAnnouncementsEnabled(bool enabled) async {
    return await _prefs.setBool(_voiceAnnouncementsKey, enabled);
  }

  // Maps each exercise type to its dedicated preference key.
  String _getKeyForExerciseType(ExerciseType exerciseType) {
    switch (exerciseType) {
      case ExerciseType.squat:
        return _squatTargetRepsKey;
      case ExerciseType.bicepsCurl:
        return _bicepsCurlTargetRepsKey;
      case ExerciseType.lateralRaise:
        return _lateralRaiseTargetRepsKey;
    }
  }
}
