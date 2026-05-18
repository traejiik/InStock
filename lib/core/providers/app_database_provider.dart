import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instock/data/database/app_database.dart';

final appDatabaseProvider = ChangeNotifierProvider<AppDatabase>(
  (ref) =>
      throw UnimplementedError('Override appDatabaseProvider in ProviderScope'),
);
