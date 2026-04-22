import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/shared/widgets/fab_menu.dart';
import 'package:instock/shared/widgets/sort_chip_row.dart';
import 'package:instock/shared/widgets/toggle_row.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  bool _makeableOnly = false;
  int _tagIndex = 0;

  static const _tags = ['All', 'Dinner', 'Quick', 'Vegetarian', 'Asian'];

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    var recipes = _makeableOnly
        ? db.recipes.where((r) => db.isRecipeMakeable(r.id)).toList()
        : db.recipes;

    if (_tagIndex > 0) {
      final tag = _tags[_tagIndex].toLowerCase();
      if (tag == 'quick') {
        recipes = recipes.where((r) => r.cookMinutes <= 20).toList();
      } else {
        recipes = recipes.where((r) => r.tags.contains(tag)).toList();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recipes', style: AppTextStyles.displayLg),
                          Text(
                            '${db.recipes.length} saved',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: ToggleRow(
                  icon: Icons.auto_awesome,
                  iconColor: AppColors.purple,
                  iconBg: AppColors.purpleDim,
                  title: 'Makeable Now',
                  subtitle: 'Filter to recipes you can cook today',
                  value: _makeableOnly,
                  onChanged: (v) => setState(() => _makeableOnly = v),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: SortChipRow(
                  chips: _tags,
                  selectedIndex: _tagIndex,
                  onChanged: (i) => setState(() => _tagIndex = i),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (recipes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _makeableOnly ? 'No makeable recipes with current pantry 😔' : 'No recipes yet 📖',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: _buildGrid(db, recipes),
              ),
          ],
        ),
      ),
      floatingActionButton: FabMenu(
        options: [
          FabOption(
            emoji: '✍️',
            label: 'Write recipe',
            background: AppColors.surface2,
            textColor: AppColors.textPrimary,
            onTap: () => context.push('/recipes/import'),
          ),
          FabOption(
            emoji: '🔗',
            label: 'Import URL',
            background: AppColors.surface2,
            textColor: AppColors.textPrimary,
            onTap: () => context.push('/recipes/import'),
          ),
          FabOption(
            emoji: '✨',
            label: 'AI Generate ☁️',
            background: AppColors.purpleDim,
            textColor: AppColors.purple,
            onTap: () => context.push('/recipes/import'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(AppDatabase db, List<Recipe> recipes) {
    if (recipes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final first = recipes.first;
    final rest = recipes.skip(1).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        RecipeCard(
          recipe: first,
          isMakeable: db.isRecipeMakeable(first.id),
          missingCount: db.missingCountForRecipe(first.id),
          onTap: () => context.push('/recipes/${first.id}'),
        ),
        const SizedBox(height: 12),
        if (rest.isNotEmpty)
          _StaggeredGrid(
            recipes: rest,
            db: db,
            onTap: (r) => context.push('/recipes/${r.id}'),
          ),
      ]),
    );
  }
}

class _StaggeredGrid extends StatelessWidget {
  final List<Recipe> recipes;
  final AppDatabase db;
  final void Function(Recipe) onTap;

  const _StaggeredGrid({
    required this.recipes,
    required this.db,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pairs = <List<Recipe>>[];
    for (var i = 0; i < recipes.length; i += 2) {
      pairs.add(recipes.sublist(i, (i + 2).clamp(0, recipes.length)));
    }

    return Column(
      children: pairs.map((pair) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RecipeCardSm(
                  recipe: pair[0],
                  isMakeable: db.isRecipeMakeable(pair[0].id),
                  missingCount: db.missingCountForRecipe(pair[0].id),
                  onTap: () => onTap(pair[0]),
                ),
              ),
              if (pair.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: RecipeCardSm(
                    recipe: pair[1],
                    isMakeable: db.isRecipeMakeable(pair[1].id),
                    missingCount: db.missingCountForRecipe(pair[1].id),
                    onTap: () => onTap(pair[1]),
                  ),
                ),
              ] else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      }).toList(),
    );
  }
}
