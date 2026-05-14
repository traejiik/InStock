import 'package:drift/drift.dart' show Value;

import '../database/drift_database.dart';

const _appFlagsSingletonId = 'singleton';

class AppFlagsRepository {
  AppFlagsRepository(this._db);

  final InStockDriftDb _db;

  Future<bool> isOnboardingComplete() async {
    final row = await (_db.select(
      _db.appFlags,
    )..where((flag) => flag.id.equals(_appFlagsSingletonId))).getSingleOrNull();

    return row?.onboardingCompleted == 1;
  }

  Future<void> markOnboardingComplete() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.appFlags)
        .insertOnConflictUpdate(
          AppFlagsCompanion.insert(
            id: _appFlagsSingletonId,
            onboardingCompleted: 1,
            onboardingCompletedAt: Value(now),
            updatedAt: now,
          ),
        );
  }

  Future<void> reset() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.appFlags)
        .insertOnConflictUpdate(
          AppFlagsCompanion.insert(
            id: _appFlagsSingletonId,
            onboardingCompleted: 0,
            onboardingCompletedAt: const Value(null),
            updatedAt: now,
          ),
        );
  }
}
