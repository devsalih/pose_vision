import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pose_vision/core/di/service_locator.dart';
import 'package:pose_vision/core/services/tts_service.dart';
import 'package:pose_vision/data/models/rep_record.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/analyzers/biceps_curl_analyzer.dart';
import 'package:pose_vision/domain/analyzers/exercise_analyzer.dart';
import 'package:pose_vision/domain/analyzers/lateral_raise_analyzer.dart';
import 'package:pose_vision/domain/analyzers/squat_analyzer.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';
import 'package:pose_vision/presentation/blocs/workout/workout_event.dart';
import 'package:pose_vision/presentation/blocs/workout/workout_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pose_vision/core/services/exercise_preferences_service.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final IWorkoutRepository _repository;
  final TtsService _ttsService = getIt<TtsService>();

  ExerciseAnalyzer? _analyzer;
  StreamSubscription<RepResult>? _repStreamSubscription;

  DateTime? _sessionStartTime;
  String? _sessionId;

  WorkoutBloc(this._repository) : super(const WorkoutInitial()) {
    on<StartWorkout>(_onStartWorkout);
    on<StopWorkout>(_onStopWorkout);
    on<PoseDetected>(_onPoseDetected);
    on<RepCompleted>(_onRepCompleted);
    on<ClearRepFeedback>(_onClearRepFeedback);
  }

  Future<void> _onStartWorkout(
    StartWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      // Keeps spoken feedback aligned with the current app locale.
      await _ttsService.initialize();
      await _ttsService.setLanguage(event.languageCode);

      _analyzer = _createAnalyzer(event.exerciseType);
      _analyzer!.reset();

      _repStreamSubscription = _analyzer!.repStream.listen((result) {
        add(RepCompleted(result));
      });

      _sessionStartTime = DateTime.now();
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      emit(WorkoutInProgress(
        exerciseType: event.exerciseType,
        targetReps: event.targetReps,
        currentReps: 0,
        correctReps: 0,
        wrongReps: 0,
        currentFaults: const [],
        pose: null,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error starting workout: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(WorkoutError('error_failed_start_workout'.tr()));
    }
  }

  Future<void> _onStopWorkout(
    StopWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! WorkoutInProgress) return;

      await _repStreamSubscription?.cancel();
      _repStreamSubscription = null;

      final accuracy = _analyzer?.getAccuracy() ?? 0.0;

      final session = WorkoutSession(
        id: _sessionId!,
        exerciseType: currentState.exerciseType,
        targetReps: currentState.targetReps,
        totalReps: _analyzer?.totalReps ?? 0,
        correctReps: _analyzer?.correctReps ?? 0,
        wrongReps: _analyzer?.wrongReps ?? 0,
        accuracy: accuracy,
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
      );

      await _repository.saveSession(session);

      _analyzer?.dispose();
      _analyzer = null;

      emit(WorkoutCompleted(session));
    } catch (e, stackTrace) {
      debugPrint('Error stopping workout: $e');
      debugPrint('StackTrace: $stackTrace');
      emit(WorkoutError('error_failed_save_workout'.tr()));
    }
  }

  void _onPoseDetected(
    PoseDetected event,
    Emitter<WorkoutState> emit,
  ) {
    final currentState = state;
    if (currentState is! WorkoutInProgress) return;
    if (_analyzer == null) return;

    try {
      _analyzer!.analyzePose(event.pose);

      emit(currentState.copyWith(
        pose: event.pose,
        currentFaults: List.from(_analyzer!.currentFaults),
      ));
    } catch (e, stackTrace) {
      debugPrint('Error analyzing pose: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> _onRepCompleted(
    RepCompleted event,
    Emitter<WorkoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkoutInProgress) return;
    if (_analyzer == null) return;

    try {
      final repRecord = RepRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: _sessionId!,
        timestamp: event.result.timestamp,
        exerciseType: currentState.exerciseType,
        isValid: event.result.isValid,
        faults: event.result.faults,
      );
      await _repository.saveRepRecord(repRecord);

      emit(currentState.copyWith(
        currentReps: _analyzer!.totalReps,
        correctReps: _analyzer!.correctReps,
        wrongReps: _analyzer!.wrongReps,
        currentFaults: const [],
        lastRepIsCorrect: event.result.isValid,
        lastRepTimestamp: DateTime.now(),
      ));

      // Avoids stale feedback lingering on screen when the user pauses.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!isClosed) {
          add(const ClearRepFeedback());
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final exercisePrefs = ExercisePreferencesService(prefs);
      if (exercisePrefs.isVoiceAnnouncementsEnabled()) {
        await _ttsService.announceRepCount(_analyzer!.totalReps);
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving rep record: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  void _onClearRepFeedback(
    ClearRepFeedback event,
    Emitter<WorkoutState> emit,
  ) {
    final currentState = state;
    if (currentState is WorkoutInProgress) {
      emit(currentState.copyWith(clearLastRep: true));
    }
  }

  ExerciseAnalyzer _createAnalyzer(ExerciseType exerciseType) {
    switch (exerciseType) {
      case ExerciseType.squat:
        return SquatAnalyzer();
      case ExerciseType.bicepsCurl:
        return BicepsCurlAnalyzer();
      case ExerciseType.lateralRaise:
        return LateralRaiseAnalyzer();
    }
  }

  @override
  Future<void> close() async {
    await _repStreamSubscription?.cancel();
    _analyzer?.dispose();
    return super.close();
  }
}
