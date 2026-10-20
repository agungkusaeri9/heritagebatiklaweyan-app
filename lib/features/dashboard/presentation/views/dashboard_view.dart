import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../location/presentation/viewmodels/location_providers.dart';

/// Dashboard / Halaman Utama Toko Online
class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  String _maskedToken = 'Memuat token sesi...';
  String _lastUsernamePref = '-';

  @override
  void initState() {
    super.initState();
    _loadStorageInspectors();
  }

  Future<void> _loadStorageInspectors() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);

    final token = await secureStorage.getAccessToken();
    final lastUser = localStorage.getLastUsername();

    if (mounted) {
      setState(() {
        if (token != null && token.isNotEmpty) {
          _maskedToken = token.length > 25
              ? '${token.substring(0, 16)}...${token.substring(token.length - 8)}'
              : token;
        } else {
          _maskedToken = 'Tidak ada token';
        }
        _lastUsernamePref = lastUser ?? '-';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Heritage Batik Laweyan'),
        actions: [
          IconButton(
            tooltip: 'Keluar Akun',
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) {
                AppSnackBar.showSuccess(context, 'Berhasil keluar dari akun.');
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card Pelanggan
            AppCard(
              backgroundColor: AppColors.primary,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          user?.username ?? 'Pelanggan Batik',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'customer@heritagebatik.com',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'VIP Member',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.accentLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Banner Lokasi Pengiriman Interaktif
            Consumer(
              builder: (context, ref, child) {
                final locationState = ref.watch(locationViewModelProvider);
                final loc = locationState.location;

                return GestureDetector(
                  onTap: () => context.push('/location'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF8F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Lokasi Pengiriman',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (loc != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: loc.isGps
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        loc.isGps ? 'GPS' : 'Manual',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: loc.isGps
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc?.displayName ?? 'Belum ditentukan - Sentuh untuk atur lokasi',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // Quick Stats E-Commerce
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accent, size: 22),
                        const SizedBox(height: 8),
                        Text('Poin Belanja', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 2),
                        Text('1.250 Poin', style: AppTextStyles.headingSmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
                        const SizedBox(height: 8),
                        Text('Pesanan Aktif', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 2),
                        Text('2 Paket', style: AppTextStyles.headingSmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.confirmation_number_outlined, color: AppColors.success, size: 22),
                        const SizedBox(height: 8),
                        Text('Voucher Batik', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 2),
                        Text('3 Kupon', style: AppTextStyles.headingSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Storage Inspection Card (Audit Secure Storage & Local Storage)
            AppCard(
              title: 'Penyimpanan Data Aplikasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Secure Storage (Terenkripsi Hardware)',
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Access Token: $_maskedToken',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(Icons.folder_open_outlined, color: AppColors.info, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Local Storage (Data Non-Sensitif)',
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Username Terakhir: $_lastUsernamePref | Tema: Toko Online Clean',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Akses Fitur Izin Perangkat E-Commerce
            AppCard(
              title: 'Izin Sensor Perangkat Toko',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periksa dan kelola izin kamera (foto produk/scan QRIS), galeri (bukti bayar), lokasi (kurir pengiriman), dan notifikasi pesanan.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Kelola Izin Perangkat',
                    icon: Icons.perm_device_information_rounded,
                    type: AppButtonType.outline,
                    onPressed: () => context.push('/permissions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Logout
            AppButton(
              text: 'Keluar dari Akun',
              icon: Icons.power_settings_new_rounded,
              type: AppButtonType.danger,
              onPressed: () async {
                await ref.read(authViewModelProvider.notifier).logout();
                if (context.mounted) {
                  AppSnackBar.showSuccess(context, 'Berhasil keluar dari akun.');
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
