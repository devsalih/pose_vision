import 'package:hive/hive.dart';

part 'exercise_type.g.dart';

// Central enum defining all supported exercise types.
// Used across domain, persistence (Hive), and UI mapping.
@HiveType(typeId: 2)
enum ExerciseType {
  @HiveField(0)
  squat,

  @HiveField(1)
  bicepsCurl,

  @HiveField(2)
  lateralRaise,
}
