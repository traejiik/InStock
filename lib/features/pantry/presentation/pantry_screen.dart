import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);

    return AppScreen(
      title: 'Pantry',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPantryEditor(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Stock item'),
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
                      'Inventory health',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You currently track ${controller.pantryItems.length} pantry items locally across ${controller.pantryItems.map((item) => item.category).toSet().length} categories.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppTheme.oliveSoft,
                ),
                child: Text(
                  'Stable stock',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppTheme.olive),
                ),
              ),
            ],
          ),
        ),
        for (final item in controller.pantryItems)
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} ${item.unit.shortLabel} • ${item.category.title}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Updated ${_formatUpdatedAt(item.updatedAt)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _showPantryEditor(context, controller, existing: item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => controller.removeItem(item.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    final difference = DateTime.now().difference(updatedAt).inDays;
    if (difference <= 0) return 'today';
    if (difference == 1) return 'yesterday';
    return '$difference days ago';
  }

  Future<void> _showPantryEditor(
    BuildContext context,
    AppController controller, {
    PantryItem? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name);
    final quantityController = TextEditingController(
      text: existing?.quantity.toString() ?? '1',
    );
    var category = existing?.category ?? AisleCategory.pantry;
    var unit = existing?.unit ?? IngredientUnit.item;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundAlt,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
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
                  existing == null ? 'Add pantry item' : 'Edit pantry item',
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
                      DropdownMenuItem(value: value, child: Text(value.title)),
                  ],
                  onChanged: (value) =>
                      setModalState(() => category = value ?? category),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.saveItem(
                        PantryItem(
                          id:
                              existing?.id ??
                              'pantry-${DateTime.now().microsecondsSinceEpoch}',
                          name: nameController.text.trim(),
                          normalizedName: normalizeName(nameController.text),
                          quantity:
                              double.tryParse(quantityController.text) ?? 1,
                          unit: unit,
                          category: category,
                          updatedAt: DateTime.now(),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      existing == null ? 'Add stock' : 'Save changes',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
