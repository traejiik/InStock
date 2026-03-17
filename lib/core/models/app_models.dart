import 'dart:convert';

enum AisleCategory {
  produce,
  dairy,
  bakery,
  pantry,
  frozen,
  spices,
  beverages,
  household,
}

enum DifficultyLevel { easy, medium, hard }

enum IngredientUnit {
  item,
  gram,
  kilogram,
  milliliter,
  liter,
  teaspoon,
  tablespoon,
  cup,
  pinch,
  pack,
}

enum RecipeSourceType { url, prompt }

enum PantryMatchStatus { enough, partial, missing }

enum AiGenerationStatus {
  idle,
  queued,
  parsing,
  reasoning,
  composing,
  done,
  failed,
}

extension EnumLabel on Enum {
  String get label {
    final value = name;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

extension AisleCategoryLabel on AisleCategory {
  String get title => switch (this) {
    AisleCategory.produce => 'Produce',
    AisleCategory.dairy => 'Dairy',
    AisleCategory.bakery => 'Bakery',
    AisleCategory.pantry => 'Pantry',
    AisleCategory.frozen => 'Frozen',
    AisleCategory.spices => 'Spices',
    AisleCategory.beverages => 'Beverages',
    AisleCategory.household => 'Household',
  };
}

extension IngredientUnitLabel on IngredientUnit {
  String get shortLabel => switch (this) {
    IngredientUnit.item => 'item',
    IngredientUnit.gram => 'g',
    IngredientUnit.kilogram => 'kg',
    IngredientUnit.milliliter => 'ml',
    IngredientUnit.liter => 'L',
    IngredientUnit.teaspoon => 'tsp',
    IngredientUnit.tablespoon => 'tbsp',
    IngredientUnit.cup => 'cup',
    IngredientUnit.pinch => 'pinch',
    IngredientUnit.pack => 'pack',
  };
}

String normalizeName(String value) => value.trim().toLowerCase();

class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.checked,
    required this.source,
    required this.pantryLinked,
  });

  final String id;
  final String name;
  final String normalizedName;
  final AisleCategory category;
  final double quantity;
  final IngredientUnit unit;
  final bool checked;
  final String source;
  final bool pantryLinked;

  GroceryItem copyWith({
    String? id,
    String? name,
    String? normalizedName,
    AisleCategory? category,
    double? quantity,
    IngredientUnit? unit,
    bool? checked,
    String? source,
    bool? pantryLinked,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      checked: checked ?? this.checked,
      source: source ?? this.source,
      pantryLinked: pantryLinked ?? this.pantryLinked,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'normalizedName': normalizedName,
    'category': category.name,
    'quantity': quantity,
    'unit': unit.name,
    'checked': checked,
    'source': source,
    'pantryLinked': pantryLinked,
  };

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalizedName'] as String,
      category: AisleCategory.values.byName(map['category'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unit: IngredientUnit.values.byName(map['unit'] as String),
      checked: map['checked'] as bool,
      source: map['source'] as String,
      pantryLinked: map['pantryLinked'] as bool,
    );
  }
}

class PantryItem {
  const PantryItem({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String normalizedName;
  final double quantity;
  final IngredientUnit unit;
  final AisleCategory category;
  final DateTime updatedAt;

  PantryItem copyWith({
    String? id,
    String? name,
    String? normalizedName,
    double? quantity,
    IngredientUnit? unit,
    AisleCategory? category,
    DateTime? updatedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'normalizedName': normalizedName,
    'quantity': quantity,
    'unit': unit.name,
    'category': category.name,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PantryItem.fromMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalizedName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: IngredientUnit.values.byName(map['unit'] as String),
      category: AisleCategory.values.byName(map['category'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.normalizedName,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.isOptional,
    required this.pantryMatchStatus,
  });

  final String name;
  final String normalizedName;
  final double quantity;
  final IngredientUnit unit;
  final AisleCategory category;
  final bool isOptional;
  final PantryMatchStatus pantryMatchStatus;

  RecipeIngredient copyWith({
    String? name,
    String? normalizedName,
    double? quantity,
    IngredientUnit? unit,
    AisleCategory? category,
    bool? isOptional,
    PantryMatchStatus? pantryMatchStatus,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isOptional: isOptional ?? this.isOptional,
      pantryMatchStatus: pantryMatchStatus ?? this.pantryMatchStatus,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'normalizedName': normalizedName,
    'quantity': quantity,
    'unit': unit.name,
    'category': category.name,
    'isOptional': isOptional,
    'pantryMatchStatus': pantryMatchStatus.name,
  };

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['name'] as String,
      normalizedName: map['normalizedName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: IngredientUnit.values.byName(map['unit'] as String),
      category: AisleCategory.values.byName(map['category'] as String),
      isOptional: map['isOptional'] as bool,
      pantryMatchStatus: PantryMatchStatus.values.byName(
        map['pantryMatchStatus'] as String,
      ),
    );
  }
}

class RecipeSummary {
  const RecipeSummary({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.prepTimeMinutes,
    required this.difficulty,
    required this.tags,
  });

  final String id;
  final String title;
  final String imageUrl;
  final int prepTimeMinutes;
  final DifficultyLevel difficulty;
  final List<String> tags;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'prepTimeMinutes': prepTimeMinutes,
    'difficulty': difficulty.name,
    'tags': tags,
  };

  factory RecipeSummary.fromMap(Map<String, dynamic> map) {
    return RecipeSummary(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String,
      prepTimeMinutes: map['prepTimeMinutes'] as int,
      difficulty: DifficultyLevel.values.byName(map['difficulty'] as String),
      tags: List<String>.from(map['tags'] as List<dynamic>),
    );
  }
}

class RecipeDetail {
  const RecipeDetail({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.prepTimeMinutes,
    required this.difficulty,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.servings,
    required this.notes,
  });

  final String id;
  final String title;
  final String imageUrl;
  final int prepTimeMinutes;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int servings;
  final String notes;

  RecipeSummary get summary => RecipeSummary(
    id: id,
    title: title,
    imageUrl: imageUrl,
    prepTimeMinutes: prepTimeMinutes,
    difficulty: difficulty,
    tags: tags,
  );

  RecipeDetail copyWith({
    String? id,
    String? title,
    String? imageUrl,
    int? prepTimeMinutes,
    DifficultyLevel? difficulty,
    List<String>? tags,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    int? servings,
    String? notes,
  }) {
    return RecipeDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      servings: servings ?? this.servings,
      notes: notes ?? this.notes,
    );
  }

  RecipeDetail scaledTo(int targetServings) {
    final ratio = targetServings / servings;
    return copyWith(
      servings: targetServings,
      ingredients: [
        for (final ingredient in ingredients)
          ingredient.copyWith(
            quantity: double.parse(
              (ingredient.quantity * ratio).toStringAsFixed(2),
            ),
          ),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'prepTimeMinutes': prepTimeMinutes,
    'difficulty': difficulty.name,
    'tags': tags,
    'ingredients': ingredients.map((item) => item.toMap()).toList(),
    'steps': steps,
    'servings': servings,
    'notes': notes,
  };

  factory RecipeDetail.fromMap(Map<String, dynamic> map) {
    return RecipeDetail(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String,
      prepTimeMinutes: map['prepTimeMinutes'] as int,
      difficulty: DifficultyLevel.values.byName(map['difficulty'] as String),
      tags: List<String>.from(map['tags'] as List<dynamic>),
      ingredients: (map['ingredients'] as List<dynamic>)
          .map(
            (item) => RecipeIngredient.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      steps: List<String>.from(map['steps'] as List<dynamic>),
      servings: map['servings'] as int,
      notes: map['notes'] as String,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'isUser': isUser,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      isUser: map['isUser'] as bool,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class AiRecipeDraft {
  const AiRecipeDraft({
    required this.id,
    required this.sourceType,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.status,
    required this.sourceValue,
    required this.imageUrl,
    required this.notes,
  });

  final String id;
  final RecipeSourceType sourceType;
  final String title;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final AiGenerationStatus status;
  final String sourceValue;
  final String imageUrl;
  final String notes;

  AiRecipeDraft copyWith({
    String? id,
    RecipeSourceType? sourceType,
    String? title,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    AiGenerationStatus? status,
    String? sourceValue,
    String? imageUrl,
    String? notes,
  }) {
    return AiRecipeDraft(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      status: status ?? this.status,
      sourceValue: sourceValue ?? this.sourceValue,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  RecipeDetail toRecipeDetail() => RecipeDetail(
    id: id,
    title: title,
    imageUrl: imageUrl,
    prepTimeMinutes: 25,
    difficulty: DifficultyLevel.medium,
    tags: const ['AI', 'Imported'],
    ingredients: ingredients,
    steps: steps,
    servings: 4,
    notes: notes,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'sourceType': sourceType.name,
    'title': title,
    'ingredients': ingredients.map((item) => item.toMap()).toList(),
    'steps': steps,
    'status': status.name,
    'sourceValue': sourceValue,
    'imageUrl': imageUrl,
    'notes': notes,
  };

  factory AiRecipeDraft.fromMap(Map<String, dynamic> map) {
    return AiRecipeDraft(
      id: map['id'] as String,
      sourceType: RecipeSourceType.values.byName(map['sourceType'] as String),
      title: map['title'] as String,
      ingredients: (map['ingredients'] as List<dynamic>)
          .map(
            (item) => RecipeIngredient.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      steps: List<String>.from(map['steps'] as List<dynamic>),
      status: AiGenerationStatus.values.byName(map['status'] as String),
      sourceValue: map['sourceValue'] as String,
      imageUrl: map['imageUrl'] as String,
      notes: map['notes'] as String,
    );
  }
}

class PersistedState {
  const PersistedState({
    required this.recipes,
    required this.pantryItems,
    required this.shoppingItems,
    required this.recentRecipeIds,
    required this.frequentItemCounts,
    required this.aiDrafts,
    required this.aiChats,
  });

  final List<RecipeDetail> recipes;
  final List<PantryItem> pantryItems;
  final List<GroceryItem> shoppingItems;
  final List<String> recentRecipeIds;
  final Map<String, int> frequentItemCounts;
  final List<AiRecipeDraft> aiDrafts;
  final Map<String, List<ChatMessage>> aiChats;

  String toJsonString() => jsonEncode({
    'recipes': recipes.map((item) => item.toMap()).toList(),
    'pantryItems': pantryItems.map((item) => item.toMap()).toList(),
    'shoppingItems': shoppingItems.map((item) => item.toMap()).toList(),
    'recentRecipeIds': recentRecipeIds,
    'frequentItemCounts': frequentItemCounts,
    'aiDrafts': aiDrafts.map((item) => item.toMap()).toList(),
    'aiChats': aiChats.map(
      (key, value) =>
          MapEntry(key, value.map((message) => message.toMap()).toList()),
    ),
  });

  factory PersistedState.fromJsonString(String value) {
    final map = jsonDecode(value) as Map<String, dynamic>;
    return PersistedState(
      recipes: (map['recipes'] as List<dynamic>)
          .map(
            (item) =>
                RecipeDetail.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      pantryItems: (map['pantryItems'] as List<dynamic>)
          .map(
            (item) =>
                PantryItem.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      shoppingItems: (map['shoppingItems'] as List<dynamic>)
          .map(
            (item) =>
                GroceryItem.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      recentRecipeIds: List<String>.from(
        map['recentRecipeIds'] as List<dynamic>,
      ),
      frequentItemCounts: Map<String, int>.from(
        map['frequentItemCounts'] as Map,
      ),
      aiDrafts: (map['aiDrafts'] as List<dynamic>)
          .map(
            (item) =>
                AiRecipeDraft.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      aiChats: (map['aiChats'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map(
                (item) =>
                    ChatMessage.fromMap(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
        ),
      ),
    );
  }
}
