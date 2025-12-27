// Centralized names for Hive boxes used by the app.
class HiveBoxes {
  static const String sessions = 'workout_sessions';
  static const String repRecords = 'rep_records';
  static const String settings = 'settings';
}

// Stable type IDs for Hive adapters.
// These values must not change once persisted data exists.
class HiveTypeIds {
  static const int workoutSession = 0;
  static const int repRecord = 1;
  static const int exerciseType = 2;
}
