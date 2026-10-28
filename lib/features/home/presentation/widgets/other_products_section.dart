import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/home_dummy_data.dart';
import 'product_card.dart';

/// Reusable Widget: OtherProductsSection
/// Menampilkan daftar semua produk (Product Lainnya) dalam format grid 2 kolom dengan infinite scroll pagination
class OtherProductsSection extends StatelessWidget {
  final List<ProductItem> products;
  final bool isLoadingMore;
  final bool hasMore;
  final ValueChanged<ProductItem>? onProductTap;
  final ValueChanged<ProductItem>? onAddToCart;

  const OtherProductsSection({
    super.key,
    required this.products,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.onProductTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Judul Product Lainnya
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Lainnya',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              if (products.isNotEmpty)
                Text(
                  '${products.length} Produk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 2. Grid Produk 2 Kolom
        if (products.isEmpty && !isLoadingMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tidak ada produk ditemukan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.61,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  width: null, // Biarkan menyesuaikan lebar cell grid
                  onProductTap: onProductTap,
                  onAddToCart: onAddToCart != null ? () => onAddToCart!(product) : null,
                );
              },
            ),
          ),

        // 3. Loading Indicator Saat Memuat Halaman Berikutnya (Infinite Scroll)
        if (isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Memuat produk lainnya...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 4. Catatan Jika Semua Produk Sudah Terload
        if (!hasMore && products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 1,
                    color: const Color(0xFFCBD5E1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Semua produk telah ditampilkan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 1,
                    color: const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
