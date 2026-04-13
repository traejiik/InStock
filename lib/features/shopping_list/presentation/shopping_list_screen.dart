import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);

    return AppScreen(
      title: 'Shopping List',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      children: [
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip progress',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${controller.shoppingItems.where((item) => item.checked).length} of ${controller.shoppingItems.length} checked off. Grouped by aisle so the trip stays fast.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.shoppingItems.any((item) => item.checked)
                ? controller.moveCheckedItemsToPantry
                : null,
            child: const Text('Move checked items to pantry'),
          ),
        ),
        const SizedBox(height: 18),
        for (final entry in controller.groupedItems.entries) ...[
          SectionHeader(
            title: entry.key.title,
            subtitle:
                '${entry.value.length} item${entry.value.length == 1 ? '' : 's'} in this aisle',
          ),
          for (final item in entry.value) _ShoppingItemTile(item: item),
        ],
        if (controller.shoppingItems.isEmpty)
          const GlassCard(
            child: Text(
              'Your list is empty. Add a staple or pull ingredients from a recipe.',
            ),
          ),
      ],
    );
  }

  Future<void> _showAddItemSheet(
    BuildContext context,
    AppController controller,
  ) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    var category = AisleCategory.produce;
    var unit = IngredientUnit.item;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundAlt,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add grocery item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Item name'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<IngredientUnit>(
                          initialValue: unit,
                          items: [
                            for (final value in IngredientUnit.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.shortLabel),
                              ),
                          ],
                          onChanged: (value) =>
                              setModalState(() => unit = value ?? unit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AisleCategory>(
                    initialValue: category,
                    items: [
                      for (final value in AisleCategory.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.title),
                        ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => category = value ?? category),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        await controller.addOrMergeItem(
                          GroceryItem(
                            id: 'shop-${DateTime.now().microsecondsSinceEpoch}',
                            name: nameController.text.trim(),
                            normalizedName: normalizeName(nameController.text),
                            category: category,
                            quantity:
                                double.tryParse(quantityController.text) ?? 1,
                            unit: unit,
                            checked: false,
                            source: 'Manual add',
                            pantryLinked: false,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Add to list'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ShoppingItemTile extends ConsumerWidget {
  const _ShoppingItemTile({required this.item});

  final GroceryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Checkbox(
            value: item.checked,
            activeColor: AppTheme.accent,
            checkColor: AppTheme.background,
            onChanged: (_) => controller.toggleItem(item.id),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: item.checked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ${item.unit.shortLabel} • ${item.source}',
                ),
              ],
            ),
          ),
          if (item.pantryLinked)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.oliveSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Pantry',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppTheme.olive),
              ),
            ),
          IconButton(
            onPressed: () => _showQuantityDialog(context, controller, item),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuantityDialog(
    BuildContext context,
    AppController controller,
    GroceryItem item,
  ) async {
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Update ${item.name}'),
        content: TextField(
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Quantity (${item.unit.shortLabel})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.updateQuantity(
                item.id,
                double.tryParse(quantityController.text) ?? item.quantity,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
