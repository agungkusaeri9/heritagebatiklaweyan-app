import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Bagian Promo Code ringkas, elegan, dan non-editable (hanya display)
/// Sesuai spesifikasi: Tidak ada text input, form field, atau form baru untuk memasukkan kode promo.
class CartPromoSection extends StatelessWidget {
  final String promoCode;
  final String description;

  const CartPromoSection({
    super.key,
    this.promoCode = 'BATIK25',
    this.description = 'Diskon voucher spesial belanja otomatis aktif',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEBE0D7),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // 1. Ikon Voucher Promo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EAE3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          // 2. Info Kode Promo & Deskripsi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      promoCode,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7), // Green 100
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'APPLIED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF166534), // Green 800
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Ikon Status Aktif (Checkmark)
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }
}
