import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/checkout_result_model.dart';

/// Kartu item pesanan pada layar My Orders (Order List).
/// Menampilkan ringkasan produk pertama, jumlah produk & total kuantitas,
/// total harga seluruh pesanan, serta tombol Track Order / badge status sesuai tab.
class OrderListItemCard extends StatelessWidget {
  final CheckoutResultModel order;
  final VoidCallback onTap;
  final VoidCallback? onTrackOrderTap;

  const OrderListItemCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onTrackOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryProduct = order.primaryProduct;
    final String title = (primaryProduct != null &&
            primaryProduct.productName.trim().isNotEmpty)
        ? primaryProduct.productName.trim()
        : 'Order #${order.orderNumber}';
    final String? variantText =
        (primaryProduct != null && primaryProduct.hasVariant)
            ? primaryProduct.displayVariant
            : null;
    final int distinctProducts = order.distinctProductCount > 0
        ? order.distinctProductCount
        : 1;
    final int totalQty = order.totalQuantity > 0 ? order.totalQuantity : 1;
    final int additionalCount = order.additionalProductCount;

    return Material(
      color: Colors.white,
      child: InkWell(
        key: Key('order_list_item_${order.orderNumber}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail Produk Pertama + Indikator Multi-Produk
              _buildProductThumbnail(primaryProduct?.primaryImage, additionalCount),

              const SizedBox(width: 14),

              // 2. Detail Ringkasan Produk & Pesanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Produk Pertama
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Varian/Ukuran (jika tersedia) + Indikator Produk Tambahan
                    if (variantText != null || additionalCount > 0) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (variantText != null)
                            Text(
                              variantText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          if (additionalCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5EFEB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+$additionalCount other ${additionalCount == 1 ? 'product' : 'products'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Ringkasan Jumlah Produk & Total Kuantitas
                    Text(
                      '$distinctProducts ${distinctProducts == 1 ? 'Product' : 'Products'} · Total Qty: $totalQty pcs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Baris Bawah: Total Harga Pesanan & Tombol Aksi / Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Total Harga Seluruh Pesanan
                        Flexible(
                          child: Text(
                            order.formattedTotal,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Tombol Track Order atau Status Badge Sesuai Status Pesanan
                        _buildTrailingAction(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl, int additionalCount) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
          if (additionalCount > 0)
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$additionalCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.checkroom_rounded,
        size: 32,
        color: Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _buildTrailingAction() {
    // 1. Active Orders -> Tampilkan tombol Track Order
    if (order.canTrackOrder) {
      return SizedBox(
        height: 34,
        child: ElevatedButton(
          key: Key('track_order_button_${order.orderNumber}'),
          onPressed: onTrackOrderTap ?? onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Track Order',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // 2. Completed Orders -> Sembunyikan Track Order, tampilkan status Completed
    if (order.isCompletedOrder) {
      return Container(
        key: Key('completed_badge_${order.orderNumber}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF15803D),
            ),
            const SizedBox(width: 4),
            Text(
              'Completed',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Cancelled Orders -> Sembunyikan Track Order, tampilkan status Cancelled
    return Container(
      key: Key('cancelled_badge_${order.orderNumber}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cancel_outlined,
            size: 14,
            color: Color(0xFF9F1239),
          ),
          const SizedBox(width: 4),
          Text(
            'Cancelled',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9F1239),
            ),
          ),
        ],
      ),
    );
  }
}

