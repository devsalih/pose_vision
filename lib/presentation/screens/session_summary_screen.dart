import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pose_vision/core/constants/app_theme.dart';
import 'package:pose_vision/core/di/service_locator.dart';
import 'package:pose_vision/data/models/rep_record.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';

class SessionSummaryScreen extends StatefulWidget {
  final WorkoutSession session;

  const SessionSummaryScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final IWorkoutRepository _repository = getIt<IWorkoutRepository>();
  List<RepRecord> _repRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepRecords();
  }

  Future<void> _loadRepRecords() async {
    try {
      final records =
          await _repository.getRepRecordsBySession(widget.session.id);
      if (!mounted) return;

      setState(() {
        _repRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading rep records: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.chevronLeft,
                            size: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'workout_summary'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _getExerciseName(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        _buildAccuracyCard(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'total_reps'.tr(),
                                widget.session.totalReps.toString(),
                                theme.primaryColor,
                                FontAwesomeIcons.listCheck,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'duration'.tr(),
                                _formatDuration(),
                                theme.primaryColor,
                                FontAwesomeIcons.clock,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'correct_reps'.tr(),
                                widget.session.correctReps.toString(),
                                AppColors.success,
                                FontAwesomeIcons.circleCheck,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'wrong_reps'.tr(),
                                widget.session.wrongReps.toString(),
                                AppColors.error,
                                FontAwesomeIcons.circleXmark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        if (_repRecords.isNotEmpty) ...[
                          Text(
                            'rep_details'.tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._repRecords.asMap().entries.map((entry) {
                            final repNumber = entry.key + 1;
                            final rep = entry.value;
                            return _buildRepCard(repNumber, rep);
                          }),
                        ],
                        const SizedBox(height: 32),
                        OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: Text('delete_workout'.tr()),
                                  content: Text('delete_workout_confirm'.tr()),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext)
                                              .pop(false),
                                      child: Text(
                                        'cancel'.tr(),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      child: Text(
                                        'delete'.tr(),
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed != true || !mounted) return;

                            try {
                              await _repository
                                  .deleteSession(widget.session.id);
                              if (!mounted) return;
                              Navigator.pop(context, true);
                            } catch (e) {
                              debugPrint('Error deleting session: $e');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: const BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.trash,
                                color: AppColors.error,
                                size: 16,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'delete_workout'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAccuracyCard() {
    final theme = Theme.of(context);
    final accuracy = widget.session.accuracy;

    Color color;
    if (accuracy >= 80) {
      color = AppColors.success;
    } else if (accuracy >= 50) {
      color = Colors.orange;
    } else {
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.bullseye, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                'accuracy'.tr().toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${accuracy.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isDark ? 0.15 : 0.08),
            color.withOpacity(isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepCard(int repNumber, RepRecord rep) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = rep.isValid ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(isDark ? 0.12 : 0.06),
            statusColor.withOpacity(isDark ? 0.06 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$repNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rep.faults.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rep.faults
                          .map(
                            (fault) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.triangleExclamation,
                                    color: AppColors.error,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: AutoSizeText(
                                      'fault_$fault'.tr(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  // Valid reps intentionally stay clean: number badge + subtle color communicates success
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExerciseName() {
    switch (widget.session.exerciseType) {
      case ExerciseType.squat:
        return 'exercise_squat'.tr();
      case ExerciseType.bicepsCurl:
        return 'exercise_biceps_curl'.tr();
      case ExerciseType.lateralRaise:
        return 'exercise_lateral_raise'.tr();
    }
  }

  String _formatDuration() {
    final duration =
        widget.session.endTime.difference(widget.session.startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
