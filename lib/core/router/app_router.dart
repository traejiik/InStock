import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/features/pantry/screens/pantry_screen.dart';
import 'package:instock/features/pantry/screens/pantry_checkin_screen.dart';
import 'package:instock/features/onboarding/providers/onboarding_provider.dart';
import 'package:instock/features/onboarding/screens/onboarding_screen.dart';
import 'package:instock/features/recipes/screens/recipes_screen.dart';
import 'package:instock/features/recipes/screens/recipe_detail_screen.dart';
import 'package:instock/features/recipes/screens/import_recipe_screen.dart';
import 'package:instock/features/recipes/screens/add_recipe_screen.dart';
import 'package:instock/features/recipes/screens/recipe_review_screen.dart';
import 'package:instock/features/recipes/services/recipe_scraper.dart';
import 'package:instock/features/settings/screens/settings_screen.dart';
import 'package:instock/features/shopping/screens/shopping_screen.dart';
import 'package:instock/shared/widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      final onboardingComplete = ref.read(onboardingControllerProvider);
      final isOnboarding = state.uri.path == '/onboarding';

      if (!onboardingComplete && !isOnboarding) {
        return '/onboarding';
      }

      if (onboardingComplete && isOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (c, s) => const ShoppingScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/pantry', builder: (c, s) => const PantryScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recipes',
                builder: (c, s) => const RecipesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (c, s) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/recipes/import',
        builder: (c, s) => const ImportRecipeScreen(),
      ),
      GoRoute(
        path: '/recipes/add',
        builder: (c, s) {
          final tab = int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 1;
          return AddRecipeScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/recipes/review',
        builder: (c, s) {
          final extra =
              s.extra as ({ParsedRecipe parsed, String? editingId});
          return RecipeReviewScreen(
            parsed: extra.parsed,
            editingId: extra.editingId,
          );
        },
      ),
      GoRoute(
        path: '/recipes/:id',
        builder: (c, s) =>
            RecipeDetailScreen(recipeId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pantry/checkin',
        builder: (c, s) => const PantryCheckinScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
