import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';
import 'package:instock/features/settings/providers/settings_provider.dart';
import 'package:instock/features/shopping/providers/shopping_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitPref = ref.watch(unitPreferenceProvider);
    final themePref = ref.watch(themePreferenceProvider);
    final packageInfo = ref.watch(packageInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headingMd),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsSection(
              title: 'Preferences',
              children: [
                _SettingsTile(
                  leading: const Icon(
                    LucideIcons.ruler,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text('Unit System', style: AppTextStyles.label),
                  trailing: _SegmentedChips<UnitSystem>(
                    selected: unitPref,
                    options: const [
                      (UnitSystem.metric, 'Metric'),
                      (UnitSystem.imperial, 'Imperial'),
                    ],
                    onSelect: (v) =>
                        ref.read(unitPreferenceProvider.notifier).set(v),
                  ),
                ),
                _SettingsTile(
                  leading: const Icon(
                    LucideIcons.moon,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text('Appearance', style: AppTextStyles.label),
                  trailing: _SegmentedChips<AppThemeMode>(
                    selected: themePref,
                    options: const [
                      (AppThemeMode.dark, 'Dark'),
                      (AppThemeMode.system, 'System'),
                    ],
                    onSelect: (v) =>
                        ref.read(themePreferenceProvider.notifier).set(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'About',
              children: [
                _SettingsTile(
                  leading: const Icon(
                    LucideIcons.info,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text('Version', style: AppTextStyles.label),
                  trailing: packageInfo.when(
                    data: (info) => Text(
                      '${info.version} (${info.buildNumber})',
                      style: AppTextStyles.caption,
                    ),
                    loading: () => Text('—', style: AppTextStyles.caption),
                    error: (_, __) => Text('—', style: AppTextStyles.caption),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'Data',
              children: [
                _SettingsTile(
                  backgroundColor: AppColors.redDim,
                  leading: const Icon(
                    LucideIcons.trash2,
                    color: AppColors.red,
                    size: 20,
                  ),
                  title: Text(
                    'Clear All Data',
                    style: AppTextStyles.label.copyWith(color: AppColors.red),
                  ),
                  subtitle: Text(
                    'Removes all pantry items, recipes, and shopping data',
                    style: AppTextStyles.caption,
                  ),
                  onTap: () => _confirmClearData(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clear all data?', style: AppTextStyles.headingSm),
        content: Text(
          'This will permanently delete your pantry, recipes, and shopping list. This cannot be undone.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTextStyles.label),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(appDatabaseProvider).clearAllData();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
              'Clear',
              style: AppTextStyles.label.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: AppTextStyles.headingSm),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ColoredBox(
            color: AppColors.surface,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _SegmentedChips<T> extends StatelessWidget {
  const _SegmentedChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(T, String)> options;
  final T selected;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _buildChip(options[i]),
        ],
      ],
    );
  }

  Widget _buildChip((T, String) option) {
    final isSelected = selected == option.$1;
    return GestureDetector(
      onTap: () => onSelect(option.$1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface3 : AppColors.surface2,
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          option.$2,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
