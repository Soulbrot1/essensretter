import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';
import '../bloc/food_state.dart';

class ExpiryFilterChips extends StatelessWidget {
  const ExpiryFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        final activeFilter = state is FoodLoaded ? state.activeFilter : null;

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(
                context: context,
                label: 'Alle',
                days: null,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: 'Heute',
                days: 0,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: 'Morgen',
                days: 1,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: 'Übermorgen',
                days: 2,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: '3 Tage',
                days: 3,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: '4 Tage',
                days: 4,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: '5 Tage',
                days: 5,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: '6 Tage',
                days: 6,
                activeFilter: activeFilter,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context: context,
                label: '7 Tage',
                days: 7,
                activeFilter: activeFilter,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required int? days,
    required int? activeFilter,
  }) {
    final isSelected = days == activeFilter;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        context.read<FoodBloc>().add(
          FilterFoodsByExpiryEvent(selected ? days : null),
        );
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}
