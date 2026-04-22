import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/features/shopping/screens/shopping_screen.dart';
import 'package:instock/features/pantry/screens/pantry_screen.dart';
import 'package:instock/features/pantry/screens/pantry_checkin_screen.dart';
import 'package:instock/features/recipes/screens/recipes_screen.dart';
import 'package:instock/features/recipes/screens/recipe_detail_screen.dart';
import 'package:instock/features/recipes/screens/import_recipe_screen.dart';
import 'package:instock/features/settings/screens/settings_screen.dart';
import 'package:instock/shared/widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (c, s) => const ShoppingScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/pantry', builder: (c, s) => const PantryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/recipes', builder: (c, s) => const RecipesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ]),
      ],
    ),
    GoRoute(
      path: '/recipes/import',
      builder: (c, s) => const ImportRecipeScreen(),
    ),
    GoRoute(
      path: '/recipes/:id',
      builder: (c, s) => RecipeDetailScreen(
        recipeId: s.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/pantry/checkin',
      builder: (c, s) => const PantryCheckinScreen(),
    ),
  ],
);
