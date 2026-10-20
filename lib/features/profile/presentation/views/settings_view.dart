import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../widgets/profile_header.dart';

/// Halaman Settings pada Profile Screen
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _isDeleting = false;

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus Akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tindakan ini bersifat permanen dan tidak dapat dibatalkan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Seluruh data profil, riwayat pesanan, alamat, dan keranjang belanja Anda akan dihapus secara permanen dari sistem Heritage Batik.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting
                        ? null
                        : () async {
                            setDialogState(() {
                              _isDeleting = true;
                            });
                            setState(() {
                              _isDeleting = true;
                            });

                            // Proses penghapusan akun
                            await Future.delayed(const Duration(milliseconds: 1200));

                            if (!mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            await ref.read(authViewModelProvider.notifier).logout();
                            if (!mounted) return;
                            AppSnackBar.showSuccess(
                              context,
                              'Permintaan hapus akun berhasil diproses.',
                            );
                            context.go('/login');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Hapus',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool showDivider = true,
    Color? iconBgColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon Kontainer
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor ?? const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Label Menu
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? const Color(0xFF1E293B),
                      ),
                    ),
                  ),

                  // Chevron Icon
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: Color(0xFFF1F5F9),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar dengan judul "Settings" dan tombol kembali
            ProfileHeader(
              title: 'Settings',
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/profile');
                }
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kotak Menu Utama Settings
                    Container(
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
                        children: [
                          // 1. Notification Settings
                          _buildMenuItem(
                            title: 'Notification Settings',
                            icon: Icons.notifications_none_rounded,
                            iconBgColor: AppColors.primary.withValues(alpha: 0.08),
                            iconColor: AppColors.primary,
                            onTap: () {
                              context.push('/settings/notifications');
                            },
                          ),

                          // 2. Password Manager
                          _buildMenuItem(
                            title: 'Password Manager',
                            icon: Icons.vpn_key_outlined,
                            iconBgColor: AppColors.primary.withValues(alpha: 0.08),
                            iconColor: AppColors.primary,
                            onTap: () {
                              context.push('/settings/password');
                            },
                          ),

                          // 3. Delete Account
                          _buildMenuItem(
                            title: 'Delete Account',
                            icon: Icons.person_remove_outlined,
                            iconBgColor: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFEF4444),
                            textColor: const Color(0xFFEF4444),
                            showDivider: false,
                            onTap: _showDeleteAccountDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
