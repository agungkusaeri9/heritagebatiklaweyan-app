import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/customer_address_model.dart';
import '../viewmodels/checkout_providers.dart';
import '../widgets/add_address_bottom_sheet.dart';

/// Halaman Penuh Pemilihan Alamat Pengiriman (Shipping Address Selection Page)
class ShippingAddressSelectionView extends ConsumerStatefulWidget {
  const ShippingAddressSelectionView({super.key});

  @override
  ConsumerState<ShippingAddressSelectionView> createState() =>
      _ShippingAddressSelectionViewState();
}

class _ShippingAddressSelectionViewState
    extends ConsumerState<ShippingAddressSelectionView> {
  CustomerAddressModel? _tempSelectedAddress;

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(checkoutViewModelProvider);
    _tempSelectedAddress = currentState.selectedAddress;

    if (_tempSelectedAddress == null && currentState.addresses.isNotEmpty) {
      _tempSelectedAddress = currentState.addresses.firstWhere(
        (a) => a.isPrimary,
        orElse: () => currentState.addresses.first,
      );
    }
  }

  void _handleApply() {
    if (_tempSelectedAddress == null) {
      AppSnackBar.showError(context, 'Silakan pilih salah satu alamat pengiriman.');
      return;
    }

    ref.read(checkoutViewModelProvider.notifier).selectAddress(_tempSelectedAddress!);
    context.pop();
  }

  void _openAddNewAddressModal() {
    AddAddressBottomSheet.show(
      context,
      onSave: (payload) async {
        final success = await ref
            .read(checkoutViewModelProvider.notifier)
            .addNewAddress(
              payload,
              onError: (msg) => AppSnackBar.showError(context, msg),
              onSuccess: () => AppSnackBar.showSuccess(
                context,
                'Alamat baru berhasil ditambahkan.',
              ),
            );

        if (success && mounted) {
          final updatedState = ref.read(checkoutViewModelProvider);
          setState(() {
            _tempSelectedAddress = updatedState.selectedAddress;
          });
        }
        return success;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutViewModelProvider);
    final addresses = state.addresses;

    // Pastikan jika ada penambahan alamat baru dari luar, state lokal sinkron
    if (_tempSelectedAddress == null && addresses.isNotEmpty) {
      _tempSelectedAddress = state.selectedAddress ?? addresses.first;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App Bar Header
            _buildAppBar(context),

            // 2. Daftar Alamat Scrollable & Tombol Add New Address
            Expanded(
              child: addresses.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ...addresses.map((address) {
                          final isSelected = _tempSelectedAddress?.id == address.id;
                          return _buildAddressCard(address, isSelected);
                        }),
                        const SizedBox(height: 12),
                        _buildAddNewAddressButton(),
                        const SizedBox(height: 24),
                      ],
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
            'Shipping Address',
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

  Widget _buildAddressCard(CustomerAddressModel address, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _tempSelectedAddress = address;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7F2) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio Button
              Radio<int>(
                value: address.id,
                groupValue: _tempSelectedAddress?.id,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) {
                  setState(() {
                    _tempSelectedAddress = address;
                  });
                },
              ),

              const SizedBox(width: 10),

              // Detail Alamat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.recipientName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (address.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Primary',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        if (address.label != null && address.label!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              address.label!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address.formattedAddress,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
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

  Widget _buildAddNewAddressButton() {
    return OutlinedButton.icon(
      onPressed: _openAddNewAddressModal,
      icon: const Icon(Icons.add_location_alt_outlined, size: 20),
      label: Text(
        'Add New Shipping Address',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.3),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Addresses Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please add a new shipping address to proceed with checkout.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildAddNewAddressButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomApplySection() {
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
        onPressed: _handleApply,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
