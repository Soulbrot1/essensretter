import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../food_tracking/domain/entities/food.dart';
import '../../../food_tracking/domain/usecases/get_expiring_foods.dart';
import '../../../settings/domain/usecases/get_notification_settings.dart';

class ScheduleDailyNotification implements UseCase<void, NoParams> {
  final GetNotificationSettings getNotificationSettings;
  final GetExpiringFoods getExpiringFoods;
  final NotificationService notificationService;

  ScheduleDailyNotification({
    required this.getNotificationSettings,
    required this.getExpiringFoods,
    required this.notificationService,
  });

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    // Hole Benachrichtigungseinstellungen
    final settingsResult = await getNotificationSettings(NoParams());
    
    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) async {
        if (!settings.isEnabled) {
          // Benachrichtigungen deaktiviert - lösche geplante Benachrichtigung
          await notificationService.cancelDailyNotification();
          return const Right(null);
        }

        // Hole ablaufende Lebensmittel (nächste 2 Tage)
        final foodsResult = await getExpiringFoods(
          const GetExpiringFoodsParams(daysAhead: 2),
        );

        return foodsResult.fold(
          (failure) => Left(failure),
          (foods) async {
            final notificationBody = _createNotificationBody(foods);
            
            if (notificationBody.isNotEmpty) {
              await notificationService.scheduleDailyNotification(
                time: settings.notificationTime,
                title: 'Lebensmittel-Erinnerung',
                body: notificationBody,
              );
            } else {
              // Keine ablaufenden Lebensmittel - trotzdem Benachrichtigung planen
              // für zukünftige Checks
              await notificationService.scheduleDailyNotification(
                time: settings.notificationTime,
                title: 'Alles frisch!',
                body: 'Keine Lebensmittel laufen in den nächsten 2 Tagen ab.',
              );
            }
            
            return const Right(null);
          },
        );
      },
    );
  }

  String _createNotificationBody(List<Food> foods) {
    if (foods.isEmpty) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final expired = <Food>[];
    final expiringToday = <Food>[];
    final expiringTomorrow = <Food>[];
    final expiringDayAfter = <Food>[];

    for (final food in foods) {
      if (food.expiryDate == null) continue;
      
      final expiryDate = DateTime(
        food.expiryDate!.year,
        food.expiryDate!.month,
        food.expiryDate!.day,
      );
      
      final daysDiff = expiryDate.difference(today).inDays;
      
      if (daysDiff < 0) {
        expired.add(food);
      } else if (daysDiff == 0) {
        expiringToday.add(food);
      } else if (daysDiff == 1) {
        expiringTomorrow.add(food);
      } else if (daysDiff == 2) {
        expiringDayAfter.add(food);
      }
    }

    final parts = <String>[];

    if (expired.isNotEmpty) {
      parts.add('❌ Abgelaufen: ${_foodListToString(expired)}');
    }
    if (expiringToday.isNotEmpty) {
      parts.add('⚠️ Heute: ${_foodListToString(expiringToday)}');
    }
    if (expiringTomorrow.isNotEmpty) {
      parts.add('🔔 Morgen: ${_foodListToString(expiringTomorrow)}');
    }
    if (expiringDayAfter.isNotEmpty) {
      parts.add('📅 Übermorgen: ${_foodListToString(expiringDayAfter)}');
    }

    return parts.join('\n');
  }

  String _foodListToString(List<Food> foods) {
    if (foods.length <= 3) {
      return foods.map((f) => f.name).join(', ');
    } else {
      final firstTwo = foods.take(2).map((f) => f.name).join(', ');
      final remaining = foods.length - 2;
      return '$firstTwo und $remaining weitere';
    }
  }
}