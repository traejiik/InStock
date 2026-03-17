import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';

class AiLoadingScreen extends ConsumerStatefulWidget {
  const AiLoadingScreen({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<AiLoadingScreen> createState() => _AiLoadingScreenState();
}

class _AiLoadingScreenState extends ConsumerState<AiLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final draft = app.draftById(widget.draftId);
    final statusText = switch (draft.status) {
      AiGenerationStatus.queued => 'Queueing the request',
      AiGenerationStatus.parsing => 'Reading source context',
      AiGenerationStatus.reasoning =>
        'Balancing ingredients and pantry matches',
      AiGenerationStatus.composing => 'Writing a clean recipe draft',
      AiGenerationStatus.done => 'Recipe preview ready',
      AiGenerationStatus.failed => 'Something went wrong',
      AiGenerationStatus.idle => 'Preparing',
    };

    if (!_started) {
      _started = true;
      Future<void>(() async {
        await ref.read(appControllerProvider).runGeneration(widget.draftId);
      });
    }

    if (draft.status == AiGenerationStatus.done) {
      final router = GoRouter.of(context);
      Future<void>(() {
        if (mounted) {
          router.go('/ai/preview/${draft.id}');
        }
      });
    }

    final progress = switch (draft.status) {
      AiGenerationStatus.queued => 0.18,
      AiGenerationStatus.parsing => 0.42,
      AiGenerationStatus.reasoning => 0.68,
      AiGenerationStatus.composing => 0.9,
      AiGenerationStatus.done => 1.0,
      AiGenerationStatus.failed => 0.0,
      AiGenerationStatus.idle => 0.05,
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 200 + (_controller.value * 20),
                    height: 200 + (_controller.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.55),
                          AppTheme.accentStrong.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Generating your recipe',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                statusText,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: AppTheme.card,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
