import 'package:flutter/material.dart';
import '../../domain/services/recipe_calculator.dart';

class ServingSizeSlider extends StatelessWidget {
  final int currentServings;
  final ValueChanged<int> onServingsChanged;
  final bool enabled;

  const ServingSizeSlider({
    super.key,
    required this.currentServings,
    required this.onServingsChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final recommendedServings = RecipeCalculator.getRecommendedServings();
    final minServings = recommendedServings.first;
    final maxServings = recommendedServings.last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portionen',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  RecipeCalculator.formatServings(currentServings),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: currentServings.toDouble(),
              min: minServings.toDouble(),
              max: maxServings.toDouble(),
              divisions: recommendedServings.length - 1,
              onChanged: enabled
                  ? (value) {
                      final newServings = _findNearestRecommendedServing(
                        value.round(),
                      );
                      if (newServings != currentServings) {
                        onServingsChanged(newServings);
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Findet die nächstgelegene empfohlene Personenanzahl
  int _findNearestRecommendedServing(int value) {
    final recommendedServings = RecipeCalculator.getRecommendedServings();

    // Finde den Wert in der Liste oder den nächstgelegenen
    if (recommendedServings.contains(value)) {
      return value;
    }

    // Finde den nächstgelegenen Wert
    int nearest = recommendedServings.first;
    int minDifference = (value - nearest).abs();

    for (final serving in recommendedServings) {
      final difference = (value - serving).abs();
      if (difference < minDifference) {
        minDifference = difference;
        nearest = serving;
      }
    }

    return nearest;
  }
}
