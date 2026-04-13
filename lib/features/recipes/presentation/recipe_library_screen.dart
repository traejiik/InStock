import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class RecipeLibraryScreen extends ConsumerStatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  ConsumerState<RecipeLibraryScreen> createState() =>
      _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends ConsumerState<RecipeLibraryScreen> {
  String query = '';
  String selectedTag = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final tags = {'All', ...controller.recipes.expand((recipe) => recipe.tags)};
    final filtered = controller.recipes.where((recipe) {
      final matchesQuery =
          query.isEmpty ||
          recipe.title.toLowerCase().contains(query.toLowerCase());
      final matchesTag =
          selectedTag == 'All' || recipe.tags.contains(selectedTag);
      return matchesQuery && matchesTag;
    }).toList()..sort((a, b) => a.title.compareTo(b.title));

    return AppScreen(
      title: 'Recipe Library',
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse what fits the kitchen you already have.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Search, filter, and pull recipes into your list without losing sight of pantry reality.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search recipes',
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final tag in tags)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tag),
                    selected: selectedTag == tag,
                    onSelected: (_) => setState(() => selectedTag = tag),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final recipe in filtered)
          GestureDetector(
            onTap: () => context.push('/recipes/${recipe.id}'),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Image.network(
                          recipe.imageUrl,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 170,
                                color: AppTheme.cardAlt,
                                alignment: Alignment.center,
                                child: Text(
                                  recipe.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Text(
                            recipe.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MetaBadge(
                        icon: Icons.schedule,
                        label: '${recipe.prepTimeMinutes} min',
                      ),
                      const SizedBox(width: 8),
                      _MetaBadge(
                        icon: Icons.local_fire_department,
                        label: recipe.difficulty.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in recipe.tags) Chip(label: Text(tag)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accentStrong),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
