import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../store/data/models/payment_method_model.dart';

/// Modal Bottom Sheet untuk memilih metode pembayaran sebelum pesanan diproses
class PaymentSelectionBottomSheet extends StatefulWidget {
  final List<PaymentMethodModel> paymentMethods;
  final String formattedTotal;
  final Future<void> Function(PaymentMethodModel selectedMethod) onConfirmPayment;

  const PaymentSelectionBottomSheet({
    super.key,
    required this.paymentMethods,
    required this.formattedTotal,
    required this.onConfirmPayment,
  });

  static Future<void> show(
    BuildContext context, {
    required List<PaymentMethodModel> paymentMethods,
    required String formattedTotal,
    required Future<void> Function(PaymentMethodModel selectedMethod) onConfirmPayment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (sheetContext) => PaymentSelectionBottomSheet(
        paymentMethods: paymentMethods,
        formattedTotal: formattedTotal,
        onConfirmPayment: onConfirmPayment,
      ),
    );
  }

  @override
  State<PaymentSelectionBottomSheet> createState() => _PaymentSelectionBottomSheetState();
}

class _PaymentSelectionBottomSheetState extends State<PaymentSelectionBottomSheet> {
  PaymentMethodModel? _selectedMethod;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethods.isNotEmpty) {
      _selectedMethod = widget.paymentMethods.first;
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedMethod == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    await widget.onConfirmPayment(_selectedMethod!);
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            const SizedBox(height: 16),

            // 2. Judul
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Payment Method',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // 3. Daftar Metode Pembayaran
            if (widget.paymentMethods.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Tidak ada metode pembayaran tersedia.')),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.paymentMethods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final method = widget.paymentMethods[index];
                    final isSelected = _selectedMethod?.id == method.id;

                    return InkWell(
                      onTap: () => setState(() => _selectedMethod = method),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.04)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: method.id,
                              groupValue: _selectedMethod?.id,
                              activeColor: AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (_) => setState(() => _selectedMethod = method),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(
                                Icons.account_balance_outlined,
                                size: 20,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${method.accountNumber} - a.n ${method.accountName}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // 4. Tombol Bayar
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Pay ${widget.formattedTotal}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
