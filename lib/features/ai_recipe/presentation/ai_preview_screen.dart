import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class AiPreviewScreen extends ConsumerWidget {
  const AiPreviewScreen({super.key, required this.draftId});

  final String draftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final draft = controller.draftById(draftId);

    return DefaultTabController(
      length: 2,
      child: AppScreen(
        title: 'AI Recipe Preview',
        showBack: true,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Image.network(
                  draft.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: AppTheme.cardAlt,
                    alignment: Alignment.center,
                    child: Text(
                      draft.title,
                      style: Theme.of(context).textTheme.headlineMedium,
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
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Text(
                    draft.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const TabBar(
              indicatorColor: AppTheme.accent,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: [
                Tab(text: 'Ingredients'),
                Tab(text: 'Instructions'),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                ListView(
                  children: [
                    for (final ingredient in draft.ingredients)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.accent,
                        ),
                        title: Text(ingredient.name),
                        subtitle: Text(
                          '${ingredient.quantity} ${ingredient.unit.shortLabel}',
                        ),
                      ),
                  ],
                ),
                ListView(
                  children: [
                    for (var i = 0; i < draft.steps.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.accentSoft,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(draft.steps[i]),
                      ),
                  ],
                ),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.saveRecipe(draft.toRecipeDetail());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recipe saved to your library.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Save to library'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await controller.addRecipeIngredients(
                        draft.toRecipeDetail(),
                        missingOnly: false,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ingredients added to your shopping list.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Add ingredients to list'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await controller.regenerate(draftId);
                          if (context.mounted) {
                            context.go('/ai/loading/$draftId');
                          }
                        },
                        child: const Text('Regenerate'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => context.push('/ai/tweak/$draftId'),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Tweak with AI'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
