import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/database/app_database.dart';
import 'features/shopping/providers/shopping_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  await db.init();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
      ],
      child: const FridgeApp(),
    ),
  );
}
