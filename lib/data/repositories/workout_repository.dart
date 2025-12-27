import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:pose_vision/core/constants/hive_constants.dart';
import 'package:pose_vision/data/models/rep_record.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';

// Hive-backed implementation of workout persistence.
class WorkoutRepository implements IWorkoutRepository {
  Box<WorkoutSession> get _sessionsBox =>
      Hive.box<WorkoutSession>(HiveBoxes.sessions);

  Box<RepRecord> get _repRecordsBox =>
      Hive.box<RepRecord>(HiveBoxes.repRecords);

  @override
  Future<void> saveSession(WorkoutSession session) async {
    try {
      await _sessionsBox.put(session.id, session);
      debugPrint('Session saved: ${session.id}');
    } catch (e, stackTrace) {
      debugPrint('Error saving session: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<WorkoutSession>> getAllSessions() async {
    try {
      final sessions = _sessionsBox.values.toList();
      // UI expects latest sessions first.
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (e, stackTrace) {
      debugPrint('Error getting all sessions: $e');
      debugPrint('StackTrace: $stackTrace');
      return [];
    }
  }

  @override
  Future<void> saveRepRecord(RepRecord record) async {
    try {
      await _repRecordsBox.put(record.id, record);
      debugPrint('Rep record saved: ${record.id}');
    } catch (e, stackTrace) {
      debugPrint('Error saving rep record: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<RepRecord>> getRepRecordsBySession(String sessionId) async {
    try {
      final records = _repRecordsBox.values
          .where((record) => record.sessionId == sessionId)
          .toList();

      // Keeps the rep timeline stable when rendering charts/lists.
      records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return records;
    } catch (e, stackTrace) {
      debugPrint('Error getting rep records for session $sessionId: $e');
      debugPrint('StackTrace: $stackTrace');
      return [];
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _sessionsBox.delete(sessionId);
      debugPrint('Session deleted: $sessionId');

      final recordsToDelete = _repRecordsBox.values
          .where((record) => record.sessionId == sessionId)
          .toList();

      for (final record in recordsToDelete) {
        await _repRecordsBox.delete(record.id);
      }

      debugPrint(
        'Deleted ${recordsToDelete.length} rep records for session $sessionId',
      );
    } catch (e, stackTrace) {
      debugPrint('Error deleting session $sessionId: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      await _sessionsBox.clear();
      await _repRecordsBox.clear();
      debugPrint('All workout data cleared');
    } catch (e, stackTrace) {
      debugPrint('Error clearing all data: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }
}
