import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class TweakAiScreen extends ConsumerStatefulWidget {
  const TweakAiScreen({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<TweakAiScreen> createState() => _TweakAiScreenState();
}

class _TweakAiScreenState extends ConsumerState<TweakAiScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final draft = app.draftById(widget.draftId);
    final messages = app.messagesFor(widget.draftId);
    final quickActions = const [
      'Show ingredients',
      'Adjust servings',
      'Make vegetarian',
      'Swap ingredient',
    ];

    return AppScreen(
      title: 'Recipe Assistant',
      showBack: true,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(draft.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Use quick actions or ask for dietary swaps, serving changes, and substitutions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in quickActions)
                    ActionChip(
                      label: Text(action),
                      onPressed: () async => ref
                          .read(appControllerProvider)
                          .sendMessage(widget.draftId, action),
                    ),
                ],
              ),
            ],
          ),
        ),
        for (final message in messages)
          Align(
            alignment: message.isUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(maxWidth: 310),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: message.isUser ? AppTheme.accentSoft : AppTheme.card,
                border: Border.all(
                  color: message.isUser ? AppTheme.accentSoft : AppTheme.border,
                ),
              ),
              child: Text(message.text),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText:
                      'Ask for substitutions, dietary tweaks, or a different tone.',
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.trim().isEmpty) return;
                final text = _controller.text.trim();
                _controller.clear();
                await ref
                    .read(appControllerProvider)
                    .sendMessage(widget.draftId, text);
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}
