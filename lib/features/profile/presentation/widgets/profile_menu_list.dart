import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/profile_menu_item_model.dart';
import 'profile_menu_item.dart';

/// Reusable Widget: ProfileMenuList
/// Kontainer daftar 8 menu pengaturan akun profil
class ProfileMenuList extends StatelessWidget {
  final List<ProfileMenuItemModel> items;
  final ValueChanged<ProfileMenuItemModel>? onMenuItemTap;
  final Future<void> Function()? onLogout;

  const ProfileMenuList({
    super.key,
    this.items = ProfileMenuItemModel.defaultMenus,
    this.onMenuItemTap,
    this.onLogout,
  });

  void _handleItemTap(BuildContext context, ProfileMenuItemModel item) {
    if (onMenuItemTap != null) {
      onMenuItemTap!(item);
      return;
    }

    if (item.id == 'your_profile') {
      context.push('/complete-profile');
      return;
    }

    if (item.id == 'settings') {
      context.push('/settings');
      return;
    }

    if (item.id == 'log_out') {
      _showLogoutDialog(context);
      return;
    }

    // Default placeholder feedback untuk menu yang belum terintegrasi
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menu ${item.title} (Tahap integrasi berikutnya)'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Heritage Batik?',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (onLogout != null) {
                await onLogout!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulasi logout berhasil (Tahap integrasi berikutnya)'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool isLast = index == items.length - 1;

          return ProfileMenuItem(
            item: item,
            showDivider: !isLast,
            onTap: () => _handleItemTap(context, item),
          );
        }),
      ),
    );
  }
}
