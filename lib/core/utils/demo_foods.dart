import 'package:uuid/uuid.dart';
import '../../features/food_tracking/domain/entities/food.dart';

class DemoFoods {
  static const String _demoLoadedKey = 'demo_foods_loaded';

  static List<Food> createDemoFoods() {
    final now = DateTime.now();
    const uuid = Uuid();

    return [
      Food(
        id: uuid.v4(),
        name: 'Milch',
        expiryDate: now.add(const Duration(days: 1)), // Morgen
        addedDate: now.subtract(const Duration(days: 2)),
        category: 'Milchprodukte',
      ),
      Food(
        id: uuid.v4(),
        name: 'Bananen',
        expiryDate: now.add(const Duration(days: 3)), // In 3 Tagen
        addedDate: now.subtract(const Duration(days: 1)),
        category: 'Obst',
      ),
      Food(
        id: uuid.v4(),
        name: 'Joghurt',
        expiryDate: now.add(const Duration(days: 7)), // In einer Woche
        addedDate: now,
        category: 'Milchprodukte',
      ),
    ];
  }

  static String get demoLoadedKey => _demoLoadedKey;
}
