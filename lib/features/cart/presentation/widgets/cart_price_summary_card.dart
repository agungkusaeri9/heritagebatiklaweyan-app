import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card rincian harga (Order Price Summary) di bagian bawah halaman My Cart
class CartPriceSummaryCard extends StatelessWidget {
  final String subtotal;
  final String? deliveryFee;
  final String? discount;
  final String totalCost;

  const CartPriceSummaryCard({
    super.key,
    required this.subtotal,
    this.deliveryFee,
    this.discount,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Subtotal
        _buildSummaryRow(label: 'Subtotal', value: subtotal),

        // 2. Ongkos Kirim Opsional (Hanya jika disertakan)
        if (deliveryFee != null && deliveryFee!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSummaryRow(label: 'Delivery Fee', value: deliveryFee!),
        ],

        // 3. Diskon Opsional (Jika ada)
        if (discount != null && discount!.isNotEmpty && discount != 'Rp 0') ...[
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Discount',
            value: discount!,
            valueColor: const Color(0xFF16A34A),
          ),
        ],

        const SizedBox(height: 12),

        // 4. Garis Pembatas
        const Divider(color: Color(0xFFF1F5F9), height: 1),

        const SizedBox(height: 12),

        // 5. Total Cost
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
              totalCost,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
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
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
