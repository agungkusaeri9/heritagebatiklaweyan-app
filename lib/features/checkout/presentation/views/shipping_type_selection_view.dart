import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/shipping_type_model.dart';
import '../viewmodels/checkout_providers.dart';

/// Halaman Penuh Pemilihan Jenis/Kurir Pengiriman (Choose Shipping Type Selection Page)
class ShippingTypeSelectionView extends ConsumerStatefulWidget {
  const ShippingTypeSelectionView({super.key});

  @override
  ConsumerState<ShippingTypeSelectionView> createState() =>
      _ShippingTypeSelectionViewState();
}

class _ShippingTypeSelectionViewState
    extends ConsumerState<ShippingTypeSelectionView> {
  ShippingTypeModel? _tempSelectedShippingType;

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(checkoutViewModelProvider);
    _tempSelectedShippingType = currentState.selectedShippingType;

    if (_tempSelectedShippingType == null && currentState.shippingTypes.isNotEmpty) {
      _tempSelectedShippingType = currentState.shippingTypes.first;
    }
  }

  void _handleApply() {
    if (_tempSelectedShippingType == null) {
      AppSnackBar.showError(context, 'Silakan pilih salah satu layanan pengiriman.');
      return;
    }

    ref
        .read(checkoutViewModelProvider.notifier)
        .selectShippingType(_tempSelectedShippingType!);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutViewModelProvider);
    final shippingTypes = state.shippingTypes;

    if (_tempSelectedShippingType == null && shippingTypes.isNotEmpty) {
      _tempSelectedShippingType = state.selectedShippingType ?? shippingTypes.first;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar Header
            _buildAppBar(context),

            // 2. Daftar Kurir Pengiriman
            Expanded(
              child: shippingTypes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: shippingTypes.length,
                      itemBuilder: (context, index) {
                        final type = shippingTypes[index];
                        final isSelected = _tempSelectedShippingType?.code == type.code;
                        return _buildShippingTypeCard(type, isSelected);
                      },
                    ),
            ),

            // 3. Tombol Apply Tetap di Bagian Bawah (Fixed Bottom)
            _buildBottomApplySection(),
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
              onTap: () => context.pop(),
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
            'Choose Shipping Type',
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

  Widget _buildShippingTypeCard(ShippingTypeModel type, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _tempSelectedShippingType = type;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7F2) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Radio Button
              Radio<String>(
                value: type.code,
                groupValue: _tempSelectedShippingType?.code,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) {
                  setState(() {
                    _tempSelectedShippingType = type;
                  });
                },
              ),

              const SizedBox(width: 8),

              // Ikon Truk Pengiriman (Kompak 34x34)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: isSelected ? AppColors.primary : const Color(0xFF475569),
                ),
              ),

              const SizedBox(width: 10),

              // Detail Kurir (Nama dan Estimasi)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description ?? type.estimatedDays,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Biaya Ongkir
              Text(
                type.formattedFee,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final state = ref.watch(checkoutViewModelProvider);
    final hasAddress = state.selectedAddress != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasAddress ? Icons.local_shipping_outlined : Icons.location_off_outlined,
                size: 36,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasAddress ? 'Layanan Pengiriman Belum Tersedia' : 'Alamat Belum Dipilih',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAddress
                  ? 'Tidak ada opsi pengiriman yang tersedia untuk alamat ini. Silakan coba lagi nanti.'
                  : 'Silakan pilih alamat pengiriman terlebih dahulu di halaman checkout untuk melihat pilihan kurir.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomApplySection() {
    final state = ref.watch(checkoutViewModelProvider);
    final isEnabled = state.shippingTypes.isNotEmpty && _tempSelectedShippingType != null;

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
      child: ElevatedButton(
        onPressed: isEnabled ? _handleApply : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF94A3B8),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Apply',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
