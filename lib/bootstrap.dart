import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/database/drift_database.dart';
import 'data/repositories/app_flags_repository.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/shopping/providers/shopping_provider.dart';

class InStockBootstrap extends StatefulWidget {
  const InStockBootstrap({super.key});

  @override
  State<InStockBootstrap> createState() => _InStockBootstrapState();
}

class _InStockBootstrapState extends State<InStockBootstrap> {
  late final Future<_BootstrapData> _bootstrapData = _initDatabase();

  Future<_BootstrapData> _initDatabase() async {
    final driftDb = InStockDriftDb();
    final appDatabase = AppDatabase(db: driftDb);
    await appDatabase.init();

    final appFlagsRepository = AppFlagsRepository(driftDb);
    final onboardingComplete = await appFlagsRepository.isOnboardingComplete();

    return _BootstrapData(
      appDatabase: appDatabase,
      appFlagsRepository: appFlagsRepository,
      onboardingComplete: onboardingComplete,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapData>(
      future: _bootstrapData,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWith((ref) => data.appDatabase),
              appFlagsRepositoryProvider.overrideWithValue(
                data.appFlagsRepository,
              ),
              onboardingInitialStateProvider.overrideWithValue(
                data.onboardingComplete,
              ),
            ],
            child: const InStockApp(),
          );
        }

        if (snapshot.hasError) {
          return InStockBootstrapError(error: snapshot.error!);
        }

        return const InStockSplashApp();
      },
    );
  }
}

class _BootstrapData {
  const _BootstrapData({
    required this.appDatabase,
    required this.appFlagsRepository,
    required this.onboardingComplete,
  });

  final AppDatabase appDatabase;
  final AppFlagsRepository appFlagsRepository;
  final bool onboardingComplete;
}

class InStockSplashApp extends StatelessWidget {
  const InStockSplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InStockSplashScreen(),
    );
  }
}

class InStockSplashScreen extends StatelessWidget {
  const InStockSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF111214),
      body: Center(
        child: SizedBox(
          width: 150,
          child: Image(
            image: AssetImage('assets/brand/splash.png'),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class InStockBootstrapError extends StatelessWidget {
  const InStockBootstrapError({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF111214),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to start InStock.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
