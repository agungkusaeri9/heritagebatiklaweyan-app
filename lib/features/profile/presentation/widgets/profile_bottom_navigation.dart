import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';

/// Reusable Widget: ProfileBottomNavigation
/// Bilah navigasi bawah modern & minimalis (4 menu: Home, Wishlist, History, Account)
class ProfileBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const ProfileBottomNavigation({
    super.key,
    this.currentIndex = 3, // Default aktif pada tab Account (index 3)
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
