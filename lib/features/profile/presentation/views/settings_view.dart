import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
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
        builder: (modalContext, setDialogState) => AlertDialog(
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
                'Apakah Anda benar-benar yakin ingin menghapus akun?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tindakan ini bersifat permanen dan tidak dapat dibatalkan. Seluruh data profil, keranjang belanja, alamat, dan riwayat pesanan Anda akan dinonaktifkan dan dihapus dari sistem Heritage Batik.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.45,
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

                            try {
                              final dioClient = ref.read(dioClientProvider);

                              // 1. Panggil endpoint delete account di backend
                              await dioClient.dio.delete('/user/account');

                              // 2. Tutup dialog modal terlebih dahulu
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              // 3. Tampilkan pesan notifikasi sukses secara global
                              AppSnackBar.showSuccess(
                                null,
                                'Akun Anda berhasil dihapus.',
                              );

                              // 4. Bersihkan sesi autentikasi dan state lokal
                              await ref.read(authViewModelProvider.notifier).logout();

                              // 5. Pastikan navigasi langsung menuju /login
                              if (mounted) {
                                context.go('/login');
                              }
                            } on DioException catch (dioErr) {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  _isDeleting = false;
                                });
                              }
                              if (mounted) {
                                setState(() {
                                  _isDeleting = false;
                                });
                              }

                              final exception = ref.read(dioClientProvider).handleDioError(dioErr);
                              AppSnackBar.showError(modalContext, exception.message);
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  _isDeleting = false;
                                });
                              }
                              if (mounted) {
                                setState(() {
                                  _isDeleting = false;
                                });
                              }

                              AppSnackBar.showError(
                                modalContext,
                                'Gagal menghapus akun. Silakan coba beberapa saat lagi.',
                              );
                            }
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
                            'Ya, Hapus Akun',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
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
    VoidCallback? onTap,
    String? badgeText,
    bool showDivider = true,
    Color? iconBgColor,
    Color? iconColor,
    Color? textColor,
  }) {
    final bool isEnabled = onTap != null && badgeText == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
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
                      color: isEnabled
                          ? (iconBgColor ?? const Color(0xFFF1F5F9))
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isEnabled
                          ? (iconColor ?? const Color(0xFF475569))
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Label Menu + Badge
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isEnabled
                                  ? (textColor ?? const Color(0xFF1E293B))
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Chevron Icon (hanya tampil jika menu aktif)
                  if (isEnabled)
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
                          // 1. Notification Settings (Segera hadir / Soon)
                          _buildMenuItem(
                            title: 'Notification Settings',
                            icon: Icons.notifications_none_rounded,
                            badgeText: 'Soon',
                            iconBgColor: AppColors.primary.withValues(alpha: 0.08),
                            iconColor: AppColors.primary,
                            onTap: null,
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
