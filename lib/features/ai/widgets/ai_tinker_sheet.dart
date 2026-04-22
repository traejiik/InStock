import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';

class AiTinkerSheet extends StatelessWidget {
  final String recipeName;

  const AiTinkerSheet({super.key, required this.recipeName});

  static void show(BuildContext context, {required String recipeName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiTinkerSheet(recipeName: recipeName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✨ AI Tinker', style: AppTextStyles.headingLg),
                            const SizedBox(height: 4),
                            Text(
                              'Let AI transform this recipe your way',
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Text('☁️', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _AiOption(
                    emoji: '🔄',
                    title: 'Substitute Ingredient',
                    subtitle: "Swap something you don't have or like",
                    iconBg: AppColors.amberDim,
                  ),
                  const _AiOption(
                    emoji: '📏',
                    title: 'Scale Recipe',
                    subtitle: 'Adjust portions + rescale all ingredients',
                    iconBg: AppColors.blueDim,
                  ),
                  const _AiOption(
                    emoji: '🥗',
                    title: 'Dietary Transform',
                    subtitle: 'Make it vegan, gluten-free, low-carb…',
                    iconBg: AppColors.purpleDim,
                  ),
                  const _AiOption(
                    emoji: '🏠',
                    title: "What Can I Make?",
                    subtitle: 'Generate recipes from your pantry',
                    iconBg: AppColors.greenDim,
                    accentColor: AppColors.green,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.purpleDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI features require internet connection and an active plan',
                            style: AppTextStyles.caption.copyWith(color: AppColors.purple),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiOption extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color accentColor;

  const _AiOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    this.accentColor = AppColors.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showComingSoon(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.label),
                    Text(subtitle,
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accentColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('☁️ $title requires an active plan',
            style: AppTextStyles.bodySm),
        backgroundColor: AppColors.purpleDim,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
