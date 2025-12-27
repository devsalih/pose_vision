import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pose_vision/core/constants/app_theme.dart';
import 'package:pose_vision/core/di/service_locator.dart';
import 'package:pose_vision/core/navigation/app_router.dart';
import 'package:pose_vision/core/services/hive_service.dart';
import 'package:pose_vision/domain/repositories/i_workout_repository.dart';
import 'package:pose_vision/presentation/blocs/workout/workout_bloc.dart';
import 'package:pose_vision/presentation/blocs/theme/theme_cubit.dart';
import 'package:pose_vision/presentation/blocs/history/history_bloc.dart';
import 'package:pose_vision/presentation/blocs/history/history_event.dart';

void main() async {
  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Initialize Hive
  final hiveInitSuccess = await HiveService().initHive();
  if (!hiveInitSuccess) {
    debugPrint('Critical: Hive initialization failed');
  }

  // Setup dependency injection
  await setupServiceLocator();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => WorkoutBloc(getIt<IWorkoutRepository>()),
        ),
        BlocProvider(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider(
          create: (context) => HistoryBloc(getIt<IWorkoutRepository>())
            ..add(const LoadHistory()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final accentColor = state.accentColor;

          return MaterialApp(
            title: 'app_name'.tr(),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            themeMode: state.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: accentColor,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              colorScheme: ColorScheme.light(
                primary: accentColor,
                error: AppColors.error,
                surface: Colors.white,
                onSurface: const Color(0xFF0F172A),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF0F172A),
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: accentColor,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: ColorScheme.dark(
                primary: accentColor,
                error: AppColors.error,
                surface: AppColors.surface,
                onSurface: AppColors.onSurface,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.onSurface,
                elevation: 0,
              ),
            ),
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.home,
            builder: BotToastInit(),
            navigatorObservers: [BotToastNavigatorObserver()],
          );
        },
      ),
    );
  }
}
