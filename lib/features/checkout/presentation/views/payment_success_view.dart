import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/checkout_result_model.dart';
import '../viewmodels/checkout_providers.dart';

/// Halaman Payment Success sesuai referensi UI
/// Menampilkan ikon centang, teks "Payment Successful!", pesan konfirmasi pembelian,
/// kartu rincian transaksi aktual, serta fixed bottom action area dengan 2 tombol:
/// 1. Upload Payment Proof
/// 2. View Order Details
/// (Tombol View E-Receipt telah dihapus)
class PaymentSuccessView extends ConsumerStatefulWidget {
  final CheckoutResultModel? order;
  final String? orderNumber;

  const PaymentSuccessView({
    super.key,
    this.order,
    this.orderNumber,
  });

  @override
  ConsumerState<PaymentSuccessView> createState() => _PaymentSuccessViewState();
}

class _PaymentSuccessViewState extends ConsumerState<PaymentSuccessView> {
  CheckoutResultModel? _order;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;

    // Jika order belum ada tetapi orderNumber tersedia, muat dari API
    if (_order == null && widget.orderNumber != null && widget.orderNumber!.isNotEmpty) {
      _fetchOrder(widget.orderNumber!);
    } else if (_order == null) {
      // Coba ambil dari checkoutResult state terakhir
      final stateResult = ref.read(checkoutViewModelProvider).checkoutResult;
      if (stateResult != null) {
        _order = stateResult;
      }
    }
  }

  Future<void> _fetchOrder(String orderNumber) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final result = await repo.getOrderDetail(orderNumber);
      if (mounted) {
        setState(() {
          _order = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.showSuccess(context, '$label berhasil disalin ke clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Bar Header dengan Tombol Tutup / Kembali
              _buildTopBar(context),

              // 2. Konten Scrollable
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : _buildContent(context, order),
              ),

              // 3. Fixed Bottom Action Area
              if (order != null) _buildFixedBottomActions(context, order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/home'),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Text(
            'Payment Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
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

  Widget _buildContent(BuildContext context, CheckoutResultModel? order) {
    if (order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'Data transaksi tidak ditemukan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const SizedBox(height: 12),

        // 1. Ikon Centang dengan Ring Layer Elegan
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7).withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3316A34A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // 2. Headline Teks "Payment Successful!"
        Text(
          'Payment Successful!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 8),

        // 3. Pesan Konfirmasi Pembelian
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Pesanan Anda berhasil dibuat dan sedang diproses. Silakan unggah bukti pembayaran agar pesanan dapat segera dikirimkan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // 4. Kartu Rincian Transaksi Aktual (Actual Transaction Summary Card)
        _buildTransactionCard(context, order),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, CheckoutResultModel order) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Total Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                order.formattedTotal,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          // Order Code
          _buildDetailRow(
            label: 'Order Code',
            value: order.orderNumber,
            showCopy: true,
            onCopy: () => _copyToClipboard(context, order.orderNumber, 'Nomor pesanan'),
          ),

          const SizedBox(height: 12),

          // Order Date
          _buildDetailRow(
            label: 'Order Date',
            value: order.formattedDate,
          ),

          const SizedBox(height: 12),

          // Payment Method
          _buildDetailRow(
            label: 'Payment Method',
            value: order.paymentMethodName ?? 'Bank Transfer',
          ),

          // Bank Account Number (if available)
          if (order.paymentAccountNumber != null && order.paymentAccountNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              label: 'Account Number',
              value: order.paymentAccountNumber!,
              showCopy: true,
              subtitle: order.paymentAccountName != null ? 'a.n ${order.paymentAccountName}' : null,
              onCopy: () => _copyToClipboard(context, order.paymentAccountNumber!, 'Nomor rekening'),
            ),
          ],

          const SizedBox(height: 12),

          // Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.hasPaymentProof
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.hasPaymentProof ? 'Proof Uploaded' : 'Awaiting Payment',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: order.hasPaymentProof
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    String? subtitle,
    bool showCopy = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  if (showCopy) ...[
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onCopy,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Fixed Bottom Action Area dengan 2 Tombol:
  /// 1. Upload Payment Proof (Primary)
  /// 2. View Order Details (Secondary)
  /// (Tanpa tombol View E-Receipt sesuai instruksi user)
  Widget _buildFixedBottomActions(BuildContext context, CheckoutResultModel order) {
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
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol 1: Upload Payment Proof (Primary)
          ElevatedButton(
            onPressed: () {
              context.push(
                '/orders/${order.orderNumber}/payment-proof',
                extra: order,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Upload Payment Proof',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tombol 2: View Order Details (Secondary)
          OutlinedButton(
            onPressed: () {
              context.push(
                '/orders/${order.orderNumber}',
                extra: order,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'View Order Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
