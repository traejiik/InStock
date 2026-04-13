import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final topFrequent = controller.frequentItems.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final recentRecipes = controller.recentRecipes.take(3).toList();
    final checkedCount = controller.shoppingItems
        .where((item) => item.checked)
        .length;
    final pantryLinkedCount = controller.shoppingItems
        .where((item) => item.pantryLinked)
        .length;

    return AppScreen(
      title: 'InStock',
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan tonight with less kitchen guesswork.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Your pantry, active list, and recent recipes are lined up so the next meal feels obvious instead of improvised.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: controller.progress,
                  backgroundColor: AppTheme.cardAlt,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(controller.progress * 100).round()}% of this trip is already checked off.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _MetricPill(
                    label: 'Items left',
                    value: '${controller.shoppingItems.length - checkedCount}',
                  ),
                  const SizedBox(width: 10),
                  _MetricPill(
                    label: 'Pantry stock',
                    value: '${controller.pantryItems.length}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MetricPill(
                    label: 'Recipes saved',
                    value: '${controller.recipes.length}',
                  ),
                  const SizedBox(width: 10),
                  _MetricPill(
                    label: 'Linked items',
                    value: '$pantryLinkedCount',
                  ),
                ],
              ),
            ],
          ),
        ),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.playlist_add_rounded,
                  label: 'Build list',
                  onTap: () => context.go('/list'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Get AI help',
                  onTap: () => context.go('/ai'),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Frequent staples',
          subtitle: 'Fast-add the items your kitchen keeps asking for.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in topFrequent.take(6))
              ActionChip(
                label: Text('${item.key}  ·  ${item.value}'),
                onPressed: () async {
                  await controller.addOrMergeItem(
                    GroceryItem(
                      id: 'shop-${DateTime.now().microsecondsSinceEpoch}',
                      name: item.key,
                      normalizedName: normalizeName(item.key),
                      category: AisleCategory.produce,
                      quantity: 1,
                      unit: IngredientUnit.item,
                      checked: false,
                      source: 'Frequent items',
                      pantryLinked: false,
                    ),
                  );
                },
                backgroundColor: AppTheme.card,
                side: const BorderSide(color: AppTheme.border),
              ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Cook from what is already here',
          subtitle: 'Recent recipes stay close to the planning loop.',
          trailing: TextButton(
            onPressed: () => context.go('/recipes'),
            child: const Text('See all'),
          ),
        ),
        for (final recipe in recentRecipes)
          GestureDetector(
            onTap: () => context.push('/recipes/${recipe.id}'),
            child: GlassCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      recipe.imageUrl,
                      width: 96,
                      height: 112,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _ImageFallback(title: recipe.title),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${recipe.prepTimeMinutes} min • ${recipe.difficulty.label}',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final tag in recipe.tags.take(2))
                              Chip(
                                label: Text(tag),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppTheme.surfaceTint,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceTint,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.olive),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 112,
      color: AppTheme.cardAlt,
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title[0] : '?',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
