import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import 'notification_item_tile.dart';

/// Seksi kelompok notifikasi berdasarkan tanggal dengan tombol "Mark all as read"
class NotificationDateSection extends StatelessWidget {
  final NotificationDateGroup group;
  final VoidCallback? onMarkAllRead;
  final void Function(NotificationModel item)? onItemTap;

  const NotificationDateSection({
    super.key,
    required this.group,
    this.onMarkAllRead,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = group.unreadCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Seksi Tanggal & Aksi "Mark all as read"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Judul Tanggal (misal: "TODAY", "YESTERDAY", "20 Oct 2026")
              Text(
                group.title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.6,
                ),
              ),

              // Tombol "Mark all as read"
              if (hasUnread)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onMarkAllRead,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Mark all as read',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 2. Daftar Notifikasi dalam Tanggal ini
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: group.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final notificationItem = group.items[index];
            return NotificationItemTile(
              item: notificationItem,
              onTap: () {
                if (onItemTap != null) {
                  onItemTap!(notificationItem);
                }
              },
            );
          },
        ),
      ],
    );
  }
}
