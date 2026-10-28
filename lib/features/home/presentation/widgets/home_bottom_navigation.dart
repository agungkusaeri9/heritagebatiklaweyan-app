import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';

/// Reusable Widget: HomeBottomNavigation
/// Bilah navigasi bawah modern & minimalis (4 menu: Home, Wishlist, History, Account)
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
