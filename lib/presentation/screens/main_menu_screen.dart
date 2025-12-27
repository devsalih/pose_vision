import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pose_vision/core/constants/exercise_constants.dart';
import 'package:pose_vision/domain/entities/exercise_type.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainMenuScreenContent();
  }
}

class MainMenuScreenContent extends StatefulWidget {
  const MainMenuScreenContent({super.key});

  @override
  State<MainMenuScreenContent> createState() => _MainMenuScreenContentState();
}

class _MainMenuScreenContentState extends State<MainMenuScreenContent> {
  late PageController _pageController;
  double _currentPage = 0;
  final int _infiniteIndexStart = 5000;

  final List<ExerciseType> _exercises = [
    ExerciseType.squat,
    ExerciseType.bicepsCurl,
    ExerciseType.lateralRaise,
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: _infiniteIndexStart,
    );
    _currentPage = _infiniteIndexStart.toDouble();

    _pageController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentPage = _pageController.page ?? _infiniteIndexStart.toDouble();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: MediaQuery.of(context).padding.bottom + 16 + 80 + 16,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'app_name'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? theme.primaryColor.withValues(alpha: 0.8)
                                : theme.primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'main_menu_title'.tr(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'main_menu_subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: 10000,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final exerciseType = _exercises[index % _exercises.length];
                final config = ExerciseConstants.getConfig(exerciseType);

                final double relativePosition = index - _currentPage;

                final double scale =
                    (1.0 - (relativePosition.abs() * 0.2)).clamp(0.75, 1.0);
                final double opacity =
                    (1.0 - (relativePosition.abs() * 0.6)).clamp(0.4, 1.0);
                final double rotation =
                    (relativePosition * 0.25).clamp(-0.6, 0.6);
                final double translateX = -relativePosition * 24;
                final double translateY = relativePosition.abs() * 15;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..translate(translateX, translateY, 0.0)
                    ..rotateY(rotation)
                    ..scale(scale),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: _buildExerciseCard(
                      exerciseType: exerciseType,
                      iconAsset: config.iconAsset,
                      name: config.nameKey.tr(),
                      description: config.descriptionKey.tr(),
                      gradient: config.gradient,
                    ),
                  ),
                );
              },
            ),
          ),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final currentIndex =
        (_currentPage % _exercises.length).round() % _exercises.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_exercises.length, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildExerciseCard({
    required ExerciseType exerciseType,
    required String iconAsset,
    required String name,
    required String description,
    required List<Color> gradient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
            ),

            // Subtle shapes to keep the gradient from feeling flat.
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),

            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/exercise-setup',
                    arguments: exerciseType,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Image.asset(
                            iconAsset,
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'start_now'.tr().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const FaIcon(
                              FontAwesomeIcons.arrowRight,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
