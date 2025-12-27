import 'package:pose_vision/data/models/rep_record.dart';
import 'package:pose_vision/data/models/workout_session.dart';

// Repository contract for workout persistence.
abstract class IWorkoutRepository {
  Future<void> saveSession(WorkoutSession session);

  Future<List<WorkoutSession>> getAllSessions();

  Future<void> saveRepRecord(RepRecord record);

  Future<List<RepRecord>> getRepRecordsBySession(String sessionId);

  // Also removes rep records linked to the session.
  Future<void> deleteSession(String sessionId);

  Future<void> clearAllData();
}
