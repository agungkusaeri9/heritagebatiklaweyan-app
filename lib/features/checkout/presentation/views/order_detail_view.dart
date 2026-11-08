import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/checkout_result_model.dart';
import '../viewmodels/checkout_providers.dart';

/// Halaman Detail Pesanan (Order Details View)
/// Menampilkan data transaksi aktual dari API GET /api/v1/orders/{identifier}
/// termasuk seluruh daftar produk, alamat penerima, kurir & resi, pembayaran,
/// rincian biaya, serta aksi kontekstual sesuai status pesanan.
class OrderDetailView extends ConsumerStatefulWidget {
  final String orderNumber;
  final CheckoutResultModel? initialOrder;

  const OrderDetailView({
    super.key,
    required this.orderNumber,
    this.initialOrder,
  });

  @override
  ConsumerState<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<OrderDetailView> {
  CheckoutResultModel? _order;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    // Selalu muat detail lengkap dari API; jika initialOrder sudah lengkap, muat secara silent
    _fetchOrderDetail(silent: _order != null && _order!.items.isNotEmpty);
  }

  Future<void> _fetchOrderDetail({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final identifier = widget.orderNumber.isNotEmpty
          ? widget.orderNumber
          : (_order?.id ?? '');
      final result = await repo.getOrderDetail(identifier);
      if (mounted) {
        final merged = _order != null ? _order!.mergeWithDetail(result) : result;
        setState(() {
          _order = merged;
          _isLoading = false;
          _errorMessage = null;
        });
        ref.read(orderListViewModelProvider.notifier).updateOrderInState(merged);
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.showSuccess(context, '$label berhasil disalin');
  }

  Future<void> _handleTrackOrder(CheckoutResultModel order) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final identifier = order.orderNumber.isNotEmpty
          ? order.orderNumber
          : order.id.toString();
      await context.push('/orders/$identifier/track', extra: order);
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> _handleUploadPaymentProof(CheckoutResultModel order) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final identifier = order.orderNumber.isNotEmpty
          ? order.orderNumber
          : order.id.toString();
      await context.push('/orders/$identifier/payment-proof', extra: order);
      if (mounted) {
        await _fetchOrderDetail(silent: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  Future<void> _handleLeaveReviewForProduct(
    CheckoutResultModel order,
    CheckoutOrderItemModel item,
  ) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final identifier = order.orderNumber.isNotEmpty
          ? order.orderNumber
          : order.id.toString();
      final result = await context.push(
        '/orders/$identifier/review?productId=${item.productId}',
        extra: {
          'order': order,
          'item': item,
          'productId': item.productId,
        },
      );
      if (mounted) {
        if (result is CheckoutResultModel) {
          setState(() {
            _order = result;
          });
          ref
              .read(orderListViewModelProvider.notifier)
              .updateOrderInState(result);
        } else {
          await _fetchOrderDetail(silent: true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar
            _buildAppBar(context),

            // 2. Konten
            Expanded(
              child: _isLoading && order == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _errorMessage != null && order == null
                      ? _buildErrorView(context)
                      : order != null
                          ? RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () => _fetchOrderDetail(silent: false),
                              child: _buildOrderBody(context, order),
                            )
                          : const SizedBox.shrink(),
            ),

            // 3. Tombol Aksi Bawah (hanya ditampilkan untuk pesanan aktif: Track Order / Upload Payment Proof)
            if (order != null &&
                (order.canTrackOrder ||
                    (order.canUploadPaymentProof && !order.hasPaymentProof)))
              _buildBottomAction(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('order_detail_back_button'),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/orders');
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Text(
            'Order Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat detail pesanan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchOrderDetail(silent: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderBody(BuildContext context, CheckoutResultModel order) {
    final fullAddress = order.fullShippingAddress;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        // 1. Status Banner
        _buildStatusBanner(order),

        const SizedBox(height: 18),

        // 2. Seksi Informasi Pesanan (Order Information)
        _buildSectionCard(
          title: 'Informasi Pesanan',
          children: [
            _buildRowItem(
              'Nomor Pesanan',
              order.orderNumber.isNotEmpty ? order.orderNumber : '#${order.id}',
              onCopy: order.orderNumber.isNotEmpty
                  ? () => _copyToClipboard(context, order.orderNumber, 'Nomor pesanan')
                  : null,
            ),
            _buildRowItem('Tanggal Pemesanan', order.formattedDate),
            _buildRowItem(
              'Status Pesanan',
              order.statusLabel,
              valueColor: _statusTextColor(order),
            ),
            _buildRowItem(
              'Status Pembayaran',
              order.paymentStatusLabel,
              valueColor: _paymentStatusTextColor(order),
            ),
            if (order.isCompletedOrder)
              _buildRowItem(
                'Status Ulasan',
                order.isFullyReviewed
                    ? 'Sudah Diulas (${order.effectiveRating?.toStringAsFixed(1) ?? '5.0'}/5)'
                    : (order.isPartiallyReviewed
                        ? 'Sebagian Diulas'
                        : 'Belum Diulas'),
                valueColor: order.isFullyReviewed
                    ? const Color(0xFF15803D)
                    : const Color(0xFFD97706),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // 2b. Seksi Penilaian & Ulasan Transaksi (khusus jika status Selesai / Completed)
        if (order.isCompletedOrder) ...[
          _buildReviewSummarySection(context, order),
          const SizedBox(height: 16),
        ],

        // 3. Seksi Daftar Seluruh Produk dalam Pesanan (Product List)
        if (order.items.isNotEmpty) ...[
          _buildItemsCard(order),
          const SizedBox(height: 16),
        ],

        // 4. Seksi Pengiriman & Alamat Penerima (Shipping & Address)
        _buildSectionCard(
          title: 'Informasi Pengiriman',
          children: [
            _buildRowItem(
              'Kurir / Layanan',
              order.shippingName ?? order.courierName ?? '-',
            ),
            if (order.trackingNumber != null && order.trackingNumber!.trim().isNotEmpty)
              _buildRowItem(
                'Nomor Resi',
                order.trackingNumber!,
                onCopy: () => _copyToClipboard(context, order.trackingNumber!, 'Nomor resi'),
              ),
            if (order.recipientName != null && order.recipientName!.trim().isNotEmpty)
              _buildRowItem('Penerima', order.recipientName!),
            if (order.recipientPhone != null && order.recipientPhone!.trim().isNotEmpty)
              _buildRowItem('Nomor Telepon', order.recipientPhone!),
            if (fullAddress != null && fullAddress.isNotEmpty)
              _buildRowItem('Alamat Pengiriman', fullAddress),
          ],
        ),

        const SizedBox(height: 16),

        // 5. Seksi Pembayaran (Payment Information)
        _buildSectionCard(
          title: 'Informasi Pembayaran',
          children: [
            _buildRowItem(
              'Metode Pembayaran',
              order.paymentMethodName ?? 'Bank Transfer',
            ),
            if (order.paymentAccountNumber != null &&
                order.paymentAccountNumber!.trim().isNotEmpty)
              _buildRowItem(
                'Nomor Rekening',
                order.paymentAccountNumber!,
                onCopy: () => _copyToClipboard(
                  context,
                  order.paymentAccountNumber!,
                  'Nomor rekening',
                ),
              ),
            if (order.paymentAccountName != null &&
                order.paymentAccountName!.trim().isNotEmpty)
              _buildRowItem('Atas Nama', order.paymentAccountName!),
            _buildRowItem(
              'Status Pembayaran',
              order.paymentStatusLabel,
              valueColor: _paymentStatusTextColor(order),
            ),
            _buildRowItem(
              'Bukti Transfer',
              order.hasPaymentProof ? 'Sudah Diunggah' : 'Belum Diunggah',
              valueColor: order.hasPaymentProof
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 6. Seksi Rincian Pembayaran (Order Summary)
        _buildSectionCard(
          title: 'Rincian Pembayaran',
          children: [
            _buildRowItem('Subtotal Produk', order.formattedSubtotal),
            _buildRowItem('Biaya Pengiriman', order.formattedShippingFee),
            if (order.discount != null && order.discount! > 0)
              _buildRowItem(
                'Diskon',
                order.formattedDiscount,
                valueColor: const Color(0xFF16A34A),
              ),
            if (order.additionalCharges != null && order.additionalCharges! > 0)
              _buildRowItem(
                'Biaya Tambahan',
                order.formattedAdditionalCharges,
              ),
            const Divider(height: 16, color: Color(0xFFE2E8F0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  order.formattedTotal,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Color _statusTextColor(CheckoutResultModel order) {
    if (order.isCompletedOrder) return const Color(0xFF15803D);
    if (order.isCancelledOrder) return const Color(0xFF9F1239);
    if (order.status.toLowerCase() == 'processing') return const Color(0xFF0369A1);
    return const Color(0xFFB45309);
  }

  Color _paymentStatusTextColor(CheckoutResultModel order) {
    final ps = order.paymentStatus.toLowerCase();
    if (ps == 'paid' || ps == 'success') return const Color(0xFF15803D);
    if (ps == 'failed' || ps == 'cancelled') return const Color(0xFF9F1239);
    if (order.hasPaymentProof) return const Color(0xFF0369A1);
    return const Color(0xFFB45309);
  }

  Widget _buildStatusBanner(CheckoutResultModel order) {
    Color bgColor = const Color(0xFFFEF3C7);
    Color textColor = const Color(0xFFB45309);
    IconData icon = Icons.access_time_rounded;
    String text = 'Menunggu Pembayaran';

    if (order.isCompletedOrder) {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF15803D);
      icon = Icons.check_circle_outline_rounded;
      text = 'Pesanan Selesai (Completed)';
    } else if (order.isCancelledOrder) {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF9F1239);
      icon = Icons.cancel_outlined;
      text = 'Pesanan Dibatalkan (Cancelled)';
    } else if (order.status.toLowerCase() == 'processing') {
      bgColor = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0369A1);
      icon = Icons.local_shipping_outlined;
      text = order.trackingNumber != null && order.trackingNumber!.isNotEmpty
          ? 'Pesanan Dalam Pengiriman (Resi: ${order.trackingNumber})'
          : 'Pesanan Sedang Diproses';
    } else if (order.hasPaymentProof) {
      bgColor = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0369A1);
      icon = Icons.hourglass_top_rounded;
      text = 'Bukti Terunggah - Menunggu Verifikasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRowItem(
    String label,
    String value, {
    Color? valueColor,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 14.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan seluruh daftar produk di dalam pesanan beserta thumbnail,
  /// nama produk, varian/ukuran, harga satuan, kuantitas, dan subtotal per produk.
  Widget _buildItemsCard(CheckoutResultModel order) {
    final items = order.items;
    final totalQty = order.totalQuantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Produk (${items.length} ${items.length == 1 ? 'Produk' : 'Produk'})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Total Qty: $totalQty pcs',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(
              height: 18,
              color: Color(0xFFE2E8F0),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final itemReview = order.reviewForProduct(item.productId);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Produk
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: item.primaryImage != null &&
                                  item.primaryImage!.isNotEmpty
                              ? Image.network(
                                  item.primaryImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.checkroom_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 24,
                                  ),
                                )
                              : const Icon(
                                  Icons.checkroom_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 24,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Detail Produk (Nama, Varian, Harga Satuan & Qty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.hasVariant) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.displayVariant,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity}x ${item.formattedPrice}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Subtotal Item
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.formattedTotalPrice,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Status & Tombol Ulasan Per Produk (Khusus Pesanan Selesai / Completed)
                  if (order.isCompletedOrder) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Badge Status Rating Produk (Belum Diulas vs Sudah Diulas ★ X/5)
                        Container(
                          key: Key(
                            itemReview != null || item.isReviewed
                                ? 'detail_item_reviewed_${item.productId}'
                                : 'detail_item_unreviewed_${item.productId}',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: itemReview != null || item.isReviewed
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                itemReview != null || item.isReviewed
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: itemReview != null || item.isReviewed
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                itemReview != null || item.isReviewed
                                    ? 'Sudah Diulas · ${itemReview?.rating ?? 5}/5'
                                    : 'Belum Diulas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: itemReview != null || item.isReviewed
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Aksi Per Produk (Satu-Satu): Leave Review atau Lihat Ulasan
                        if (itemReview != null || item.isReviewed)
                          SizedBox(
                            height: 32,
                            child: OutlinedButton.icon(
                              key: Key('view_review_product_${item.productId}'),
                              onPressed: _isNavigating
                                  ? null
                                  : () => _handleLeaveReviewForProduct(order, item),
                              icon: const Icon(Icons.visibility_outlined, size: 14),
                              label: Text(
                                'Lihat Ulasan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.1,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              key: Key('leave_review_product_${item.productId}'),
                              onPressed: _isNavigating
                                  ? null
                                  : () => _handleLeaveReviewForProduct(order, item),
                              icon: const Icon(Icons.star_rate_rounded, size: 15),
                              label: Text(
                                'Leave Review',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Tampilkan isi komentar review produk jika sudah diulas
                  if (order.isCompletedOrder &&
                      itemReview != null &&
                      itemReview.comment != null &&
                      itemReview.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '"${itemReview.comment!.trim()}"',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Kartu Ringkasan Penilaian & Ulasan pada Detail Transaksi (saat status Completed)
  Widget _buildReviewSummarySection(
    BuildContext context,
    CheckoutResultModel order,
  ) {
    final bool isReviewed = order.isFullyReviewed;
    final double? rating = order.effectiveRating;

    return Container(
      key: const Key('detail_review_summary_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReviewed ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReviewed
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isReviewed
                        ? Icons.stars_rounded
                        : Icons.rate_review_outlined,
                    size: 20,
                    color: isReviewed
                        ? const Color(0xFFD97706)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status Ulasan Produk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                key: Key(
                  isReviewed
                      ? 'detail_reviewed_status_badge'
                      : 'detail_unreviewed_status_badge',
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isReviewed
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isReviewed
                      ? 'Sudah Diulas'
                      : (order.isPartiallyReviewed ? 'Sebagian Diulas' : 'Belum Diulas'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isReviewed
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isReviewed) ...[
            Row(
              children: [
                ...List.generate(5, (index) {
                  final starVal = index + 1;
                  final activeStars = (rating ?? 5.0).round();
                  return Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: starVal <= activeStars
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFCBD5E1),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${rating?.toStringAsFixed(1) ?? '5.0'} / 5.0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Terima kasih! Seluruh produk pada transaksi ini telah Anda berikan penilaian dan ulasan.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ] else ...[
            Text(
              order.isPartiallyReviewed
                  ? 'Masih ada ${order.unreviewedProductCount} produk yang belum diberi rating. Silakan tekan tombol "Leave Review" pada produk di bawah satu per satu.'
                  : 'Pesanan telah selesai. Silakan pilih tombol "Leave Review" pada masing-masing produk di bawah untuk memberikan rating satu per satu.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Menampilkan tombol aksi bawah sesuai status pesanan aktif:
  /// - Active: Track Order & Upload Payment Proof (bila belum lunas / belum upload)
  Widget _buildBottomAction(BuildContext context, CheckoutResultModel order) {
    final bool showUpload = order.canUploadPaymentProof && !order.hasPaymentProof;
    final bool showTrack = order.canTrackOrder;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showUpload) ...[
            ElevatedButton.icon(
              key: const Key('detail_upload_payment_proof_button'),
              onPressed: _isNavigating ? null : () => _handleUploadPaymentProof(order),
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: Text(
                'Upload Payment Proof',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
            if (showTrack) const SizedBox(height: 10),
          ],
          if (showTrack)
            showUpload
                ? OutlinedButton.icon(
                    key: const Key('detail_track_order_button'),
                    onPressed: _isNavigating ? null : () => _handleTrackOrder(order),
                    icon: const Icon(Icons.local_shipping_outlined, size: 19),
                    label: Text(
                      'Track Order',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    key: const Key('detail_track_order_button'),
                    onPressed: _isNavigating ? null : () => _handleTrackOrder(order),
                    icon: const Icon(Icons.local_shipping_outlined, size: 20),
                    label: Text(
                      'Track Order',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
        ],
      ),
    );
  }
}
