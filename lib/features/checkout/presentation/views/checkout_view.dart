import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../cart/presentation/viewmodels/cart_providers.dart';
import '../../../store/data/models/payment_method_model.dart';
import '../../../store/presentation/viewmodels/store_providers.dart';
import '../viewmodels/checkout_providers.dart';
import '../viewmodels/checkout_state.dart';
import '../widgets/checkout_order_item_card.dart';

/// Halaman Checkout dengan Pemilihan Alamat Pengiriman dan Tipe Pengiriman (Kurir)
class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartItems = ref.read(cartViewModelProvider).items;
      ref.read(checkoutViewModelProvider.notifier).initCheckout(cartItems);
      // Preload active payment methods for smooth payment bottom sheet
      ref.read(storeViewModelProvider.notifier).fetchInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar Header
            _buildAppBar(context),

            // 2. Konten Checkout
            Expanded(
              child: _buildBody(context, state),
            ),
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
          // Tombol Kembali
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
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
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          // Judul Halaman
          Text(
            'Checkout',
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

  Widget _buildBody(BuildContext context, CheckoutState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (state.isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Gagal memuat checkout.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final cartItems = ref.read(cartViewModelProvider).items;
                  ref.read(checkoutViewModelProvider.notifier).initCheckout(cartItems);
                },
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // Seksi 1: Shipping Address
              _buildShippingAddressSection(context, state),

              const SizedBox(height: 20),

              // Seksi 2: Choose Shipping Type
              _buildShippingTypeSection(context, state),

              const SizedBox(height: 20),

              // Seksi: Select Payment Method (1 baris 2 kolom dengan radio button)
              _buildPaymentMethodSection(context, state),

              const SizedBox(height: 20),

              // Seksi 3: Order List
              _buildOrderListSection(context, state),

              const SizedBox(height: 20),

              // Seksi 4: Price Summary
              _buildPriceSummarySection(state),

              const SizedBox(height: 24),
            ],
          ),
        ),

        // Seksi 5: Fixed Bottom Button Continue to Payment
        _buildBottomFixedSection(context, state),
      ],
    );
  }

  /// Seksi Shipping Address dengan Tombol CHANGE
  Widget _buildShippingAddressSection(BuildContext context, CheckoutState state) {
    final address = state.selectedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shipping Address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () => context.push('/checkout/shipping-address'),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'CHANGE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: address != null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address.recipientName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if (address.isPrimary) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Primary',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address.phone,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address.formattedAddress,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.add_location_outlined, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Belum ada alamat dipilih',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Seksi Choose Shipping Type dengan Tombol CHANGE
  /// Seksi Choose Shipping Type dengan Tombol CHANGE
  Widget _buildShippingTypeSection(BuildContext context, CheckoutState state) {
    final shipping = state.selectedShippingType;
    final hasAddress = state.selectedAddress != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Choose Shipping Type',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                if (!hasAddress) {
                  AppSnackBar.showError(
                    context,
                    'Silakan pilih alamat pengiriman terlebih dahulu.',
                  );
                  context.push('/checkout/shipping-address');
                  return;
                }
                context.push('/checkout/shipping-type');
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'CHANGE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasAddress ? AppColors.primary : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            if (!hasAddress) {
              AppSnackBar.showError(
                context,
                'Silakan pilih alamat pengiriman terlebih dahulu.',
              );
              context.push('/checkout/shipping-address');
              return;
            }
            context.push('/checkout/shipping-type');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: !hasAddress
                ? Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pilih alamat pengiriman terlebih dahulu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  )
                : state.isLoadingShipping
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Menghitung ongkos kirim...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      )
                    : shipping != null
                        ? Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shipping.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      shipping.description ?? shipping.estimatedDays,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                shipping.formattedFee,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Tidak ada opsi pengiriman tersedia untuk alamat ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
          ),
        ),
      ],
    );
  }

  /// Seksi Select Payment Method: 1 baris 2 kolom dengan radio button
  Widget _buildPaymentMethodSection(BuildContext context, CheckoutState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        if (state.paymentMethods.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment_outlined, color: Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tidak ada metode pembayaran tersedia.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < state.paymentMethods.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodCard(
                        method: state.paymentMethods[i],
                        isSelected: state.selectedPaymentMethod?.id == state.paymentMethods[i].id,
                        onTap: () {
                          ref
                              .read(checkoutViewModelProvider.notifier)
                              .selectPaymentMethod(state.paymentMethods[i]);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (i + 1 < state.paymentMethods.length)
                      Expanded(
                        child: _buildPaymentMethodCard(
                          method: state.paymentMethods[i + 1],
                          isSelected: state.selectedPaymentMethod?.id == state.paymentMethods[i + 1].id,
                          onTap: () {
                            ref
                                .read(checkoutViewModelProvider.notifier)
                                .selectPaymentMethod(state.paymentMethods[i + 1]);
                          },
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMethodModel method,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final displayName = _getDisplayPaymentName(method.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Radio<int>(
                value: method.id,
                groupValue: isSelected ? method.id : null,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (method.accountNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        method.accountNumber,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayPaymentName(String rawName) {
    final match = RegExp(r'\((.*?)\)').firstMatch(rawName);
    if (match != null && match.group(1) != null && match.group(1)!.isNotEmpty) {
      return match.group(1)!;
    }
    if (rawName.toLowerCase().contains('qris')) {
      return 'QRIS';
    }
    return rawName;
  }

  /// Seksi Order List: Menampilkan item produk di keranjang
  Widget _buildOrderListSection(BuildContext context, CheckoutState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order List',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${state.items.length} items',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: Color(0xFFF1F5F9),
          ),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return CheckoutOrderItemCard(item: item);
          },
        ),
      ],
    );
  }

  /// Seksi Rincian Harga Pesanan (Subtotal, Ongkos Kirim, Total)
  Widget _buildPriceSummarySection(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(label: 'Subtotal', value: state.formattedSubtotal),
          const SizedBox(height: 8),
          _buildSummaryRow(label: 'Delivery Fee', value: state.formattedShippingFee),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Cost',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                state.formattedTotalAmount,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// Bagian Bawah Tetap: Tombol Continue to Payment
  Widget _buildBottomFixedSection(BuildContext context, CheckoutState state) {
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
          ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : () => _handleContinueToPayment(context, state),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Payment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _handleContinueToPayment(BuildContext context, CheckoutState state) {
    if (state.selectedAddress == null) {
      AppSnackBar.showError(context, 'Silakan pilih alamat pengiriman terlebih dahulu.');
      return;
    }

    if (state.selectedShippingType == null) {
      AppSnackBar.showError(context, 'Silakan pilih jenis pengiriman terlebih dahulu.');
      return;
    }

    if (state.selectedPaymentMethod == null) {
      AppSnackBar.showError(context, 'Silakan pilih metode pembayaran terlebih dahulu.');
      return;
    }

    ref.read(checkoutViewModelProvider.notifier).processCheckout(
          paymentMethodId: state.selectedPaymentMethod!.id,
          onError: (msg) => AppSnackBar.showError(context, msg),
          onSuccess: (res) {
            // Refresh data keranjang
            ref.read(cartViewModelProvider.notifier).loadCart();

            // Navigasi ke Halaman Payment Success membawa data transaksi aktual
            context.pushReplacement('/checkout/success', extra: res);
          },
        );
  }

  void _showSuccessOrderDialog(BuildContext context, String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nomor Pesanan: $orderNumber\nTerima kasih telah berbelanja di Heritage Batik Laweyan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
