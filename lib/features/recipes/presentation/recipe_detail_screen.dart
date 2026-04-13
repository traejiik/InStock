import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late int servings;

  @override
  void initState() {
    super.initState();
    final recipe = ref.read(appControllerProvider).recipeById(widget.recipeId);
    servings = recipe.servings;
    ref.read(appControllerProvider).markViewed(widget.recipeId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final recipe = controller.recipeById(widget.recipeId).scaledTo(servings);

    return AppScreen(
      title: recipe.title,
      showBack: true,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            recipe.imageUrl,
            height: 230,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 230,
              color: AppTheme.cardAlt,
              alignment: Alignment.center,
              child: Text(
                recipe.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatBlock(
                    label: 'Time',
                    value: '${recipe.prepTimeMinutes}m',
                  ),
                  const SizedBox(width: 10),
                  _StatBlock(
                    label: 'Difficulty',
                    value: recipe.difficulty.label,
                  ),
                  const SizedBox(width: 10),
                  _StatBlock(label: 'Servings', value: '$servings'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: servings > 1
                        ? () => setState(() => servings -= 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => setState(() => servings += 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(recipe.notes, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        SectionHeader(
          title: 'Ingredients',
          subtitle: 'Tap into your pantry-aware shopping flow.',
          trailing: Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await controller.addRecipeIngredients(
                    recipe,
                    missingOnly: false,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All ingredients added to your list.'),
                      ),
                    );
                  }
                },
                child: const Text('Add all'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await controller.addRecipeIngredients(
                    recipe,
                    missingOnly: true,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Only missing ingredients were added.'),
                      ),
                    );
                  }
                },
                child: const Text('Add missing'),
              ),
            ],
          ),
        ),
        for (final ingredient in recipe.ingredients)
          _IngredientTile(ingredient: ingredient, controller: controller),
        const SizedBox(height: 8),
        const SectionHeader(
          title: 'Instructions',
          subtitle: 'Simple steps designed for shopping-list handoff.',
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < recipe.steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.accentSoft,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recipe.steps[i],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                if (i != recipe.steps.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final draftId = await controller.createDraftFromRecipe(recipe);
            if (context.mounted) context.push('/ai/tweak/$draftId');
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Tweak with AI'),
        ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient, required this.controller});

  final RecipeIngredient ingredient;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final pantryQty = controller.quantityFor(
      ingredient.normalizedName,
      ingredient.unit,
    );
    final status = pantryQty >= ingredient.quantity
        ? PantryMatchStatus.enough
        : pantryQty > 0
        ? PantryMatchStatus.partial
        : PantryMatchStatus.missing;
    final color = switch (status) {
      PantryMatchStatus.enough => AppTheme.success,
      PantryMatchStatus.partial => AppTheme.warning,
      PantryMatchStatus.missing => AppTheme.accent,
    };

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${ingredient.quantity} ${ingredient.unit.shortLabel} • ${ingredient.category.title}',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
