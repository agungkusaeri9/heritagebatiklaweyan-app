import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// Halaman Manajemen Izin Perangkat untuk Fitur Toko Online E-Commerce
class PermissionsView extends ConsumerWidget {
  const PermissionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsNotifierProvider);
    final notifier = ref.read(permissionsNotifierProvider.notifier);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Izin Akses Perangkat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Penjelasan Fitur
            AppCard(
              backgroundColor: AppColors.surfaceVariant,
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Aplikasi memerlukan izin di bawah ini untuk mendukung kemudahan transaksi belanja, pengiriman, dan notifikasi pesanan Anda.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Kamera
            _buildPermissionCard(
              context: context,
              icon: Icons.camera_alt_outlined,
              title: 'Kamera',
              description: 'Scan kode QRIS pembayaran, scan barcode motif batik, dan foto bukti transfer belanja.',
              type: AppPermissionType.camera,
              result: permissionsState.permissions[AppPermissionType.camera],
              onRequest: () => notifier.request(AppPermissionType.camera),
            ),
            const SizedBox(height: 14),

            // 2. Galeri Foto & Media
            _buildPermissionCard(
              context: context,
              icon: Icons.photo_library_outlined,
              title: 'Galeri Foto & Media',
              description: 'Pilih struk bukti transfer dari galeri dan unggah foto untuk ulasan kain batik.',
              type: AppPermissionType.gallery,
              result: permissionsState.permissions[AppPermissionType.gallery],
              onRequest: () => notifier.request(AppPermissionType.gallery),
            ),
            const SizedBox(height: 14),

            // 3. Lokasi GPS
            _buildPermissionCard(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Lokasi Pengiriman (GPS)',
              description: 'Menentukan alamat pengiriman secara akurat dan menghitung estimasi ongkos kirim kurir.',
              type: AppPermissionType.location,
              result: permissionsState.permissions[AppPermissionType.location],
              onRequest: () => context.push('/location'),
            ),
            const SizedBox(height: 14),

            // 4. Notifikasi
            _buildPermissionCard(
              context: context,
              icon: Icons.notifications_active_outlined,
              title: 'Notifikasi Pesanan & Promo',
              description: 'Pemberitahuan nomor resi kurir pengiriman dan promo diskon spesial kain batik Laweyan.',
              type: AppPermissionType.notification,
              result: permissionsState.permissions[AppPermissionType.notification],
              onRequest: () => notifier.request(AppPermissionType.notification),
            ),
            const SizedBox(height: 24),

            // Card Buka Pengaturan
            AppCard(
              title: 'Pengaturan Sistem Perangkat',
              child: Column(
                children: [
                  Text(
                    'Jika izin pernah ditolak permanen, Anda dapat mengaktifkannya langsung melalui Pengaturan Sistem HP.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    text: 'Buka Pengaturan Aplikasi',
                    type: AppButtonType.outline,
                    icon: Icons.settings_outlined,
                    onPressed: () => notifier.openSettings(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required AppPermissionType type,
    required PermissionResult? result,
    required VoidCallback onRequest,
  }) {
    final isGranted = result?.isGranted ?? false;
    final isPermanentlyDenied = result?.isPermanentlyDenied ?? false;

    Color badgeColor;
    String statusLabel;

    if (isGranted) {
      badgeColor = AppColors.success;
      statusLabel = 'Diizinkan';
    } else if (isPermanentlyDenied) {
      badgeColor = AppColors.error;
      statusLabel = 'Ditolak Permanen';
    } else {
      badgeColor = AppColors.warning;
      statusLabel = 'Belum Diizinkan';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 14),
          AppButton(
            text: isGranted ? 'Sudah Aktif (Cek Ulang)' : 'Izinkan Akses',
            type: isGranted ? AppButtonType.outline : AppButtonType.primary,
            onPressed: onRequest,
          ),
        ],
      ),
    );
  }
}
