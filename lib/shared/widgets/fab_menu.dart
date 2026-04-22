import 'package:flutter/material.dart';
import 'package:instock/core/theme/app_colors.dart';
import 'package:instock/core/theme/app_text_styles.dart';

class FabOption {
  final String label;
  final String emoji;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const FabOption({
    required this.label,
    required this.emoji,
    required this.background,
    required this.textColor,
    required this.onTap,
  });
}

class FabMenu extends StatefulWidget {
  final List<FabOption> options;

  const FabMenu({super.key, required this.options});

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...widget.options.asMap().entries.map((e) {
          final delay = e.key * 0.15;
          final end = 0.4 + e.key * 0.2;
          final anim = CurvedAnimation(
            parent: _ctrl,
            curve: Interval(delay, end.clamp(0.0, 1.0), curve: Curves.easeOut),
          );
          return AnimatedBuilder(
            animation: anim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (1 - anim.value) * 20),
                child: Opacity(
                  opacity: anim.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  _toggle();
                  e.value.onTap();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: e.value.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.value.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        e.value.label,
                        style: AppTextStyles.label.copyWith(color: e.value.textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.background,
          elevation: 0,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add, size: 26),
          ),
        ),
      ],
    );
  }
}
