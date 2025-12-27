import 'package:hive/hive.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

part 'rep_record.g.dart';

// Persistent model representing a single completed repetition.
@HiveType(typeId: 1)
class RepRecord {
  @HiveField(0)
  final String id;

  // Links the rep to its parent workout session.
  @HiveField(1)
  final String sessionId;

  // Time when the repetition was completed.
  @HiveField(2)
  final DateTime timestamp;

  // Exercise this repetition belongs to.
  @HiveField(3)
  final ExerciseType exerciseType;

  // Indicates whether the rep was performed without detected faults.
  @HiveField(4)
  final bool isValid;

  // Fault codes collected during the repetition.
  @HiveField(5)
  final List<String> faults;

  RepRecord({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.exerciseType,
    required this.isValid,
    required this.faults,
  });
}
