import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/home_dummy_data.dart';
import 'product_card.dart';

/// Reusable Widget: RecommendationSection
/// Menampilkan deretan kartu produk rekomendasi dengan scroll horizontal
class RecommendationSection extends StatelessWidget {
  final List<ProductItem> products;
  final ValueChanged<ProductItem>? onProductTap;
  final ValueChanged<ProductItem>? onAddToCart;
  final VoidCallback? onSeeAllTap;

  const RecommendationSection({
    super.key,
    this.products = HomeDummyData.recommendations,
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
        // 1. Header Judul Recommendation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommendation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              InkWell(
                onTap: onSeeAllTap ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Katalog lengkap rekomendasi (Tahap berikutnya)'),
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
