import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Widget: ProfileHeader
/// Header halaman Profile dengan tombol Back di kiri dan judul di tengah
class ProfileHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  final Widget? trailing;

  const ProfileHeader({
    super.key,
    this.title = 'Account',
    this.onBackTap,
    this.showBackButton = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tombol Back di Kiri Atas (atau placeholder bila disembunyikan)
          if (showBackButton)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBackTap ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
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
            )
          else
            const SizedBox(
              width: 42,
              height: 42,
            ),

          // 2. Judul Profile di Tengah
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),

          // 3. Sisi Kanan Penyeimbang Layout
          trailing ??
              const SizedBox(
                width: 42,
                height: 42,
              ),
        ],
      ),
    );
  }
}
