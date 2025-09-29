import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'features/food_tracking/presentation/bloc/food_bloc.dart';
import 'features/food_tracking/presentation/pages/food_tracking_page.dart';
import 'features/recipes/presentation/bloc/recipe_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/notification/domain/usecases/schedule_daily_notification.dart';
import 'core/services/notification_service.dart';
import 'core/usecases/usecase.dart';
import 'features/sharing/presentation/services/simple_user_identity_service.dart';
import 'injection_container.dart' as di;
import 'modern_splash_screen.dart';
import 'features/onboarding/presentation/pages/onboarding_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lade Environment Variablen
  await dotenv.load(fileName: ".env");

  await di.init();

  // Initialisiere User Identity (Sharing Feature)
  try {
    final userId = await SimpleUserIdentityService.ensureUserIdentity();
    print('App started with User-ID: $userId');
  } catch (e) {
    print('Warning: User Identity initialization failed: $e');
    // App kann trotzdem starten, nur Sharing-Features sind nicht verfügbar
  }

  // Initialisiere Notification Service
  final notificationService = di.sl<NotificationService>();
  await notificationService.initialize();

  // Plane tägliche Benachrichtigung basierend auf Einstellungen
  final scheduleDailyNotification = di.sl<ScheduleDailyNotification>();
  await scheduleDailyNotification(NoParams());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Essensretter 3',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de', 'DE'), Locale('en', 'US')],
      locale: const Locale('de', 'DE'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<FoodBloc>()),
          BlocProvider(create: (context) => di.sl<RecipeBloc>()),
          BlocProvider(
            create: (context) =>
                di.sl<SettingsBloc>()..add(LoadNotificationSettings()),
          ),
        ],
        child: const ModernSplashScreen(
          child: OnboardingScreen(child: FoodTrackingPage()),
        ),
      ),
    );
  }
}
