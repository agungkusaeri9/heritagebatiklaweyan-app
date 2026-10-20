import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/home_dummy_data.dart';

/// Reusable Widget: ProductCard
/// Kartu produk batik dengan badge diskon, harga strikethrough, dan status favorit
class ProductCard extends StatefulWidget {
  final ProductItem product;
  final ValueChanged<ProductItem>? onProductTap;
  final ValueChanged<bool>? onFavoriteToggle;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onProductTap,
    this.onFavoriteToggle,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onProductTap != null) {
          widget.onProductTap!(widget.product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detail: ${widget.product.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        width: 175,
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
                  // Placeholder Visual Kain Batik
                  Container(
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
                        // Ornamen Batik Geometris Visual
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.15,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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

                        // Center Icon Visual Motif
                        Center(
                          child: Icon(
                            Icons.checkroom_rounded,
                            size: 46,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge Persentase Diskon (Kiri Atas)
                  if (widget.product.discountPercentage > 0)
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
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        if (widget.onFavoriteToggle != null) {
                          widget.onFavoriteToggle!(_isFavorite);
                        }
                      },
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
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          size: 17,
                          color: _isFavorite
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
                  // Rating & Terjual
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.product.rating}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '| ${widget.product.soldCount} terjual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

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
                            // Harga Asli Dicoret
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
                            // Harga Diskon
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
                      GestureDetector(
                        onTap: widget.onAddToCart ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${widget.product.name} dimasukkan ke keranjang',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
