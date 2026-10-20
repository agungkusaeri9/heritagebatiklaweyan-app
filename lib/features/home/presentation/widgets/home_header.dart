import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../location/presentation/viewmodels/location_providers.dart';

/// Reusable Widget: HomeHeader
/// Menampilkan lokasi pengiriman pengguna dengan dropdown serta ikon Cart dan Notifikasi ber-badge
class HomeHeader extends ConsumerWidget {
  final int cartCount;
  final int notificationCount;
  final VoidCallback? onCartTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAddressTap;

  const HomeHeader({
    super.key,
    this.cartCount = 2,
    this.notificationCount = 3,
    this.onCartTap,
    this.onNotificationTap,
    this.onAddressTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationViewModelProvider);
    final currentLocation = locationState.location;
    final addressText = currentLocation?.displayName ?? 'Kampung Batik Laweyan, Solo';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Informasi Alamat Pengiriman (Delivery Address)
          Expanded(
            child: InkWell(
              onTap: onAddressTap ?? () => context.push('/location'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Deliver to',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            addressText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. Ikon Cart dengan Badge
          _buildActionIconButton(
            icon: Icons.shopping_bag_outlined,
            badgeCount: cartCount,
            tooltip: 'Keranjang Belanja',
            onTap: onCartTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Keranjang belanja (Tahap integrasi berikutnya)'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
          ),

          const SizedBox(width: 10),

          // 3. Ikon Notifikasi dengan Badge
          _buildActionIconButton(
            icon: Icons.notifications_outlined,
            badgeCount: notificationCount,
            tooltip: 'Notifikasi',
            onTap: onNotificationTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifikasi toko (Tahap integrasi berikutnya)'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required int badgeCount,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 21,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
