import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Handles text-to-speech feedback during workouts.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _isInitialized = true;
      debugPrint('TTS initialized');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Updates the active TTS language to match the current app locale.
  Future<void> setLanguage(String languageCode) async {
    try {
      if (!_isInitialized) await initialize();
      await _tts.setLanguage(languageCode);
      debugPrint('TTS language set to: $languageCode');
    } catch (e) {
      debugPrint('Error setting TTS language: $e');
    }
  }

  // Speaks the current repetition count.
  Future<void> announceRepCount(int count) async {
    try {
      if (!_isInitialized) await initialize();
      await _tts.speak(count.toString());
    } catch (e) {
      debugPrint('Error announcing rep count: $e');
    }
  }

  // Announces that the workout has been completed.
  Future<void> announceWorkoutComplete() async {
    try {
      if (!_isInitialized) await initialize();
      await _tts.speak('tts_workout_complete'.tr());
    } catch (e) {
      debugPrint('Error announcing workout complete: $e');
    }
  }

  // Stops any ongoing speech and releases resources.
  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Error disposing TTS: $e');
    }
  }
}
