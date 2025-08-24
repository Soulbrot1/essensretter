import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_state.dart';

class PersistenceInfoWidget extends StatelessWidget {
  const PersistenceInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        if (state is! FoodLoaded) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.save, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${state.foods.length} Lebensmittel gespeichert • Daten bleiben nach App-Neustart erhalten',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
