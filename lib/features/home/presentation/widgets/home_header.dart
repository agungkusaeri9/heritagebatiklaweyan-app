import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/presentation/viewmodels/cart_providers.dart';
import '../../../location/presentation/viewmodels/location_providers.dart';
import '../../../notification/presentation/viewmodels/notification_providers.dart';

/// Reusable Widget: HomeHeader
/// Menampilkan lokasi pengiriman pengguna dengan dropdown serta ikon Cart dan Notifikasi ber-badge
class HomeHeader extends ConsumerWidget {
  final int? cartCount;
  final int? notificationCount;
  final VoidCallback? onCartTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAddressTap;

  const HomeHeader({
    super.key,
    this.cartCount,
    this.notificationCount,
    this.onCartTap,
    this.onNotificationTap,
    this.onAddressTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationViewModelProvider);
    final currentLocation = locationState.location;
    final bool isAddressLoading =
        locationState.isLoading ||
        locationState.isLocatingGps ||
        (locationState.isSyncingWithBackend &&
            (currentLocation == null || !currentLocation.hasResolvedAddress)) ||
        (currentLocation != null && !currentLocation.hasResolvedAddress);

    final addressText =
        (currentLocation != null && currentLocation.hasResolvedAddress)
        ? currentLocation.displayName
        : 'Kampung Batik Laweyan, Solo';
    final liveUnreadCount = ref.watch(unreadNotificationCountProvider);
    final effectiveNotificationCount = notificationCount ?? liveUnreadCount;
    final liveCartCount = ref.watch(cartItemCountProvider);
    final effectiveCartCount = cartCount ?? liveCartCount;

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
                    if (isAddressLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: _DeliveryAddressSkeleton(),
                      )
                    else
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
            badgeCount: effectiveCartCount,
            tooltip: 'Keranjang Belanja',
            onTap: onCartTap ?? () => context.push('/cart'),
          ),

          const SizedBox(width: 4),

          // 3. Ikon Notifikasi dengan Badge
          _buildActionIconButton(
            icon: Icons.notifications_outlined,
            badgeCount: effectiveNotificationCount,
            tooltip: 'Notifikasi',
            onTap: onNotificationTap ?? () => context.push('/notifications'),
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
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 25, color: const Color(0xFF1E293B)),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
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
                    fontSize: 9,
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

/// Widget Skeleton Shimmer untuk teks alamat pengiriman pada HomeHeader
class _DeliveryAddressSkeleton extends StatefulWidget {
  const _DeliveryAddressSkeleton();

  @override
  State<_DeliveryAddressSkeleton> createState() =>
      _DeliveryAddressSkeletonState();
}

class _DeliveryAddressSkeletonState extends State<_DeliveryAddressSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Row(
        children: [
          Container(
            width: 170,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
