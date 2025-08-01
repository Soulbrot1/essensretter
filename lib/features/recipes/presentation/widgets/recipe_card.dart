import 'package:flutter/material.dart';
import '../../domain/entities/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onBookmark;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onBookmark,
                  icon: Icon(
                    recipe.isBookmarked 
                        ? Icons.bookmark 
                        : Icons.bookmark_border,
                    color: recipe.isBookmarked 
                        ? Colors.orange 
                        : Colors.grey,
                  ),
                  tooltip: recipe.isBookmarked 
                      ? 'Aus Favoriten entfernen'
                      : 'Zu Favoriten hinzufügen',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Kochzeit: ${recipe.cookingTime}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIngredientSection(
              context,
              'Vorhanden:',
              recipe.vorhanden,
              Colors.green,
              Icons.check_circle,
            ),
            if (recipe.ueberpruefen.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildIngredientSection(
                context,
                'Überprüfen/Kaufen:',
                recipe.ueberpruefen,
                Colors.orange,
                Icons.help_outline,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Anleitung:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              recipe.instructions,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientSection(
    BuildContext context,
    String title,
    List<String> ingredients,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ingredients
              .map((ingredient) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      ingredient,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color.withValues(alpha: 0.8),
                          ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}