import 'package:get_it/get_it.dart';
import 'features/food_tracking/data/datasources/food_local_data_source.dart';
import 'features/food_tracking/data/datasources/text_parser_service.dart';
import 'features/food_tracking/data/datasources/openai_text_parser_service.dart';
import 'features/food_tracking/data/repositories/food_repository_impl.dart';
import 'features/food_tracking/data/repositories/openai_text_parser_repository_impl.dart';
import 'features/food_tracking/domain/repositories/food_repository.dart';
import 'features/food_tracking/domain/repositories/text_parser_repository.dart';
import 'features/food_tracking/domain/usecases/add_food_from_text.dart';
import 'features/food_tracking/domain/usecases/delete_food.dart';
import 'features/food_tracking/domain/usecases/get_all_foods.dart';
import 'features/food_tracking/domain/usecases/get_foods_by_expiry.dart';
import 'features/food_tracking/presentation/bloc/food_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(
    () => FoodBloc(
      getAllFoods: sl(),
      getFoodsByExpiry: sl(),
      addFoodFromText: sl(),
      deleteFood: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllFoods(sl()));
  sl.registerLazySingleton(() => GetFoodsByExpiry(sl()));
  sl.registerLazySingleton(() => AddFoodFromText(
    textParserRepository: sl(),
    foodRepository: sl(),
  ));
  sl.registerLazySingleton(() => DeleteFood(sl()));

  // Repositories
  sl.registerLazySingleton<FoodRepository>(
    () => FoodRepositoryImpl(localDataSource: sl()),
  );
  
  // Wähle zwischen OpenAI und einfachem Parser
  sl.registerLazySingleton<TextParserRepository>(
    () => OpenAITextParserRepositoryImpl(openAITextParserService: sl()),
    // Fallback auf einfachen Parser:
    // () => TextParserRepositoryImpl(textParserService: sl<TextParserService>()),
  );

  // Data sources
  sl.registerLazySingleton<FoodLocalDataSource>(
    () => FoodLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<OpenAITextParserService>(
    () => OpenAITextParserService(),
  );
  sl.registerLazySingleton<TextParserService>(
    () => TextParserServiceImpl(),
  );
}