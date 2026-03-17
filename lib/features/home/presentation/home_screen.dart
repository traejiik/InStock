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

    return AppScreen(
      title: 'InStock',
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tonight at a glance',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Your current list is ${(controller.progress * 100).round()}% complete, and your pantry still covers the basics.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: controller.progress,
                  backgroundColor: AppTheme.background,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _MetricPill(
                    label: 'Active items',
                    value: '${controller.shoppingItems.length}',
                  ),
                  const SizedBox(width: 10),
                  _MetricPill(
                    label: 'Pantry stock',
                    value: '${controller.pantryItems.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Frequent items',
          subtitle: 'Fast add staples based on your local shopping rhythm.',
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
              ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Quick recipe access',
          subtitle: 'Jump back into meals you viewed recently.',
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
                      width: 92,
                      height: 92,
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
          color: AppTheme.background.withValues(alpha: 0.4),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      color: AppTheme.cardAlt,
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title[0] : '?',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
