import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';

/// Reusable Widget: HomeBottomNavigation
/// Bilah navigasi bawah reusable berbentuk rounded pill melayang
/// Menggunakan AppBottomNavigation (5 menu: Home, Bag, Wishlist, Messages, Account)
class HomeBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const HomeBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigation(
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
    );
  }
}

