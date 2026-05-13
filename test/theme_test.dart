import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light theme exposes the design-system color tokens', () {
    const colors = AppColors.light;

    expect(colors.background, const Color(0xFFF6F7F8));
    expect(colors.surface, Colors.white);
    expect(colors.surface2, const Color(0xFFF1F2F4));
    expect(colors.border, const Color(0xFFE2E4E9));
    expect(colors.textPrimary, const Color(0xFF0E0F11));
    expect(colors.textSecondary, const Color(0xFF5A5F6B));
    expect(colors.green, const Color(0xFF22C55E));
    expect(colors.greenInk, const Color(0xFF15803D));
    expect(colors.redInk, const Color(0xFF991B1B));
  });

  test('theme preference maps and persists light mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themePreferenceProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    container.read(themePreferenceProvider.notifier).set(AppThemeMode.light);

    expect(AppThemeMode.light.toThemeMode(), ThemeMode.light);
    expect(container.read(themePreferenceProvider), AppThemeMode.light);
    expect(prefs.getString('instock_theme_pref'), 'light');
  });
}
