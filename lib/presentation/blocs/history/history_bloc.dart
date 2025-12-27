import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final IWorkoutRepository _repository;

  HistoryBloc(this._repository) : super(const HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<DeleteAllHistory>(_onDeleteAllHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    try {
      final sessions = await _repository.getAllSessions();
      emit(HistoryLoaded(sessions));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onDeleteAllHistory(
    DeleteAllHistory event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _repository.clearAllData();
      emit(const HistoryLoaded([]));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}
