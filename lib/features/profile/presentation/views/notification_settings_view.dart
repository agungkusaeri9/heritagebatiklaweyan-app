import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../widgets/profile_header.dart';

/// Halaman Notification Settings
class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  bool _pushNotifications = true;
  bool _orderUpdates = true;
  bool _promoDiscounts = true;
  bool _paymentAlerts = true;

  Widget _buildSwitchItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBD5E1),
                onChanged: (newValue) {
                  onChanged(newValue);
                  AppSnackBar.showSuccess(
                    context,
                    'Preferensi notifikasi diperbarui.',
                  );
                },
              ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(
              title: 'Notification Settings',
              onBackTap: () {
                Navigator.pop(context);
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchItem(
                        title: 'Notifikasi Push',
                        description: 'Terima pemberitahuan langsung pada perangkat Anda',
                        value: _pushNotifications,
                        onChanged: (val) => setState(() => _pushNotifications = val),
                      ),
                      _buildSwitchItem(
                        title: 'Status Pesanan',
                        description: 'Update real-time mengenai pengemasan dan pengiriman batik',
                        value: _orderUpdates,
                        onChanged: (val) => setState(() => _orderUpdates = val),
                      ),
                      _buildSwitchItem(
                        title: 'Promo & Penawaran',
                        description: 'Info diskon motif terbaru dan penawaran eksklusif',
                        value: _promoDiscounts,
                        onChanged: (val) => setState(() => _promoDiscounts = val),
                      ),
                      _buildSwitchItem(
                        title: 'Pengingat Pembayaran',
                        description: 'Pengingat batas waktu transfer dan bukti pembayaran',
                        value: _paymentAlerts,
                        showDivider: false,
                        onChanged: (val) => setState(() => _paymentAlerts = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
