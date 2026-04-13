import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/features/ai_recipe/presentation/ai_import_screen.dart';
import 'package:instock/features/ai_recipe/presentation/ai_loading_screen.dart';
import 'package:instock/features/ai_recipe/presentation/ai_preview_screen.dart';
import 'package:instock/features/ai_recipe/presentation/tweak_ai_screen.dart';
import 'package:instock/features/home/presentation/home_screen.dart';
import 'package:instock/features/pantry/presentation/pantry_screen.dart';
import 'package:instock/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:instock/features/recipes/presentation/recipe_library_screen.dart';
import 'package:instock/features/shopping_list/presentation/shopping_list_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/list',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ShoppingListScreen()),
          ),
          GoRoute(
            path: '/recipes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RecipeLibraryScreen()),
          ),
          GoRoute(
            path: '/pantry',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PantryScreen()),
          ),
          GoRoute(
            path: '/ai',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AiImportScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/recipes/:recipeId',
        builder: (context, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['recipeId']!),
      ),
      GoRoute(
        path: '/ai/loading/:draftId',
        builder: (context, state) =>
            AiLoadingScreen(draftId: state.pathParameters['draftId']!),
      ),
      GoRoute(
        path: '/ai/preview/:draftId',
        builder: (context, state) =>
            AiPreviewScreen(draftId: state.pathParameters['draftId']!),
      ),
      GoRoute(
        path: '/ai/tweak/:draftId',
        builder: (context, state) =>
            TweakAiScreen(draftId: state.pathParameters['draftId']!),
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final destinations = const [
      ('/home', Icons.dashboard_rounded, 'Home'),
      ('/list', Icons.shopping_basket_rounded, 'List'),
      ('/recipes', Icons.menu_book_rounded, 'Recipes'),
      ('/pantry', Icons.kitchen_rounded, 'Pantry'),
      ('/ai', Icons.auto_awesome_rounded, 'AI'),
    ];
    final selectedIndex = destinations.indexWhere(
      (item) => location.startsWith(item.$1),
    );

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundAlt,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex < 0 ? 0 : selectedIndex,
          onTap: (index) => context.go(destinations[index].$1),
          items: [
            for (final destination in destinations)
              BottomNavigationBarItem(
                icon: Icon(destination.$2),
                label: destination.$3,
              ),
          ],
        ),
      ),
    );
  }
}
