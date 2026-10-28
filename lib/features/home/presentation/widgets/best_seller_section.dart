import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/home_dummy_data.dart';
import 'product_card.dart';

/// Reusable Widget: BestSellerSection
/// Menampilkan deretan kartu produk terlaris dengan scroll horizontal (seperti Rekomendasi)
class BestSellerSection extends StatelessWidget {
  final List<ProductItem> products;
  final ValueChanged<ProductItem>? onProductTap;
  final ValueChanged<ProductItem>? onAddToCart;
  final VoidCallback? onSeeAllTap;

  const BestSellerSection({
    super.key,
    required this.products,
    this.onProductTap,
    this.onAddToCart,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Judul Product Terlaris
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Product Terlaris',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 13,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'HOT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onSeeAllTap ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Katalog lengkap produk terlaris'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'See All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 2. Daftar Kartu Produk Horizontal
        SizedBox(
          height: 275,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onProductTap: onProductTap,
                onAddToCart: onAddToCart != null ? () => onAddToCart!(product) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
