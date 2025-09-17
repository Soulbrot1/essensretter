import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/services/speech_service.dart';
import 'core/services/local_key_service.dart';
import 'features/food_tracking/data/datasources/food_local_data_source.dart';
import 'features/food_tracking/data/datasources/text_parser_service.dart';
import 'features/food_tracking/data/datasources/openai_text_parser_service.dart';
import 'features/food_tracking/data/datasources/food_tips_service.dart';
import 'features/food_tracking/data/datasources/food_tips_local_data_source.dart';
import 'features/food_tracking/data/repositories/food_repository_impl.dart';
import 'features/food_tracking/data/repositories/openai_text_parser_repository_impl.dart';
import 'features/food_tracking/domain/repositories/food_repository.dart';
import 'features/food_tracking/domain/repositories/text_parser_repository.dart';
import 'features/food_tracking/domain/usecases/add_food_from_text.dart';
import 'features/food_tracking/domain/usecases/add_foods.dart';
import 'features/food_tracking/domain/usecases/delete_food.dart';
import 'features/food_tracking/domain/usecases/get_all_foods.dart';
import 'features/food_tracking/domain/usecases/get_foods_by_expiry.dart';
import 'features/food_tracking/domain/usecases/parse_foods_from_text.dart';
import 'features/food_tracking/domain/usecases/update_food.dart';
import 'features/food_tracking/domain/usecases/get_expiring_foods.dart';
import 'features/food_tracking/presentation/bloc/food_bloc.dart';
import 'features/food_tracking/presentation/bloc/food_data_bloc.dart';
import 'features/food_tracking/presentation/bloc/food_ui_bloc.dart';
import 'features/recipes/data/datasources/recipe_service.dart';
import 'features/recipes/data/datasources/openai_recipe_service.dart';
import 'features/recipes/data/datasources/recipe_local_data_source.dart';
import 'features/recipes/data/repositories/recipe_repository_impl.dart';
import 'features/recipes/domain/repositories/recipe_repository.dart';
import 'features/recipes/domain/usecases/generate_recipes.dart';
import 'features/recipes/domain/usecases/get_bookmarked_recipes.dart';
import 'features/recipes/domain/usecases/save_bookmarked_recipe.dart';
import 'features/recipes/domain/usecases/remove_bookmarked_recipe.dart';
import 'features/recipes/domain/usecases/update_recipes_after_food_deletion.dart';
import 'features/recipes/presentation/bloc/recipe_bloc.dart';
import 'features/settings/data/datasources/settings_local_data_source.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/get_notification_settings.dart';
import 'features/settings/domain/usecases/save_notification_settings.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/notification/domain/usecases/schedule_daily_notification.dart';
import 'features/statistics/data/datasources/statistics_local_data_source.dart';
import 'features/statistics/data/repositories/statistics_repository_impl.dart';
import 'features/statistics/domain/repositories/statistics_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Services
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => SpeechService());
  sl.registerLazySingleton(() => LocalKeyService(sl<SharedPreferences>()));
  // BLoCs - Old monolithic FoodBloc (deprecated, will be removed)
  sl.registerFactory(
    () => FoodBloc(
      getAllFoods: sl(),
      getFoodsByExpiry: sl(),
      addFoodFromText: sl(),
      addFoods: sl(),
      parseFoodsFromText: sl(),
      deleteFood: sl(),
      updateFood: sl(),
      updateRecipesAfterFoodDeletion: sl(),
      statisticsRepository: sl(),
    ),
  );

  // New split BLoCs
  sl.registerFactory(
    () => FoodDataBloc(
      getAllFoods: sl(),
      addFoods: sl(),
      deleteFood: sl(),
      updateFood: sl(),
      updateRecipesAfterFoodDeletion: sl(),
      statisticsRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => FoodUIBloc(addFoodFromText: sl(), parseFoodsFromText: sl()),
  );

  sl.registerFactory(
    () => RecipeBloc(
      generateRecipes: sl(),
      getBookmarkedRecipes: sl(),
      saveBookmarkedRecipe: sl(),
      removeBookmarkedRecipe: sl(),
    ),
  );

  sl.registerFactory(
    () => SettingsBloc(
      getNotificationSettings: sl(),
      saveNotificationSettings: sl(),
      scheduleDailyNotification: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllFoods(sl()));
  sl.registerLazySingleton(() => GetFoodsByExpiry(sl()));
  sl.registerLazySingleton(
    () => AddFoodFromText(textParserRepository: sl(), foodRepository: sl()),
  );
  sl.registerLazySingleton(() => AddFoods(sl()));
  sl.registerLazySingleton(() => ParseFoodsFromText(sl()));
  sl.registerLazySingleton(
    () => DeleteFood(
      foodRepository: sl(),
      statisticsRepository: sl(),
      updateRecipesAfterFoodDeletion: sl(),
    ),
  );
  sl.registerLazySingleton(() => UpdateFood(sl()));
  sl.registerLazySingleton(() => GenerateRecipes(sl()));
  sl.registerLazySingleton(
    () => GetBookmarkedRecipes(repository: sl(), foodRepository: sl()),
  );
  sl.registerLazySingleton(() => SaveBookmarkedRecipe(sl()));
  sl.registerLazySingleton(() => RemoveBookmarkedRecipe(sl()));
  sl.registerLazySingleton(() => UpdateRecipesAfterFoodDeletion(sl()));
  sl.registerLazySingleton(() => GetExpiringFoods(sl()));
  sl.registerLazySingleton(() => GetNotificationSettings(sl()));
  sl.registerLazySingleton(() => SaveNotificationSettings(sl()));
  sl.registerLazySingleton(
    () => ScheduleDailyNotification(
      getNotificationSettings: sl(),
      getExpiringFoods: sl(),
      notificationService: sl(),
    ),
  );

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

  sl.registerLazySingleton<RecipeRepository>(
    () => RecipeRepositoryImpl(recipeService: sl(), localDataSource: sl()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<FoodLocalDataSource>(
    () => FoodLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<OpenAITextParserService>(
    () => OpenAITextParserService(),
  );
  sl.registerLazySingleton<TextParserService>(() => TextParserServiceImpl());
  sl.registerLazySingleton<FoodTipsLocalDataSource>(
    () => FoodTipsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<FoodTipsService>(
    () => OpenAIFoodTipsService(localDataSource: sl()),
  );
  sl.registerLazySingleton<RecipeService>(() => OpenAIRecipeService());
  sl.registerLazySingleton<RecipeLocalDataSource>(
    () => RecipeLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<StatisticsLocalDataSource>(
    () => StatisticsLocalDataSourceImpl(),
  );
}
