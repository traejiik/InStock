import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/models/app_models.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

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
              GlassCard(
                margin: EdgeInsets.zero,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.cardAlt,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  AppTheme.accent,
                                  AppTheme.accentStrong,
                                  _controller.value,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Kitchen assistant in progress',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppTheme.olive),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
