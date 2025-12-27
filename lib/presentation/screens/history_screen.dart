import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pose_vision/core/constants/app_theme.dart';
import 'package:pose_vision/core/constants/exercise_constants.dart';
import 'package:pose_vision/core/di/service_locator.dart';
import 'package:pose_vision/core/services/toast_service.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pose_vision/presentation/blocs/history/history_bloc.dart';
import 'package:pose_vision/presentation/blocs/history/history_event.dart';
import 'package:pose_vision/presentation/blocs/history/history_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoryScreenContent();
  }
}

class HistoryScreenContent extends StatelessWidget {
  const HistoryScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is HistoryLoaded) {
          if (state.sessions.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<HistoryBloc>().add(const LoadHistory());
            },
            child: _buildSessionList(context, state.sessions),
          );
        } else if (state is HistoryError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'no_history_message'.tr(),
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    List<WorkoutSession> sessions,
  ) {
    final grouped = _groupSessionsByDate(context, sessions);
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: MediaQuery.of(context).padding.bottom + 32 + 80,
        left: 16,
        right: 16,
      ),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                group['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ...(group['sessions'] as List<WorkoutSession>)
                .map((session) => _buildSessionCard(context, session)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _groupSessionsByDate(
    BuildContext context,
    List<WorkoutSession> sessions,
  ) {
    final sortedSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final Map<String, List<WorkoutSession>> groups = {};
    final DateFormat formatter = DateFormat.yMMMMd(context.locale.toString());

    for (final session in sortedSessions) {
      final dateKey = formatter.format(session.startTime);
      (groups[dateKey] ??= []).add(session);
    }

    final result = <Map<String, dynamic>>[];
    final Set<String> processedKeys = {};

    for (final session in sortedSessions) {
      final dateKey = formatter.format(session.startTime);
      if (processedKeys.add(dateKey)) {
        result.add({
          'label': dateKey.toUpperCase(),
          'sessions': groups[dateKey],
        });
      }
    }

    return result;
  }

  Widget _buildSessionCard(BuildContext context, WorkoutSession session) {
    final theme = Theme.of(context);
    final repository = getIt<IWorkoutRepository>();

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text('delete_workout'.tr()),
                  content: Text('delete_workout_confirm'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        'cancel'.tr(),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        'delete'.tr(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (direction) async {
        final deletedSession = session;

        try {
          await repository.deleteSession(session.id);

          if (!context.mounted) return;

          context.read<HistoryBloc>().add(const LoadHistory());

          ToastService.showSuccess(
            'workout_deleted'.tr(),
            actionLabel: 'undo'.tr(),
            onAction: () async {
              await repository.saveSession(deletedSession);
              if (context.mounted) {
                context.read<HistoryBloc>().add(const LoadHistory());
              }
            },
          );
        } catch (e) {
          debugPrint('Error deleting session: $e');
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const FaIcon(
          FontAwesomeIcons.trash,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: InkWell(
            onTap: () async {
              final deleted = await Navigator.pushNamed(
                context,
                '/summary',
                arguments: session,
              );

              if (deleted == true && context.mounted) {
                context.read<HistoryBloc>().add(const LoadHistory());
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            ExerciseConstants.getGradient(session.exerciseType),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      ExerciseConstants.getIconAsset(session.exerciseType),
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getExerciseName(session.exerciseType),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.totalReps} ${'reps'.tr()} • ${session.accuracy.toStringAsFixed(0)}% ${'accurate'.tr()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm',
                                  context.locale.toString())
                              .format(session.startTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAccuracyColor(session.accuracy),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${session.accuracy.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getExerciseName(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return 'exercise_squat'.tr();
      case ExerciseType.bicepsCurl:
        return 'exercise_biceps_curl'.tr();
      case ExerciseType.lateralRaise:
        return 'exercise_lateral_raise'.tr();
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) {
      return AppColors.success;
    } else if (accuracy >= 50) {
      return Colors.orange;
    } else {
      return AppColors.error;
    }
  }
}
