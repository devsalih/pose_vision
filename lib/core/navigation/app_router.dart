import 'package:flutter/material.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/presentation/screens/camera_screen.dart';
import 'package:pose_vision/presentation/screens/exercise_setup_screen.dart';
import 'package:pose_vision/presentation/screens/main_navigation_screen.dart';
import 'package:pose_vision/presentation/screens/session_summary_screen.dart';

// Centralized route definitions and screen construction.
class AppRouter {
  static const String home = '/';
  static const String exerciseSetup = '/exercise-setup';
  static const String camera = '/camera';
  static const String summary = '/summary';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );

      case exerciseSetup:
        final exerciseType = settings.arguments as ExerciseType;
        return MaterialPageRoute(
          builder: (_) => ExerciseSetupScreen(exerciseType: exerciseType),
        );

      case camera:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CameraScreen(
            exerciseType: args['exerciseType'] as ExerciseType,
            targetReps: args['targetReps'] as int,
          ),
        );

      case summary:
        final session = settings.arguments as WorkoutSession;
        return MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(session: session),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );
    }
  }
}
