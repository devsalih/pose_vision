import 'package:get_it/get_it.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pose_vision/core/services/permission_service.dart';
import 'package:pose_vision/core/services/tts_service.dart';
import 'package:pose_vision/core/utils/image_converter.dart';
import 'package:pose_vision/data/repositories/workout_repository.dart';
import 'package:pose_vision/domain/analyzers/biceps_curl_analyzer.dart';
import 'package:pose_vision/domain/analyzers/lateral_raise_analyzer.dart';
import 'package:pose_vision/domain/analyzers/squat_analyzer.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Data layer bindings.
  getIt.registerLazySingleton<IWorkoutRepository>(
    () => WorkoutRepository(),
  );

  // App-level services.
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionService(),
  );

  getIt.registerLazySingleton<TtsService>(
    () => TtsService(),
  );

  // Shared utilities.
  getIt.registerLazySingleton<ImageProcessor>(
    () => ImageProcessor(),
  );

  // Single pose detector instance for the camera stream.
  getIt.registerLazySingleton<PoseDetector>(
    () => PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    ),
  );

  // Analyzers are created per workout to keep state isolated.
  getIt.registerFactory<SquatAnalyzer>(
    () => SquatAnalyzer(),
  );
  getIt.registerFactory<BicepsCurlAnalyzer>(
    () => BicepsCurlAnalyzer(),
  );
  getIt.registerFactory<LateralRaiseAnalyzer>(
    () => LateralRaiseAnalyzer(),
  );
}
