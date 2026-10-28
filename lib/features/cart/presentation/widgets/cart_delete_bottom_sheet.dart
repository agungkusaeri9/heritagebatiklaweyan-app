import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/cart_item_model.dart';

/// Modal Bottom Sheet untuk konfirmasi hapus item dari keranjang belanja.
/// Menampilkan detail item: gambar produk, nama produk, ukuran/varian, harga,
/// serta dua tombol aksi: Cancel dan Yes, Remove.
class CartDeleteBottomSheet extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onConfirmDelete;

  const CartDeleteBottomSheet({
    super.key,
    required this.item,
    required this.onConfirmDelete,
  });

  /// Helper statis untuk menampilkan modal bottom sheet dengan animasi lembut
  static Future<bool?> show(
    BuildContext context, {
    required CartItemModel item,
    required VoidCallback onConfirmDelete,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 320),
        reverseDuration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (context) => CartDeleteBottomSheet(
        item: item,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 2. Judul Bottom Sheet
            Text(
              'Remove from Cart',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(
              height: 1,
              thickness: 0.8,
              color: Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 16),

            // 3. Pesan Konfirmasi
            Text(
              'Are you sure you want to remove this item from your cart?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 16),

            // 4. Kartu Ringkasan Item: Gambar, Nama, Ukuran, Harga
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gambar Produk
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDF2F7),
                      ),
                      child: item.primaryImage != null && item.primaryImage!.isNotEmpty
                          ? Image.network(
                              item.primaryImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Detail Produk: Nama, Ukuran (Size), dan Harga
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nama Produk
                        Text(
                          item.productName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 5),

                        // Ukuran / Varian Produk
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.displayVariant,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Harga Produk
                        Text(
                          item.formattedPrice,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Tombol Aksi: Cancel dan Yes, Remove
            Row(
              children: [
                // Tombol Cancel
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      key: const Key('cart_delete_cancel_button'),
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Tombol Yes, Remove
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('cart_delete_confirm_button'),
                      onPressed: () {
                        Navigator.pop(context, true);
                        onConfirmDelete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Yes, Remove',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(
        Icons.checkroom_rounded,
        size: 28,
        color: Color(0xFFCBD5E1),
      ),
    );
  }
}

