import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';

/// Modal Bottom Sheet Konfirmasi Logout
/// Menampilkan dialog konfirmasi dengan judul Logout, pesan konfirmasi,
/// tombol Cancel dan Yes, Logout dengan indikator loading state.
class LogoutConfirmationBottomSheet extends ConsumerStatefulWidget {
  final Future<void> Function()? onLogout;

  const LogoutConfirmationBottomSheet({
    super.key,
    this.onLogout,
  });

  /// Helper statis untuk menampilkan modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    Future<void> Function()? onLogout,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (modalContext) => LogoutConfirmationBottomSheet(
        onLogout: onLogout,
      ),
    );
  }

  @override
  ConsumerState<LogoutConfirmationBottomSheet> createState() =>
      _LogoutConfirmationBottomSheetState();
}

class _LogoutConfirmationBottomSheetState
    extends ConsumerState<LogoutConfirmationBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.onLogout != null) {
        await widget.onLogout!();
      } else {
        await ref.read(authViewModelProvider.notifier).logout();
      }

      if (mounted) {
        Navigator.pop(context);
      }

      AppSnackBar.showSuccess(null, 'Berhasil keluar dari akun.');

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppSnackBar.showError(
          context,
          'Gagal keluar dari akun. Silakan coba lagi.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Handle Bar Abu-Abu di Atas
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 2. Judul "Logout"
              Text(
                'Logout',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 18),

              // 3. Pesan Konfirmasi
              Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // 4. Tombol Aksi (Cancel & Yes, Logout)
              Row(
                children: [
                  // Tombol Cancel
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Tombol Yes, Logout
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Yes, Logout',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
