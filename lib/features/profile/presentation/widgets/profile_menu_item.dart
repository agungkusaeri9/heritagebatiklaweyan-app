import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/profile_menu_item_model.dart';

/// Reusable Widget: ProfileMenuItem
/// Satu baris item menu profil dengan icon di kiri, label + badge di tengah, dan chevron di kanan
class ProfileMenuItem extends StatelessWidget {
  final ProfileMenuItemModel item;
  final VoidCallback? onTap;
  final bool showDivider;

  const ProfileMenuItem({
    super.key,
    required this.item,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDestructive = item.isDestructive;
    final bool hasBadge = item.badgeText != null;

    final Color itemColor = item.textColor ??
        (isDestructive
            ? const Color(0xFFEF4444)
            : (hasBadge ? const Color(0xFF64748B) : const Color(0xFF1E293B)));

    final Color iconColor = item.iconColor ??
        (isDestructive
            ? const Color(0xFFEF4444)
            : (hasBadge ? const Color(0xFF94A3B8) : const Color(0xFF475569)));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasBadge ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  // 1. Icon Menu di Sebelah Kiri
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? const Color(0xFFFEE2E2).withValues(alpha: 0.6)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // 2. Label Menu + Badge di Tengah
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight:
                                  isDestructive ? FontWeight.w700 : FontWeight.w600,
                              color: itemColor,
                            ),
                          ),
                        ),
                        if (item.badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              item.badgeText!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 3. Chevron Icon di Sebelah Kanan (hanya tampil jika menu aktif)
                  if (!hasBadge)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: isDestructive
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFCBD5E1),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Divider Tipis di Antara Item Menu
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: Color(0xFFF1F5F9),
            ),
          ),
      ],
    );
  }
}
