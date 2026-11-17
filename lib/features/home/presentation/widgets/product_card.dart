import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../wishlist/presentation/viewmodels/wishlist_providers.dart';
import '../../data/models/home_dummy_data.dart';

/// Reusable Widget: ProductCard
/// Kartu produk batik dengan gambar network / placeholder visual, badge diskon, harga strikethrough, dan status favorit
class ProductCard extends ConsumerStatefulWidget {
  final ProductItem product;
  final double? width;
  final ValueChanged<ProductItem>? onProductTap;
  final ValueChanged<bool>? onFavoriteToggle;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.width = 175,
    this.onProductTap,
    this.onFavoriteToggle,
    this.onAddToCart,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isTogglingWishlist = false;

  Future<void> _handleToggleWishlist() async {
    if (_isTogglingWishlist) return;

    final productIdInt = int.tryParse(widget.product.id) ?? 0;
    if (productIdInt <= 0) return;

    setState(() => _isTogglingWishlist = true);
    final next = await ref
        .read(wishlistViewModelProvider.notifier)
        .toggleWishlist(
          productIdInt,
          onError: (msg) {
            if (mounted) AppSnackBar.showError(context, msg);
          },
        );
    if (!mounted) return;
    setState(() => _isTogglingWishlist = false);
    widget.onFavoriteToggle?.call(next);
  }

  String _formatCurrency(double amount) {
    final int intAmount = amount.toInt();
    final String str = intAmount.toString();
    final StringBuffer buffer = StringBuffer();
    int count = 0;

    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  Widget _buildPlaceholderGraphic() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.product.placeholderColor,
            widget.product.placeholderColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 16,
                itemBuilder: (context, i) => const Icon(
                  Icons.diamond_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.checkroom_rounded,
              size: 46,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.originalPrice > widget.product.discountedPrice &&
        widget.product.discountPercentage > 0;

    final wishlistIds = ref.watch(wishlistIdsProvider);
    final bool isWishlisted =
        wishlistIds.contains(widget.product.id) || widget.product.isFavorite;

    return GestureDetector(
      onTap: () {
        if (widget.onProductTap != null) {
          widget.onProductTap!(widget.product);
        } else if (GoRouter.maybeOf(context) != null) {
          context.push(
            '/product/${widget.product.id}',
            extra: widget.product,
          );
        }
      },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Area Gambar Produk + Badge Diskon & Favorite Icon
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: Stack(
                children: [
                  if (widget.product.imageUrl != null &&
                      widget.product.imageUrl!.isNotEmpty)
                    Image.network(
                      widget.product.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderGraphic(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 140,
                          width: double.infinity,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    _buildPlaceholderGraphic(),

                  // Badge Persentase Diskon (Kiri Atas)
                  if (hasDiscount)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${widget.product.discountPercentage}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Tombol Wishlist / Love (Kanan Atas)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _handleToggleWishlist,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          size: 17,
                          color: isWishlisted
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Informasi Detail Produk
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Produk (Maks 2 Baris)
                  SizedBox(
                    height: 36,
                    child: Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Harga Setelah Diskon & Strikethrough Asli
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                _formatCurrency(widget.product.originalPrice),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 1),
                            ],
                            Text(
                              _formatCurrency(widget.product.discountedPrice),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tombol Tambah Keranjang Mini
                      /*
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onAddToCart,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      */
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
