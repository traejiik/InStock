import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: LucideIcons.refrigerator,
      title: 'Welcome to InStock',
      body: 'Your pantry, recipes, and shopping list — all in one place.',
    ),
    _OnboardingPageData(
      icon: LucideIcons.package2,
      title: 'Track what you have',
      body:
          'Keep an eye on your pantry. Mark items as low or out, so nothing slips off the list.',
    ),
    _OnboardingPageData(
      icon: LucideIcons.bookOpen,
      title: 'Cook from what\'s in',
      body:
          'Save recipes and see what you can make with the ingredients you already have.',
    ),
    _OnboardingPageData(
      icon: LucideIcons.shoppingCart,
      title: 'Shop with a plan',
      body:
          'Missing ingredients flow straight to your shopping list. Tick them off, they land back in the pantry.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref.read(onboardingControllerProvider.notifier).markComplete();
    if (mounted) context.go('/');
  }

  void _advance() {
    if (_pageIndex == _pages.length - 1) {
      _complete();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const Spacer(),
                    ExcludeSemantics(
                      excluding: _pageIndex == 0,
                      child: AnimatedOpacity(
                        opacity: _pageIndex > 0 ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: IgnorePointer(
                          ignoring: _pageIndex == 0,
                          child: TextButton(
                            onPressed: _complete,
                            child: Text(
                              'Skip',
                              style: AppTextStyles.label.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingPage(
                      icon: page.icon,
                      title: page.title,
                      body: page.body,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PageIndicator(
                      count: _pages.length,
                      currentIndex: _pageIndex,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _advance,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: colors.green,
                          foregroundColor: onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: AppTextStyles.label,
                        ),
                        child: Text(
                          _pageIndex == _pages.length - 1
                              ? 'Get started'
                              : 'Next',
                          style: AppTextStyles.label.copyWith(color: onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(icon, size: 96, color: colors.green),
                ),
                const SizedBox(height: 40),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLg.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.only(right: index == count - 1 ? 0 : 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? colors.green : colors.textTertiary,
          ),
        );
      }),
    );
  }
}
