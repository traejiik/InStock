import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:instock/core/data/app_controller.dart';
import 'package:instock/core/theme/app_theme.dart';
import 'package:instock/core/widgets/app_scaffold.dart';

class AiImportScreen extends ConsumerStatefulWidget {
  const AiImportScreen({super.key});

  @override
  ConsumerState<AiImportScreen> createState() => _AiImportScreenState();
}

class _AiImportScreenState extends ConsumerState<AiImportScreen> {
  final _urlController = TextEditingController();
  final _promptController = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _urlController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'AI Recipe Import',
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bring any recipe into your flow',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Paste a URL for import or describe a meal using the ingredients you already have.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1D4B), Color(0xFF181224)],
            ),
            border: Border.all(color: AppTheme.accentSoft),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import from URL',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.link_rounded),
                    hintText: 'https://example.com/recipe',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _working ? null : _startUrlFlow,
                    child: const Text('Import recipe'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF311954), Color(0xFF130F1D)],
            ),
            border: Border.all(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate from a prompt',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promptController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        'Example: Build a high-protein vegetarian dinner using pantry staples and something fresh.',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _working ? null : _startPromptFlow,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate recipe'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startUrlFlow() async {
    if (_urlController.text.trim().isEmpty) return;
    setState(() => _working = true);
    final id = await ref
        .read(appControllerProvider)
        .createUrlDraft(_urlController.text.trim());
    if (!mounted) return;
    setState(() => _working = false);
    context.push('/ai/loading/$id');
  }

  Future<void> _startPromptFlow() async {
    if (_promptController.text.trim().isEmpty) return;
    setState(() => _working = true);
    final id = await ref
        .read(appControllerProvider)
        .createPromptDraft(_promptController.text.trim());
    if (!mounted) return;
    setState(() => _working = false);
    context.push('/ai/loading/$id');
  }
}
