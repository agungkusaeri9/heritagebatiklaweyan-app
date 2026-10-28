import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';

/// Item notifikasi individual dengan ikon sesuai kategori, judul, pesan, waktu, dan status baca
class NotificationItemTile extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback? onTap;

  const NotificationItemTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final styleInfo = _getCategoryStyle(item.categoryCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFF1F5F9)
                  : AppColors.primary.withValues(alpha: 0.15),
              width: item.isRead ? 1.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: item.isRead ? 0.02 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ikon kategori dengan background bulat/squircle pastel
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: styleInfo.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  styleInfo.icon,
                  size: 22,
                  color: styleInfo.iconColor,
                ),
              ),

              const SizedBox(width: 12),

              // 2. Konten Notifikasi (Judul, Pesan, Waktu)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header item: Judul & Titik Unread
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Cuplikan Pesan Notifikasi
                    Text(
                      item.message,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.4,
                        color: item.isRead
                            ? const Color(0xFF64748B)
                            : const Color(0xFF334155),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Footer item: Waktu relatif & Label Kategori
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Waktu relatif (misal: "10m ago", "Yesterday")
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.timeAgo,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),

                        // Kategori pill kecil
                        if (item.categoryName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: styleInfo.bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.categoryName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: styleInfo.iconColor,
                              ),
                            ),
                          ),
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

  /// Menentukan ikon dan palet warna berdasarkan kode kategori
  _CategoryStyle _getCategoryStyle(String code) {
    final upper = code.toUpperCase();

    if (upper.contains('PROMO') || upper.contains('DISCOUNT')) {
      return const _CategoryStyle(
        icon: Icons.local_offer_rounded,
        bgColor: Color(0xFFFEF3C7), // Amber 100
        iconColor: Color(0xFFD97706), // Amber 600
      );
    } else if (upper.contains('ORDER')) {
      return const _CategoryStyle(
        icon: Icons.local_shipping_rounded,
        bgColor: Color(0xFFEFF6FF), // Blue 50
        iconColor: Color(0xFF2563EB), // Blue 600
      );
    } else if (upper.contains('ANNOUNCEMENT') || upper.contains('GENERAL')) {
      return const _CategoryStyle(
        icon: Icons.campaign_rounded,
        bgColor: Color(0xFFF5EFEB), // Sogan Brown soft tint
        iconColor: AppColors.primary, // Sogan Brown #704F38
      );
    } else if (upper.contains('ALERT') || upper.contains('WARN')) {
      return const _CategoryStyle(
        icon: Icons.error_outline_rounded,
        bgColor: Color(0xFFFFF1F2), // Rose 50
        iconColor: Color(0xFFE11D48), // Rose 600
      );
    } else {
      return const _CategoryStyle(
        icon: Icons.notifications_none_rounded,
        bgColor: Color(0xFFF1F5F9), // Slate 100
        iconColor: Color(0xFF475569), // Slate 600
      );
    }
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _CategoryStyle({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}
