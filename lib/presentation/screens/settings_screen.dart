import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pose_vision/core/constants/app_theme.dart';
import 'package:pose_vision/core/constants/exercise_constants.dart';
import 'package:pose_vision/core/di/service_locator.dart';
import 'package:pose_vision/core/services/exercise_preferences_service.dart';
import 'package:pose_vision/data/models/rep_record.dart';
import 'package:pose_vision/data/models/workout_session.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';
import 'package:pose_vision/core/services/toast_service.dart';
import 'package:pose_vision/presentation/blocs/history/history_bloc.dart';
import 'package:pose_vision/presentation/blocs/history/history_event.dart';
import 'package:pose_vision/presentation/blocs/theme/theme_cubit.dart';
import 'package:pose_vision/presentation/widgets/glass_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreenContent();
  }
}

class SettingsScreenContent extends StatefulWidget {
  const SettingsScreenContent({super.key});

  @override
  State<SettingsScreenContent> createState() => _SettingsScreenContentState();
}

class _SettingsScreenContentState extends State<SettingsScreenContent> {
  bool _voiceAnnouncementsEnabled = true;
  ExercisePreferencesService? _exercisePrefs;

  int _squatTargetReps = 10;
  int _bicepsCurlTargetReps = 10;
  int _lateralRaiseTargetReps = 10;

  ExerciseType? _selectedExercise;

  final List<Color> _accentOptions = [
    const Color(0xFF6366F1),
    const Color(0xFF10B981),
    const Color(0xFFF43F5E),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _exercisePrefs = ExercisePreferencesService(prefs);

    if (!mounted) return;
    setState(() {
      _squatTargetReps = _exercisePrefs!.getTargetReps(ExerciseType.squat);
      _bicepsCurlTargetReps =
          _exercisePrefs!.getTargetReps(ExerciseType.bicepsCurl);
      _lateralRaiseTargetReps =
          _exercisePrefs!.getTargetReps(ExerciseType.lateralRaise);
      _voiceAnnouncementsEnabled =
          _exercisePrefs!.isVoiceAnnouncementsEnabled();
    });
  }

  int _getTargetReps(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return _squatTargetReps;
      case ExerciseType.bicepsCurl:
        return _bicepsCurlTargetReps;
      case ExerciseType.lateralRaise:
        return _lateralRaiseTargetReps;
    }
  }

  Future<void> _setTargetReps(ExerciseType type, int value) async {
    setState(() {
      switch (type) {
        case ExerciseType.squat:
          _squatTargetReps = value;
          break;
        case ExerciseType.bicepsCurl:
          _bicepsCurlTargetReps = value;
          break;
        case ExerciseType.lateralRaise:
          _lateralRaiseTargetReps = value;
          break;
      }
    });
    await _exercisePrefs!.setTargetReps(type, value);
  }

  Color _getExerciseColor(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return const Color(0xFF6366F1);
      case ExerciseType.bicepsCurl:
        return const Color(0xFF10B981);
      case ExerciseType.lateralRaise:
        return const Color(0xFFF59E0B);
    }
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: MediaQuery.of(context).padding.top + 16,
        bottom: MediaQuery.of(context).padding.bottom + 80 + 16 + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('language'.tr()),
          const SizedBox(height: 12),
          _buildLanguageSelector(),
          const SizedBox(height: 32),
          _buildSectionTitle('appearance'.tr()),
          const SizedBox(height: 12),
          _buildThemeToggle(),
          const SizedBox(height: 20),
          _buildAccentColorPicker(),
          const SizedBox(height: 32),
          _buildSectionTitle('voice_settings'.tr()),
          const SizedBox(height: 12),
          _buildVoiceSettings(),
          const SizedBox(height: 32),
          _buildSectionTitle('default_target_reps'.tr()),
          const SizedBox(height: 12),
          _buildExerciseTargetReps(),
          const SizedBox(height: 32),
          _buildSectionTitle('danger_zone'.tr()),
          const SizedBox(height: 12),
          _buildDummyDataButton(),
          const SizedBox(height: 12),
          _buildDeleteAllDataButton(),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '${'app_name'.tr()} v1.0.0',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildLanguageTile(
            'english'.tr(),
            const Locale('en'),
            FontAwesomeIcons.globe,
          ),
          const Divider(color: Color(0x1A000000), indent: 48),
          _buildLanguageTile(
            'turkish'.tr(),
            const Locale('tr'),
            FontAwesomeIcons.globe,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String title, Locale locale, IconData icon) {
    final isSelected = context.locale == locale;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.setLocale(locale);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            FaIcon(icon, color: theme.primaryColor, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: theme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentColorPicker() {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: state.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.palette,
                      color: state.accentColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'accent_color'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: _accentOptions.asMap().entries.map((entry) {
                  final color = entry.value;
                  final isSelected = state.accentColor == color;

                  return Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 50),
                      child: GestureDetector(
                        onTap: () {
                          context.read<ThemeCubit>().updateAccentColor(color);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          width: isSelected ? 50 : 44,
                          height: isSelected ? 50 : 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black.withValues(alpha: 0.8))
                                  : Colors.transparent,
                              width: isSelected ? 3 : 0,
                            ),
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isSelected ? 1.0 : 0.0,
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceSettings() {
    final theme = Theme.of(context);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.volumeHigh,
            color: theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'voice_announcements'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: _voiceAnnouncementsEnabled,
            onChanged: (value) {
              setState(() {
                _voiceAnnouncementsEnabled = value;
              });
              _exercisePrefs?.setVoiceAnnouncementsEnabled(value);
            },
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.primaryColor.withValues(alpha: 0.5);
              }
              return null;
            }),
            activeThumbColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final theme = Theme.of(context);

        return GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.palette,
                      color: theme.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'theme_mode'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildThemeOption(
                      context,
                      'theme_system'.tr(),
                      FontAwesomeIcons.mobile,
                      ThemeMode.system,
                      state.themeMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeOption(
                      context,
                      'theme_light'.tr(),
                      FontAwesomeIcons.solidSun,
                      ThemeMode.light,
                      state.themeMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildThemeOption(
                      context,
                      'theme_dark'.tr(),
                      FontAwesomeIcons.solidMoon,
                      ThemeMode.dark,
                      state.themeMode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    final theme = Theme.of(context);
    final isSelected = mode == currentMode;

    return GestureDetector(
      onTap: () {
        context.read<ThemeCubit>().setThemeMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            FaIcon(
              icon,
              color: isSelected
                  ? theme.primaryColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.primaryColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTargetReps() {
    if (_exercisePrefs == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final exercises = [
      ExerciseType.squat,
      ExerciseType.bicepsCurl,
      ExerciseType.lateralRaise,
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'default_target_reps_desc'.tr(),
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: exercises.map((exercise) {
              final isSelected = _selectedExercise == exercise;
              final color = _getExerciseColor(exercise);
              final reps = _getTargetReps(exercise);
              final name = _getExerciseName(exercise);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedExercise =
                            (_selectedExercise == exercise) ? null : exercise;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity:
                          _selectedExercise == null || isSelected ? 1.0 : 0.4,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              color.withValues(alpha: isSelected ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              ExerciseConstants.getIconAsset(exercise),
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              color: Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$reps',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedExercise != null) ...[
            const SizedBox(height: 20),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: _getExerciseColor(_selectedExercise!),
                inactiveTrackColor: _getExerciseColor(_selectedExercise!)
                    .withValues(alpha: 0.2),
                thumbColor: _getExerciseColor(_selectedExercise!),
                overlayColor: _getExerciseColor(_selectedExercise!)
                    .withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _getTargetReps(_selectedExercise!).toDouble(),
                min: 5,
                max: 50,
                divisions: 45,
                onChanged: (value) {
                  _setTargetReps(_selectedExercise!, value.round());
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeleteAllDataButton() {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const FaIcon(
            FontAwesomeIcons.trashCan,
            color: Colors.red,
            size: 18,
          ),
        ),
        title: Text(
          'delete_all_data'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          'delete_all_data_desc'.tr(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.red.withValues(alpha: 0.7),
          ),
        ),
        onTap: () => _showDeleteAllConfirmation(context),
      ),
    );
  }

  Widget _buildDummyDataButton() {
    final theme = Theme.of(context);

    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            FontAwesomeIcons.database,
            color: theme.primaryColor,
            size: 18,
          ),
        ),
        title: Text(
          'generate_dummy_data'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'generate_dummy_data_desc'.tr(),
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        onTap: _generateDummyData,
      ),
    );
  }

  Future<void> _generateDummyData() async {
    final repository = getIt<IWorkoutRepository>();
    final random = Random();
    final exercises = [
      ExerciseType.squat,
      ExerciseType.bicepsCurl,
      ExerciseType.lateralRaise,
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final now = DateTime.now();

      for (int i = 0; i < 8; i++) {
        final day = now.subtract(Duration(days: i));
        final sessionCount = random.nextInt(3) + 1;

        for (int j = 0; j < sessionCount; j++) {
          final type = exercises[random.nextInt(exercises.length)];
          final target = 10 + random.nextInt(21);
          final total = target + random.nextInt(5);

          final correct = max(0, total - random.nextInt(3));
          final wrong = total - correct;
          final accuracy = total == 0 ? 0.0 : (correct / total) * 100;

          final startTime = DateTime(
            day.year,
            day.month,
            day.day,
            8 + random.nextInt(12),
            random.nextInt(60),
          );

          final session = WorkoutSession(
            id: '${now.microsecondsSinceEpoch}_${random.nextInt(100000)}',
            exerciseType: type,
            targetReps: target,
            totalReps: total,
            correctReps: correct,
            wrongReps: wrong,
            accuracy: accuracy,
            startTime: startTime,
            endTime: startTime.add(
              Duration(minutes: 1 + random.nextInt(4)),
            ),
          );

          await repository.saveSession(session);

          for (int k = 0; k < total; k++) {
            final isCorrect = k < correct;
            final repTime = startTime.add(Duration(seconds: k * 5));
            final faults = <String>[];

            if (!isCorrect) {
              final possibleFaults = _getFaultsForExercise(type);
              final faultCount = 1 + random.nextInt(2);
              for (int f = 0; f < faultCount; f++) {
                final fault =
                    possibleFaults[random.nextInt(possibleFaults.length)];
                if (!faults.contains(fault)) faults.add(fault);
              }
            }

            final repRecord = RepRecord(
              id: '${session.id}_rep_$k',
              sessionId: session.id,
              timestamp: repTime,
              exerciseType: type,
              isValid: isCorrect,
              faults: faults,
            );

            await repository.saveRepRecord(repRecord);
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      context.read<HistoryBloc>().add(const LoadHistory());
      ToastService.showSuccess('dummy_data_generated'.tr());
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error generating dummy data: $e');
    }
  }

  List<String> _getFaultsForExercise(ExerciseType type) {
    switch (type) {
      case ExerciseType.squat:
        return [
          'KNEES_FORWARD',
          'BACK_NOT_STRAIGHT',
          'INSUFFICIENT_DEPTH',
          'UNEVEN_HIPS',
        ];
      case ExerciseType.bicepsCurl:
        return [
          'ELBOW_MOVING',
          'INCOMPLETE_CURL',
          'SWINGING',
          'TOO_FAST',
        ];
      case ExerciseType.lateralRaise:
        return [
          'ARMS_NOT_PARALLEL',
          'ELBOW_BENT',
          'INSUFFICIENT_HEIGHT',
          'TORSO_LEAN',
        ];
    }
  }

  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_all_data'.tr()),
        content: Text('delete_all_data_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final historyBloc = context.read<HistoryBloc>();
              Navigator.pop(context);

              historyBloc.add(const DeleteAllHistory());

              if (!context.mounted) return;
              ToastService.showSuccess('all_data_deleted'.tr());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}
