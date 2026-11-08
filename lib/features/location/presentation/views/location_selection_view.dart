import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../viewmodels/location_providers.dart';
import '../viewmodels/location_state.dart';

/// Halaman Pemilihan Lokasi (Location Selection View)
class LocationSelectionView extends ConsumerStatefulWidget {
  const LocationSelectionView({super.key});

  @override
  ConsumerState<LocationSelectionView> createState() => _LocationSelectionViewState();
}

class _LocationSelectionViewState extends ConsumerState<LocationSelectionView> {
  @override
  void initState() {
    super.initState();
    // Muat lokasi segera saat layar dibuka & otomatis minta/ambil lokasi GPS jika belum diset
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locVm = ref.read(locationViewModelProvider.notifier);
      await locVm.loadLocation();
      if (!mounted) return;
      final currentLoc = ref.read(locationViewModelProvider).location;
      if (currentLoc == null || !currentLoc.hasResolvedAddress) {
        locVm.selectGpsLocation();
      }
    });
  }

  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.location_off_rounded, color: Color(0xFFE11D48), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Layanan GPS Nonaktif',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Layanan lokasi (GPS) pada perangkat Anda belum diaktifkan. Harap aktifkan GPS untuk menggunakan deteksi otomatis atau pilih input manual.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _showManualLocationBottomSheet();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
            child: const Text('Input Manual'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(locationViewModelProvider.notifier).openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.security_rounded, color: Color(0xFFE11D48), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Izin Lokasi Diperlukan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Izin akses lokasi telah ditolak secara permanen di perangkat Anda. Anda dapat mengaktifkannya melalui Pengaturan Aplikasi atau memasukkan lokasi secara manual.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _showManualLocationBottomSheet();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
            child: const Text('Gunakan Manual'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(locationViewModelProvider.notifier).openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showManualLocationBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController();
    final labelController = TextEditingController(text: 'Rumah');

    // Jika sudah ada lokasi manual sebelumnya, isikan sebagai nilai awal
    final currentLocation = ref.read(locationViewModelProvider).location;
    if (currentLocation != null && currentLocation.isManual) {
      addressController.text = currentLocation.address ?? '';
      if (currentLocation.label != null) {
        labelController.text = currentLocation.label!;
      }
    }

    final quickChips = ['Rumah', 'Kantor', 'Toko', 'Laweyan'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: keyboardPadding + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar atas
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Judul Modal
                      const Text(
                        'Masukkan Lokasi Manual',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ketik alamat pengiriman atau nama kota/area Anda tanpa memerlukan GPS.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Chips untuk label
                      const Text(
                        'Label Lokasi:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: quickChips.map((chip) {
                          final isSelected = labelController.text == chip;
                          return ChoiceChip(
                            label: Text(chip),
                            selected: isSelected,
                            onSelected: (selected) {
                              setSheetState(() {
                                labelController.text = chip;
                              });
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : const Color(0xFF475569),
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Input Alamat Lengkap
                      const Text(
                        'Alamat / Nama Wilayah *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: addressController,
                        maxLines: 3,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Alamat atau lokasi tidak boleh kosong';
                          }
                          return null;
                        },
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Jl. Dr. Rajiman No. 521, Laweyan, Surakarta, Jawa Tengah',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            Navigator.of(bottomSheetContext).pop();

                            await ref
                                .read(locationViewModelProvider.notifier)
                                .selectManualLocation(
                                  address: addressController.text.trim(),
                                  label: labelController.text.trim(),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Simpan Lokasi Ini',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationViewModelProvider);
    final locationViewModel = ref.read(locationViewModelProvider.notifier);

    // Listener feedback notifikasi
    ref.listen<LocationState>(locationViewModelProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        if (!next.isGpsEnabled) {
          _showGpsDisabledDialog();
        } else if (next.isPermissionPermanentlyDenied) {
          _showPermanentlyDeniedDialog();
        } else {
          AppSnackBar.showError(context, next.errorMessage!);
        }
      } else if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        AppSnackBar.showSuccess(context, next.successMessage!);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          context.go('/dashboard');
        });
      }
    });

    final selectedLocation = locationState.location;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              child: const Text(
                'Lewati',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // 1. Hero Illustration: Circular Map/Pin Container
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF8F5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 28,
                        spreadRadius: 6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: locationState.isLocatingGps
                            ? const SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.location_on_rounded,
                                size: 52,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // 2. Headline
                const Text(
                  'What is Your Location?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Subtitle / Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Kami memerlukan akses lokasi Anda untuk menampilkan rekomendasi layanan terdekat dan menghitung estimasi pengiriman pesanan batik Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Card Lokasi Terpilih Saat Ini (Jika ada di Cache atau Backend)
                if (selectedLocation != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedLocation.isGps
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFDF8F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            selectedLocation.isGps
                                ? Icons.my_location_rounded
                                : Icons.place_rounded,
                            size: 20,
                            color: selectedLocation.isGps
                                ? const Color(0xFF10B981)
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lokasi Pengiriman Saat Ini',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedLocation.displayName,
                                softWrap: true,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (locationState.isSyncingWithBackend)
                          const Padding(
                            padding: EdgeInsets.only(left: 6, top: 4),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const Spacer(flex: 2),

                // 5. Tombol Primary: Allow Location Access (GPS)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: locationState.isLoading || locationState.isLocatingGps
                        ? null
                        : () async {
                            await locationViewModel.selectGpsLocation();
                          },
                    icon: locationState.isLocatingGps
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.near_me_rounded, size: 20),
                    label: Text(
                      locationState.isLocatingGps
                          ? 'Mendeteksi Lokasi...'
                          : 'Allow Location Access',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Tombol Secondary: Enter Location Manually
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: locationState.isLoading || locationState.isLocatingGps
                        ? null
                        : _showManualLocationBottomSheet,
                    icon: const Icon(
                      Icons.edit_location_alt_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Enter Location Manually',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
