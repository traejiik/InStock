import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'features/shopping/providers/shopping_provider.dart';

class InStockBootstrap extends StatefulWidget {
  const InStockBootstrap({super.key});

  @override
  State<InStockBootstrap> createState() => _InStockBootstrapState();
}

class _InStockBootstrapState extends State<InStockBootstrap> {
  late final Future<AppDatabase> _database = _initDatabase();

  Future<AppDatabase> _initDatabase() async {
    final db = AppDatabase();
    await db.init();
    return db;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDatabase>(
      future: _database,
      builder: (context, snapshot) {
        final db = snapshot.data;
        if (db != null) {
          return ProviderScope(
            overrides: [appDatabaseProvider.overrideWith((ref) => db)],
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
