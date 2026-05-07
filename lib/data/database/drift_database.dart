import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'drift_database.g.dart';

@DataClassName('IngredientData')
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get canonicalName => text()();
  TextColumn get category => text()();
  TextColumn get aliases => text()(); // JSON-encoded List<String>
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PantryItemData')
class PantryItems extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId => text()();
  RealColumn get quantity => real()();
  RealColumn get initialQuantity => real()();
  TextColumn get unit => text()();
  IntColumn get addedAt => integer()();
  IntColumn get lastVerifiedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get depletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeData')
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get emoji => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get instructions => text()(); // JSON-encoded List<String>
  IntColumn get servings => integer()();
  IntColumn get cookMinutes => integer()();
  TextColumn get difficulty => text()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get tags => text()(); // JSON-encoded List<String>
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeIngredientData')
class RecipeIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId => text()();
  TextColumn get ingredientId => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  IntColumn get isOptional => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShoppingItemData')
class ShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  IntColumn get checked => integer()();
  TextColumn get sourceRecipeId => text().nullable()();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Ingredients, PantryItems, Recipes, RecipeIngredients, ShoppingItems],
)
QueryExecutor _openDatabase() {
  return LazyDatabase(() async {
    // On Android, use the bundled sqlite3 from sqlite3_flutter_libs.
    // On iOS, use the system SQLite (avoids objective_c.framework dependency).
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'instock.db'));
    return NativeDatabase(file);
  });
}

class InStockDriftDb extends _$InStockDriftDb {
  InStockDriftDb() : super(_openDatabase());

  InStockDriftDb.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {},
  );
}
