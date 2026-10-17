import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Indikator halaman 3 dots dengan animasi transisi smooth
class OnboardingPageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const OnboardingPageIndicator({
    super.key,
    this.count = 3,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
