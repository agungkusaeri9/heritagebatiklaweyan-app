import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
/// Bilah navigasi bawah bersih, modern, dan minimalis dengan 4 menu utama:
/// 1. Home
/// 2. Wishlist
/// 3. History
/// 4. Account
///
/// Spesifikasi Desain:
/// - Background: Putih bersih (Colors.white) dengan border tipis di atas & upward shadow lembut
/// - Distribusi: Terbagi merata secara proporsional untuk seluruh item (responsive)
/// - Tata letak item: Ikon di bagian tengah tepat di atas label teks
/// - Ukuran ikon: Konsisten 24px
/// - Jarak ikon ke label: 4px
/// - Warna Menu Aktif: Ikon Cokelat Utama (AppColors.primary) & Label Hijau (Color(0xFF16A34A))
/// - Warna Menu Inaktif: Ikon Abu-abu & Label Abu-abu (Color(0xFF94A3B8))
/// - SafeArea: Menangani padding bawah perangkat (home indicator / gesture bar)
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Color backgroundColor;
  final Color activeIconColor;
  final Color activeLabelColor;
  final Color inactiveColor;
  final List<AppNavItem>? customItems;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.backgroundColor = Colors.white,
    this.activeIconColor = AppColors.primary,
    this.activeLabelColor = const Color(0xFF16A34A),
    this.inactiveColor = const Color(0xFF94A3B8),
    this.customItems,
  });

  /// 4 Menu Standar Sesuai Spesifikasi: Home, Wishlist, History, Account
  static const List<AppNavItem> defaultItems = [
    AppNavItem(
      unselectedIcon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppNavItem(
      unselectedIcon: Icons.favorite_outline_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Wishlist',
    ),
    AppNavItem(
      unselectedIcon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: 'History',
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

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool isActive = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Ikon Menu Terpusat (Active: Cokelat, Inactive: Abu-abu)
                        Icon(
                          isActive ? item.selectedIcon : item.unselectedIcon,
                          size: 24,
                          color: isActive ? activeIconColor : inactiveColor,
                        ),

                        const SizedBox(height: 4),

                        // 2. Label Teks Menu Terpusat (Active: Hijau, Inactive: Abu-abu)
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? activeLabelColor : inactiveColor,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
