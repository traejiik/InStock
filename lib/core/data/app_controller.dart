import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instock/core/data/seed_data.dart';
import 'package:instock/core/models/app_models.dart';

const _storageKey = 'instock_state_v1';

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  PersistedState load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return SeedData.build();
    }
    return PersistedState.fromJsonString(raw);
  }

  Future<void> save(PersistedState state) async {
    await _prefs.setString(_storageKey, state.toJsonString());
  }
}

abstract class RecipeRepository {
  List<RecipeDetail> get recipes;
  RecipeDetail recipeById(String id);
  List<RecipeDetail> get recentRecipes;
  void markViewed(String id);
  Future<void> saveRecipe(RecipeDetail recipe);
}

abstract class PantryRepository {
  List<PantryItem> get pantryItems;
  double quantityFor(String normalizedName, IngredientUnit unit);
  Future<void> saveItem(PantryItem item);
  Future<void> removeItem(String id);
}

abstract class ShoppingListRepository {
  List<GroceryItem> get shoppingItems;
  Map<String, int> get frequentItems;
  double get progress;
  Map<AisleCategory, List<GroceryItem>> get groupedItems;
  Future<void> addOrMergeItem(GroceryItem item);
  Future<void> toggleItem(String id);
  Future<void> updateQuantity(String id, double quantity);
  Future<void> addRecipeIngredients(
    RecipeDetail recipe, {
    required bool missingOnly,
  });
  Future<void> moveCheckedItemsToPantry();
}

abstract class AiRecipeService {
  List<AiRecipeDraft> get drafts;
  List<ChatMessage> messagesFor(String draftId);
  Future<String> createUrlDraft(String url);
  Future<String> createPromptDraft(String prompt);
  Future<String> createDraftFromRecipe(RecipeDetail recipe);
  Future<void> runGeneration(String draftId);
  Future<void> regenerate(String draftId);
  Future<void> sendMessage(String draftId, String text);
}

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError(
    'localStoreProvider must be overridden at app bootstrap.',
  );
});

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController(ref.watch(localStoreProvider));
});

class AppController extends ChangeNotifier
    implements
        RecipeRepository,
        PantryRepository,
        ShoppingListRepository,
        AiRecipeService {
  AppController(this._store) : _state = _store.load() {
    unawaited(_persist());
  }

  final LocalStore _store;
  PersistedState _state;

  PersistedState get state => _state;

  Future<void> _persist() => _store.save(_state);

  void _replaceState(PersistedState next) {
    _state = next;
    notifyListeners();
    unawaited(_persist());
  }

  @override
  List<RecipeDetail> get recipes => _state.recipes;

  @override
  RecipeDetail recipeById(String id) =>
      recipes.firstWhere((recipe) => recipe.id == id);

  @override
  List<RecipeDetail> get recentRecipes => [
    for (final id in _state.recentRecipeIds)
      recipes.firstWhere(
        (recipe) => recipe.id == id,
        orElse: () => recipes.first,
      ),
  ];

  @override
  void markViewed(String id) {
    final next = [
      id,
      ..._state.recentRecipeIds.where((item) => item != id),
    ].take(5).toList();
    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: _state.pantryItems,
        shoppingItems: _state.shoppingItems,
        recentRecipeIds: next,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  Future<void> saveRecipe(RecipeDetail recipe) async {
    final existing = [
      ..._state.recipes.where((item) => item.id != recipe.id),
      recipe,
    ];
    _replaceState(
      PersistedState(
        recipes: existing,
        pantryItems: _state.pantryItems,
        shoppingItems: _state.shoppingItems,
        recentRecipeIds: [
          recipe.id,
          ..._state.recentRecipeIds.where((item) => item != recipe.id),
        ],
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  List<PantryItem> get pantryItems =>
      [..._state.pantryItems]..sort((a, b) => a.name.compareTo(b.name));

  @override
  double quantityFor(String normalizedName, IngredientUnit unit) {
    final match = pantryItems.where(
      (item) => item.normalizedName == normalizedName && item.unit == unit,
    );
    return match.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Future<void> saveItem(PantryItem item) async {
    final items = [
      ..._state.pantryItems.where((current) => current.id != item.id),
      item,
    ];
    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: items,
        shoppingItems: _state.shoppingItems,
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  Future<void> removeItem(String id) async {
    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: _state.pantryItems.where((item) => item.id != id).toList(),
        shoppingItems: _state.shoppingItems,
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  List<GroceryItem> get shoppingItems => _state.shoppingItems;

  @override
  Map<String, int> get frequentItems => _state.frequentItemCounts;

  @override
  double get progress {
    if (_state.shoppingItems.isEmpty) return 0;
    final checked = _state.shoppingItems.where((item) => item.checked).length;
    return checked / _state.shoppingItems.length;
  }

  @override
  Map<AisleCategory, List<GroceryItem>> get groupedItems {
    final map = <AisleCategory, List<GroceryItem>>{};
    for (final category in AisleCategory.values) {
      final items =
          shoppingItems.where((item) => item.category == category).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      if (items.isNotEmpty) {
        map[category] = items;
      }
    }
    return map;
  }

  @override
  Future<void> addOrMergeItem(GroceryItem item) async {
    final items = [..._state.shoppingItems];
    final index = items.indexWhere(
      (current) =>
          current.normalizedName == item.normalizedName &&
          current.unit == item.unit &&
          current.category == item.category,
    );
    if (index >= 0) {
      final merged = items[index];
      items[index] = merged.copyWith(
        quantity: double.parse(
          (merged.quantity + item.quantity).toStringAsFixed(2),
        ),
        source: merged.source == item.source
            ? merged.source
            : '${merged.source}, ${item.source}',
      );
    } else {
      items.add(item);
    }

    final frequent = Map<String, int>.from(_state.frequentItemCounts);
    frequent[item.name] = (frequent[item.name] ?? 0) + 1;

    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: _state.pantryItems,
        shoppingItems: items,
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: frequent,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  Future<void> toggleItem(String id) async {
    final items = [
      for (final item in _state.shoppingItems)
        if (item.id == id) item.copyWith(checked: !item.checked) else item,
    ];
    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: _state.pantryItems,
        shoppingItems: items,
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  Future<void> updateQuantity(String id, double quantity) async {
    final items = [
      for (final item in _state.shoppingItems)
        if (item.id == id) item.copyWith(quantity: quantity) else item,
    ];
    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: _state.pantryItems,
        shoppingItems: items,
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  Future<void> addRecipeIngredients(
    RecipeDetail recipe, {
    required bool missingOnly,
  }) async {
    for (final ingredient in recipe.ingredients) {
      final pantryQty = quantityFor(ingredient.normalizedName, ingredient.unit);
      if (missingOnly && pantryQty >= ingredient.quantity) {
        continue;
      }
      final quantity = missingOnly
          ? (ingredient.quantity - pantryQty)
                .clamp(0.0, ingredient.quantity)
                .toDouble()
          : ingredient.quantity;
      if (quantity == 0) continue;
      await addOrMergeItem(
        GroceryItem(
          id: 'shop-${DateTime.now().microsecondsSinceEpoch}-${ingredient.normalizedName}',
          name: ingredient.name,
          normalizedName: ingredient.normalizedName,
          category: ingredient.category,
          quantity: quantity,
          unit: ingredient.unit,
          checked: false,
          source: recipe.title,
          pantryLinked: true,
        ),
      );
    }
  }

  @override
  Future<void> moveCheckedItemsToPantry() async {
    final checkedItems = _state.shoppingItems
        .where((item) => item.checked)
        .toList();
    var pantry = [..._state.pantryItems];
    for (final item in checkedItems) {
      final index = pantry.indexWhere(
        (existing) =>
            existing.normalizedName == item.normalizedName &&
            existing.unit == item.unit,
      );
      if (index >= 0) {
        final current = pantry[index];
        pantry[index] = current.copyWith(
          quantity: double.parse(
            (current.quantity + item.quantity).toStringAsFixed(2),
          ),
          updatedAt: DateTime.now(),
        );
      } else {
        pantry.add(
          PantryItem(
            id: 'pantry-${DateTime.now().microsecondsSinceEpoch}-${item.normalizedName}',
            name: item.name,
            normalizedName: item.normalizedName,
            quantity: item.quantity,
            unit: item.unit,
            category: item.category,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: pantry,
        shoppingItems: _state.shoppingItems
            .where((item) => !item.checked)
            .toList(),
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  @override
  List<AiRecipeDraft> get drafts => [..._state.aiDrafts];

  @override
  List<ChatMessage> messagesFor(String draftId) =>
      _state.aiChats[draftId] ?? const [];

  @override
  Future<String> createUrlDraft(String url) async {
    final id = 'draft-${DateTime.now().microsecondsSinceEpoch}';
    final draft = AiRecipeDraft(
      id: id,
      sourceType: RecipeSourceType.url,
      title: 'Importing from URL',
      ingredients: const [],
      steps: const [],
      status: AiGenerationStatus.queued,
      sourceValue: url,
      imageUrl:
          'https://images.unsplash.com/photo-1495521821757-a1efb6729352?auto=format&fit=crop&w=900&q=80',
      notes: 'AI import will summarize the source into a grocery-ready recipe.',
    );
    _saveDraft(draft);
    _saveMessages(id, [
      ChatMessage(
        id: 'msg-$id-1',
        isUser: false,
        text:
            'Import queued. I will extract ingredients and simplify the method.',
        createdAt: DateTime.now(),
      ),
    ]);
    return id;
  }

  @override
  Future<String> createPromptDraft(String prompt) async {
    final id = 'draft-${DateTime.now().microsecondsSinceEpoch}';
    final draft = AiRecipeDraft(
      id: id,
      sourceType: RecipeSourceType.prompt,
      title: 'Generating recipe',
      ingredients: const [],
      steps: const [],
      status: AiGenerationStatus.queued,
      sourceValue: prompt,
      imageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80',
      notes: 'AI generation uses your pantry context and dietary request.',
    );
    _saveDraft(draft);
    _saveMessages(id, [
      ChatMessage(
        id: 'msg-$id-1',
        isUser: false,
        text:
            'Recipe generation queued. I am balancing pantry items with your request.',
        createdAt: DateTime.now(),
      ),
    ]);
    return id;
  }

  @override
  Future<String> createDraftFromRecipe(RecipeDetail recipe) async {
    final id = 'draft-${DateTime.now().microsecondsSinceEpoch}';
    final draft = AiRecipeDraft(
      id: id,
      sourceType: RecipeSourceType.prompt,
      title: recipe.title,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      status: AiGenerationStatus.done,
      sourceValue: recipe.title,
      imageUrl: recipe.imageUrl,
      notes: 'AI tweak session created from a saved recipe.',
    );
    _saveDraft(draft);
    _saveMessages(id, [
      ChatMessage(
        id: 'msg-$id-seed',
        isUser: false,
        text:
            'I loaded this recipe. Ask for swaps, dietary adjustments, or serving changes.',
        createdAt: DateTime.now(),
      ),
    ]);
    return id;
  }

  void _saveDraft(AiRecipeDraft draft) {
    final nextDrafts = [
      ..._state.aiDrafts.where((item) => item.id != draft.id),
      draft,
    ];
    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: _state.pantryItems,
        shoppingItems: _state.shoppingItems,
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: nextDrafts,
        aiChats: _state.aiChats,
      ),
    );
  }

  void _saveMessages(String draftId, List<ChatMessage> messages) {
    final chats = Map<String, List<ChatMessage>>.from(_state.aiChats);
    chats[draftId] = messages;
    _replaceState(
      PersistedState(
        recipes: _state.recipes,
        pantryItems: _state.pantryItems,
        shoppingItems: _state.shoppingItems,
        recentRecipeIds: _state.recentRecipeIds,
        frequentItemCounts: _state.frequentItemCounts,
        aiDrafts: _state.aiDrafts,
        aiChats: chats,
      ),
    );
  }

  AiRecipeDraft draftById(String id) =>
      drafts.firstWhere((draft) => draft.id == id);

  Future<void> _setDraftStatus(String id, AiGenerationStatus status) async {
    final draft = draftById(id);
    _saveDraft(draft.copyWith(status: status));
  }

  @override
  Future<void> runGeneration(String draftId) async {
    final prompt = draftById(draftId).sourceValue;
    final statusFlow = [
      AiGenerationStatus.parsing,
      AiGenerationStatus.reasoning,
      AiGenerationStatus.composing,
    ];
    for (final status in statusFlow) {
      await _setDraftStatus(draftId, status);
      await Future<void>.delayed(const Duration(milliseconds: 850));
    }

    final pantryNames = pantryItems
        .take(2)
        .map((item) => item.name.toLowerCase())
        .join(', ');
    final generated = AiRecipeDraft(
      id: draftId,
      sourceType: draftById(draftId).sourceType,
      title: draftById(draftId).sourceType == RecipeSourceType.url
          ? 'AI-Imported Citrus Crunch Bowl'
          : 'Lavender Night Market Bowl',
      ingredients: [
        ingredient(
          name: 'Chickpeas',
          quantity: 1,
          unit: IngredientUnit.pack,
          category: AisleCategory.pantry,
          status: PantryMatchStatus.missing,
        ),
        ingredient(
          name: 'Cucumber',
          quantity: 1,
          unit: IngredientUnit.item,
          category: AisleCategory.produce,
          status: PantryMatchStatus.missing,
        ),
        ingredient(
          name: 'Greek yogurt',
          quantity: 150,
          unit: IngredientUnit.gram,
          category: AisleCategory.dairy,
          status: PantryMatchStatus.partial,
        ),
        ingredient(
          name: 'Lemon',
          quantity: 1,
          unit: IngredientUnit.item,
          category: AisleCategory.produce,
          status: PantryMatchStatus.enough,
        ),
      ],
      steps: [
        'Roast or warm the chickpeas with olive oil and spices.',
        'Slice cucumber finely and mix yogurt with lemon for a cool sauce.',
        'Assemble the bowl and finish with pantry staples you already have: $pantryNames.',
      ],
      status: AiGenerationStatus.done,
      sourceValue: prompt,
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=80',
      notes: 'Generated locally from mock AI with pantry-aware suggestions.',
    );
    _saveDraft(generated);
    _saveMessages(draftId, [
      ...messagesFor(draftId),
      ChatMessage(
        id: 'msg-$draftId-final',
        isUser: false,
        text:
            'Draft ready. You can save it, add missing ingredients, or keep refining it.',
        createdAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<void> regenerate(String draftId) async {
    await _setDraftStatus(draftId, AiGenerationStatus.queued);
    await runGeneration(draftId);
  }

  @override
  Future<void> sendMessage(String draftId, String text) async {
    final currentDraft = draftById(draftId);
    final messages = [
      ...messagesFor(draftId),
      ChatMessage(
        id: 'msg-$draftId-user-${DateTime.now().microsecondsSinceEpoch}',
        isUser: true,
        text: text,
        createdAt: DateTime.now(),
      ),
    ];

    var updatedDraft = currentDraft;
    final lower = text.toLowerCase();
    if (lower.contains('vegetarian')) {
      updatedDraft = currentDraft.copyWith(
        title: '${currentDraft.title} (Vegetarian)',
        ingredients: currentDraft.ingredients
            .where(
              (item) => item.normalizedName != normalizeName('Chicken thighs'),
            )
            .toList(),
        notes: '${currentDraft.notes} Tweaked for a vegetarian direction.',
      );
    } else if (lower.contains('serv')) {
      updatedDraft = currentDraft.copyWith(
        ingredients: [
          for (final ingredient in currentDraft.ingredients)
            ingredient.copyWith(
              quantity: double.parse(
                (ingredient.quantity * 1.5).toStringAsFixed(2),
              ),
            ),
        ],
        notes: '${currentDraft.notes} Adjusted for a larger serving size.',
      );
    } else if (lower.contains('ingredient')) {
      messages.add(
        ChatMessage(
          id: 'msg-$draftId-ai-${DateTime.now().microsecondsSinceEpoch}',
          isUser: false,
          text:
              'Current ingredients: ${currentDraft.ingredients.map((item) => item.name).join(', ')}.',
          createdAt: DateTime.now(),
        ),
      );
      _saveMessages(draftId, messages);
      return;
    }

    messages.add(
      ChatMessage(
        id: 'msg-$draftId-ai-${DateTime.now().microsecondsSinceEpoch}',
        isUser: false,
        text:
            'Updated the recipe. Review the new draft and add it to your list if it looks right.',
        createdAt: DateTime.now(),
      ),
    );
    _saveDraft(updatedDraft);
    _saveMessages(draftId, messages);
  }
}
