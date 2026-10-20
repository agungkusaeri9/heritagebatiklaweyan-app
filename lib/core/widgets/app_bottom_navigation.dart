import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Item data untuk navigasi bawah reusable
class AppNavItem {
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final String label;

  const AppNavItem({
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Reusable Widget: AppBottomNavigation
/// Bilah navigasi bawah berbentuk rounded pill melayang dengan 5 menu
/// (Home, Bag, Wishlist, Messages, Account)
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Color backgroundColor;
  final Color activeIconColor;
  final List<AppNavItem>? customItems;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.backgroundColor = const Color(0xFF231B15),
    this.activeIconColor = AppColors.primary,
    this.customItems,
  });

  /// 5 Menu Standar E-Commerce Sesuai Desain Referensi
  static const List<AppNavItem> defaultItems = [
    AppNavItem(
      unselectedIcon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppNavItem(
      unselectedIcon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      label: 'Bag',
    ),
    AppNavItem(
      unselectedIcon: Icons.favorite_outline_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Wishlist',
    ),
    AppNavItem(
      unselectedIcon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
    ),
    AppNavItem(
      unselectedIcon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = customItems ?? defaultItems;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final bool isActive = currentIndex == index;

            return GestureDetector(
              onTap: () => onTabSelected(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  // Menu aktif: background lingkaran berwarna putih
                  color: isActive ? Colors.white : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isActive ? item.selectedIcon : item.unselectedIcon,
                    size: 22,
                    // Menu aktif: icon berwarna cokelat (AppColors.primary).
                    // Menu tidak aktif: icon berwarna terang di atas background gelap.
                    color: isActive
                        ? activeIconColor
                        : Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
