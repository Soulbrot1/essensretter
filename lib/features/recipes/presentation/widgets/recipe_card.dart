import 'package:flutter/material.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/recipe_calculator.dart';
import 'serving_size_slider.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onBookmark;

  const RecipeCard({super.key, required this.recipe, this.onBookmark});

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isExpanded = false;
  late Recipe _currentRecipe;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
  }

  void _updateServings(int newServings) {
    setState(() {
      _currentRecipe = RecipeCalculator.scaleRecipe(widget.recipe, newServings);
    });
  }

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
                    _currentRecipe.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          Theme.of(context).textTheme.headlineSmall!.fontSize! *
                          0.8,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  tooltip: _isExpanded ? 'Einklappen' : 'Ausklappen',
                ),
                IconButton(
                  onPressed: widget.onBookmark,
                  icon: Icon(
                    widget.recipe.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: widget.recipe.isBookmarked
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  tooltip: widget.recipe.isBookmarked
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
                  'Kochzeit: ${_currentRecipe.cookingTime}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              // Serving Size Slider
              ServingSizeSlider(
                currentServings: _currentRecipe.servings,
                onServingsChanged: _updateServings,
              ),
              const SizedBox(height: 16),
              _buildIngredientSection(
                context,
                'Vorhanden:',
                _currentRecipe.vorhanden.map((i) => i.displayText).toList(),
                Colors.green,
                Icons.check_circle,
              ),
              if (_currentRecipe.ueberpruefen.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildIngredientSection(
                  context,
                  'Überprüfen/Kaufen:',
                  _currentRecipe.ueberpruefen
                      .map((i) => i.displayText)
                      .toList(),
                  Colors.orange,
                  Icons.help_outline,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Anleitung:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildInstructionSteps(context),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInstructionSteps(BuildContext context) {
    final steps = _parseInstructions(_currentRecipe.instructions);
    return steps.asMap().entries.map((entry) {
      final stepNumber = entry.key + 1;
      final stepText = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildStepContent(context, stepText)),
          ],
        ),
      );
    }).toList();
  }

  List<String> _parseInstructions(String instructions) {
    final steps = <String>[];

    // Split by newlines first to preserve structure
    final lines = instructions.split('\n');

    String currentStep = '';
    for (final line in lines) {
      final trimmedLine = line.trim();

      // Check if it's a numbered step (1., 2., etc.)
      if (RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
        // Save previous step if exists
        if (currentStep.isNotEmpty) {
          steps.add(currentStep.trim());
        }
        // Start new step
        currentStep = trimmedLine;
      } else if (trimmedLine.isNotEmpty) {
        // Add to current step (could be a bullet point or continuation)
        if (currentStep.isNotEmpty) {
          currentStep += '\n$trimmedLine';
        } else {
          currentStep = trimmedLine;
        }
      }
    }

    // Add the last step
    if (currentStep.isNotEmpty) {
      steps.add(currentStep.trim());
    }

    // If no steps found, return the whole instruction as one step
    if (steps.isEmpty && instructions.trim().isNotEmpty) {
      steps.add(instructions.trim());
    }

    return steps;
  }

  Widget _buildStepContent(BuildContext context, String stepText) {
    // Check if the step contains bullet points
    if (stepText.contains('•') || stepText.contains('\n')) {
      final lines = stepText.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final trimmedLine = line.trim();
          if (trimmedLine.isEmpty) return const SizedBox.shrink();

          // Format main step title
          if (RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                trimmedLine.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            );
          }

          // Format bullet points
          if (trimmedLine.startsWith('•')) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      trimmedLine.substring(1).trim(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          // Regular text
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              trimmedLine,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }).toList(),
      );
    }

    // Simple text without formatting
    return Text(stepText, style: Theme.of(context).textTheme.bodyMedium);
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
              .map(
                (ingredient) => Container(
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
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
