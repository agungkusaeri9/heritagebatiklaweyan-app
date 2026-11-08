import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../profile/presentation/widgets/profile_header.dart';
import '../../data/models/wishlist_item_model.dart';
import '../viewmodels/wishlist_providers.dart';
import '../viewmodels/wishlist_state.dart';
import '../widgets/wishlist_product_card.dart';

/// Layar daftar produk favorit (wishlist) dengan header, grid produk,
/// pull-to-refresh, dan hapus via tombol hati.
class WishlistView extends ConsumerWidget {
  final VoidCallback? onBackTap;
  final bool embedded;

  const WishlistView({super.key, this.onBackTap, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistViewModelProvider);

    final content = Column(
      children: [
        ProfileHeader(
          title: 'Wishlist',
          onBackTap:
              onBackTap ??
              () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/dashboard');
                }
              },
        ),
        Expanded(child: _buildBody(context, ref, state)),
      ],
    );

    if (embedded) {
      return ColoredBox(color: Colors.white, child: content);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(bottom: false, child: content),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, WishlistState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (state.isError && state.items.isEmpty) {
      return _buildMessageState(
        icon: Icons.cloud_off_rounded,
        iconColor: const Color(0xFFEF4444),
        iconBg: const Color(0xFFFFF1F2),
        title: 'Gagal Memuat Wishlist',
        message: state.errorMessage ?? 'Terjadi kesalahan saat memuat data.',
        action: ElevatedButton.icon(
          onPressed: () =>
              ref.read(wishlistViewModelProvider.notifier).loadWishlist(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(wishlistViewModelProvider.notifier).loadWishlist(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: _buildMessageState(
                icon: Icons.favorite_border_rounded,
                iconColor: const Color(0xFF94A3B8),
                iconBg: const Color(0xFFF8FAFC),
                title: 'Wishlist Masih Kosong',
                message:
                    'Tap ikon hati pada produk untuk menyimpannya di sini.',
                action: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Jelajahi Produk'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(wishlistViewModelProvider.notifier).loadWishlist(),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.66,
        ),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return WishlistProductCard(
            item: item,
            isProcessing: state.isToggling,
            onTap: () => context.push('/product/${item.productId}'),
            onRemove: () => _handleRemove(context, ref, item),
          );
        },
      ),
    );
  }

  Future<void> _handleRemove(
    BuildContext context,
    WidgetRef ref,
    WishlistItemModel item,
  ) async {
    final removed = await ref
        .read(wishlistViewModelProvider.notifier)
        .toggleWishlist(
          item.productId,
          onError: (msg) {
            if (context.mounted) AppSnackBar.showError(context, msg);
          },
        );
    if (!context.mounted) return;
    if (!removed) {
      AppSnackBar.showSuccess(context, 'Dihapus dari wishlist.');
    }
  }

  Widget _buildMessageState({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 22), action],
          ],
        ),
      ),
    );
  }
}
