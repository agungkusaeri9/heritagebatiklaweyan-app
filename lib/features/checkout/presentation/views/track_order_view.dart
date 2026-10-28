import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/checkout_result_model.dart';
import '../viewmodels/checkout_providers.dart';

/// Layar Pelacakan Pengiriman Pesanan (Track Order Screen)
/// Menampilkan ringkasan produk utama, nomor resi & kurir, serta timeline status pesanan.
class TrackOrderView extends ConsumerStatefulWidget {
  final String orderNumber;
  final CheckoutResultModel? initialOrder;

  const TrackOrderView({
    super.key,
    required this.orderNumber,
    this.initialOrder,
  });

  @override
  ConsumerState<TrackOrderView> createState() => _TrackOrderViewState();
}

class _TrackOrderViewState extends ConsumerState<TrackOrderView> {
  CheckoutResultModel? _order;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
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
      final result = await repo.getOrderDetail(widget.orderNumber);
      if (mounted) {
        final merged = _order != null
            ? _order!.mergeWithDetail(result)
            : result;
        setState(() {
          _order = merged;
          _isLoading = false;
          _errorMessage = null;
        });
        ref
            .read(orderListViewModelProvider.notifier)
            .updateOrderInState(merged);
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

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading && order == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _errorMessage != null && order == null
                  ? _buildErrorState()
                  : order != null
                  ? RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _fetchOrderDetail(silent: false),
                      child: _buildBody(context, order),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/orders');
                }
              },
              borderRadius: BorderRadius.circular(21),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Text(
            'Track Order',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat informasi pelacakan pesanan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchOrderDetail(silent: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CheckoutResultModel order) {
    final primaryProduct = order.primaryProduct;
    final int distinctProducts = order.distinctProductCount > 0
        ? order.distinctProductCount
        : 1;
    final int totalQty = order.totalQuantity > 0 ? order.totalQuantity : 1;
    final bool hasTracking =
        order.trackingNumber != null && order.trackingNumber!.trim().isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        // 1. Ringkasan Produk Utama
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child:
                      primaryProduct?.primaryImage != null &&
                          primaryProduct!.primaryImage!.isNotEmpty
                      ? Image.network(
                          primaryProduct.primaryImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.checkroom_rounded,
                            size: 32,
                            color: Color(0xFFCBD5E1),
                          ),
                        )
                      : const Icon(
                          Icons.checkroom_rounded,
                          size: 32,
                          color: Color(0xFFCBD5E1),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryProduct?.productName.isNotEmpty == true
                          ? primaryProduct!.productName
                          : 'Order #${order.orderNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (primaryProduct != null && primaryProduct.hasVariant)
                      Text(
                        primaryProduct.displayVariant,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    Text(
                      '$distinctProducts ${distinctProducts == 1 ? 'Product' : 'Products'} · Total Qty: $totalQty pcs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.formattedTotal,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 24, color: Color(0xFFE2E8F0)),

        // 2. Order Details & Shipment Information
        Text(
          'Order Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailLine(
          label: 'Order Number',
          value: order.orderNumber,
          onCopy: () =>
              _copyToClipboard(context, order.orderNumber, 'Nomor pesanan'),
        ),
        _buildDetailLine(
          label: 'Courier Service',
          value: order.shippingName ?? order.courierName ?? 'Standard Delivery',
        ),
        _buildDetailLine(
          label: 'Tracking ID',
          value: hasTracking
              ? order.trackingNumber!
              : 'Awaiting Tracking Number',
          onCopy: hasTracking
              ? () => _copyToClipboard(
                  context,
                  order.trackingNumber!,
                  'Nomor resi',
                )
              : null,
        ),

        const Divider(height: 28, color: Color(0xFFE2E8F0)),

        // 3. Order Status Stepper Timeline
        Text(
          'Order Status',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeline(order),
      ],
    );
  }

  Widget _buildDetailLine({
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(4),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(CheckoutResultModel order) {
    final s = order.status.toLowerCase();
    final isPaid = order.paymentStatus.toLowerCase() == 'paid';
    final hasProof = order.hasPaymentProof;
    final isProcessing =
        s == 'processing' || s == 'success' || s == 'completed';
    final hasTracking =
        order.trackingNumber != null && order.trackingNumber!.trim().isNotEmpty;
    final isShipped = hasTracking || s == 'success' || s == 'completed';
    final isCompleted = s == 'success' || s == 'completed';

    final steps = [
      _TimelineStep(
        title: 'Order Placed',
        subtitle: order.formattedDate,
        icon: Icons.assignment_turned_in_outlined,
        isCompleted: true,
      ),
      _TimelineStep(
        title: isPaid
            ? 'Payment Verified'
            : (hasProof ? 'Payment Proof Uploaded' : 'Waiting for Payment'),
        subtitle: isPaid
            ? 'Payment has been verified'
            : (hasProof
                  ? 'Awaiting admin verification'
                  : 'Please complete payment and upload proof'),
        icon: Icons.payments_outlined,
        isCompleted: isPaid || hasProof || isProcessing,
      ),
      _TimelineStep(
        title: 'In Progress',
        subtitle: isProcessing
            ? 'Your batik order is being prepared & packed'
            : 'Will be processed after payment confirmation',
        icon: Icons.inventory_2_outlined,
        isCompleted: isProcessing,
      ),
      _TimelineStep(
        title: 'Shipped',
        subtitle: hasTracking
            ? '${order.shippingName ?? order.courierName ?? 'Courier'} · Resi: ${order.trackingNumber}'
            : 'Package will be handed over to courier',
        icon: Icons.local_shipping_outlined,
        isCompleted: isShipped,
      ),
      _TimelineStep(
        title: 'Delivered',
        subtitle: isCompleted
            ? 'Order has been delivered & completed'
            : (order.fullShippingAddress ?? 'Destination address'),
        icon: Icons.verified_outlined,
        isCompleted: isCompleted,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: step.isCompleted
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: step.isCompleted
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: step.isCompleted
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: step.isCompleted
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              step.subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        step.icon,
                        size: 22,
                        color: step.isCompleted
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
  });
}
