import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pose_vision/core/constants/hive_constants.dart';
import 'package:pose_vision/data/models/rep_record.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

/// Service for initializing and managing Hive database
class HiveService {
  /// Initialize Hive with all adapters and boxes
  Future<bool> initHive() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      Hive.registerAdapter(WorkoutSessionAdapter());
      Hive.registerAdapter(RepRecordAdapter());
      Hive.registerAdapter(ExerciseTypeAdapter());

      // Open boxes
      await Hive.openBox<WorkoutSession>(HiveBoxes.sessions);
      await Hive.openBox<RepRecord>(HiveBoxes.repRecords);
      await Hive.openBox(HiveBoxes.settings);

      debugPrint('Hive initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error initializing Hive: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }
}
