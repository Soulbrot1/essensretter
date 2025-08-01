import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/food_tracking/presentation/bloc/food_bloc.dart';
import 'features/food_tracking/presentation/pages/food_tracking_page.dart';
import 'features/recipes/presentation/bloc/recipe_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lade Environment Variablen
  await dotenv.load(fileName: ".env");
  
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      supportedLocales: const [
        Locale('de', 'DE'),
        Locale('en', 'US'),
      ],
      locale: const Locale('de', 'DE'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<FoodBloc>()),
          BlocProvider(create: (context) => di.sl<RecipeBloc>()),
        ],
        child: const FoodTrackingPage(),
      ),
    );
  }
}