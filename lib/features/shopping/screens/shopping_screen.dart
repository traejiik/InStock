import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/core/utils/unit_converter.dart';
import 'package:instock/data/database/app_database.dart';
import 'package:instock/data/models/app_models.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';
import 'package:instock/shared/widgets/category_picker.dart';
import 'package:instock/shared/widgets/segment_control.dart';
import 'package:instock/shared/widgets/unit_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/shopping_list_item.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  int _sortIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final db = ref.watch(appDatabaseProvider);
    final items = db.shoppingItems;
    final checkedCount = items.where((i) => i.checked).length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(total: items.length, inStock: checkedCount),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: SegmentControl(
                  labels: const ['By Category', 'By Recipe', 'All Items'],
                  selectedIndex: _sortIndex,
                  onChanged: (i) => setState(() => _sortIndex = i),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (items.isEmpty)
              SliverFillRemaining(
                child: _ShoppingEmptyState(
                  onAddItem: () => _showAddSheet(context),
                  onBrowseRecipes: () => context.go('/recipes'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: _buildList(db, items),
              ),
          ],
        ),
      ),
      floatingActionButton: items.isEmpty
          ? null
          : FloatingActionButton(
              heroTag: 'shopping_fab',
              onPressed: () => _showAddSheet(context),
              backgroundColor: colors.green,
              foregroundColor: onPrimary,
              elevation: 0,
              child: const Icon(Icons.add, size: 26),
            ),
    );
  }

  Widget _buildList(AppDatabase db, List<ShoppingItem> items) {
    if (_sortIndex == 2) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _buildItem(db, items[i]),
          childCount: items.length,
        ),
      );
    }

    // Group by category or recipe
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final ing = db.ingredientById(item.ingredientId);
      final key = _sortIndex == 0
          ? (ing?.category.label ?? 'Other')
          : (item.sourceRecipeId != null
                ? (db.recipeById(item.sourceRecipeId!)?.title ?? 'Unknown')
                : 'Manual');
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final sections = grouped.entries.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final section = sections[i];
        final ing = db.ingredientById(section.value.first.ingredientId);
        final emoji = _sortIndex == 0 ? (ing?.category.emoji ?? '📦') : '🍽️';
        return _Section(
          emoji: emoji,
          label: section.key,
          items: section.value,
          db: db,
          builder: (item) => _buildItem(db, item),
        );
      }, childCount: sections.length),
    );
  }

  Widget _buildItem(AppDatabase db, ShoppingItem item) {
    final ing = db.ingredientById(item.ingredientId);
    if (ing == null) return const SizedBox.shrink();
    final sourceRecipeName = item.sourceRecipeId != null
        ? db.recipeById(item.sourceRecipeId!)?.title
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ShoppingListItem(
        item: item,
        ingredient: ing,
        stockStatus: db.stockStatusForIngredient(item.ingredientId),
        sourceRecipeName: sourceRecipeName,
        onToggle: () =>
            ref.read(appDatabaseProvider).toggleShoppingItem(item.id),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final db = ref.read(appDatabaseProvider);
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    String selectedUnit = 'pcs';
    var selectedCategory = IngredientCategory.custom;
    String? nameError;
    String? qtyError;
    String? pantryHint;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void checkPantryHint(String value) {
            final name = value.trim();
            if (name.length < 2) {
              setLocal(() => pantryHint = null);
              return;
            }
            final normalized = name.toLowerCase();
            final ing = db.ingredients
                .where(
                  (i) =>
                      i.canonicalName.toLowerCase() == normalized ||
                      i.aliases.any((a) => a.toLowerCase() == normalized),
                )
                .firstOrNull;
            if (ing != null) {
              final pantryItem = db.pantryItemForIngredient(ing.id);
              if (pantryItem != null && pantryItem.quantity > 0) {
                setLocal(() {
                  pantryHint =
                      'You have ${UnitConverter.formatQty(pantryItem.quantity, pantryItem.unit)} in your pantry';
                  selectedCategory = ing.category;
                });
              } else {
                setLocal(() {
                  pantryHint = null;
                  selectedCategory = ing.category;
                });
              }
            } else {
              setLocal(() => pantryHint = null);
            }
          }

          void submit() {
            final name = nameCtrl.text.trim();
            final qty = double.tryParse(qtyCtrl.text);

            setLocal(() {
              nameError = name.length < 2
                  ? 'Name must be at least 2 characters'
                  : null;
              qtyError = (qtyCtrl.text.isEmpty || qty == null || qty <= 0)
                  ? 'Enter a valid quantity greater than 0'
                  : null;
            });

            if (name.length < 2 || qty == null || qty <= 0) return;

            final ing = db.findOrCreateIngredient(
              name,
              category: selectedCategory,
            );
            db.addOrIncrementShopping(
              ingredientId: ing.id,
              quantity: qty,
              unit: selectedUnit,
            );
            Navigator.pop(ctx);
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Item', style: AppTextStyles.headingMd),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Item name',
                      errorText: nameError,
                    ),
                    autofocus: true,
                    onChanged: checkPantryHint,
                  ),
                  if (pantryHint != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      pantryHint!,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.amber,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      errorText: qtyError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CategoryPicker(
                    selectedCategory: selectedCategory,
                    onChanged: (category) =>
                        setLocal(() => selectedCategory = category),
                  ),
                  const SizedBox(height: 12),
                  UnitPicker(
                    selectedUnit: selectedUnit,
                    onChanged: (u) => setLocal(() => selectedUnit = u),
                    allowCustom: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.green,
                        foregroundColor: onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: submit,
                      child: Text(
                        'Add to List',
                        style: AppTextStyles.label.copyWith(color: onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShoppingEmptyState extends StatelessWidget {
  final VoidCallback onAddItem;
  final VoidCallback onBrowseRecipes;
  const _ShoppingEmptyState({
    required this.onAddItem,
    required this.onBrowseRecipes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 260;
        final maxWidth = compact ? 520.0 : double.infinity;

        final addButton = ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.green,
            foregroundColor: onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onAddItem,
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Add Item',
            style: AppTextStyles.label.copyWith(color: onPrimary),
          ),
        );

        final recipeButton = ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.surface2,
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.border),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onBrowseRecipes,
          icon: const Icon(LucideIcons.bookOpen, size: 18),
          label: Text(
            'Add from Recipe',
            style: AppTextStyles.label.copyWith(color: colors.textPrimary),
          ),
        );

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 40,
              vertical: compact ? 12 : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.shoppingCart,
                    size: compact ? 36 : 56,
                    color: colors.textTertiary,
                  ),
                  SizedBox(height: compact ? 10 : 20),
                  Text('Your list is empty', style: AppTextStyles.headingMd),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Add items or pull from a recipe',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: compact ? 14 : 28),
                  if (compact)
                    Row(
                      children: [
                        Expanded(child: addButton),
                        const SizedBox(width: 10),
                        Expanded(child: recipeButton),
                      ],
                    )
                  else ...[
                    SizedBox(width: double.infinity, child: addButton),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: recipeButton),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final int inStock;

  const _Header({required this.total, required this.inStock});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shopping', style: AppTextStyles.displayLg),
          const SizedBox(height: 4),
          Text(
            '$total items · $inStock checked off',
            style: AppTextStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String emoji;
  final String label;
  final List<ShoppingItem> items;
  final AppDatabase db;
  final Widget Function(ShoppingItem) builder;

  const _Section({
    required this.emoji,
    required this.label,
    required this.items,
    required this.db,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text('$emoji ', style: const TextStyle(fontSize: 16)),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surface3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${items.length}', style: AppTextStyles.caption),
              ),
            ],
          ),
        ),
        ...items.map(builder),
      ],
    );
  }
}
