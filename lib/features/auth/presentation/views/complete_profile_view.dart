import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../location/presentation/viewmodels/location_providers.dart';
import '../viewmodels/auth_providers.dart';

/// Custom Clipper untuk lengkungan cembung elegan di bagian bawah Header
class _CompleteProfileHeaderClipper extends CustomClipper<Path> {
  const _CompleteProfileHeaderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 45);

    final controlPoint = Offset(size.width / 2, size.height);
    final endPoint = Offset(size.width, size.height - 45);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Halaman Lengkapi Profil (Complete Your Profile Screen)
class CompleteProfileView extends ConsumerStatefulWidget {
  const CompleteProfileView({super.key});

  @override
  ConsumerState<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends ConsumerState<CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _selectedGender;
  String? _selectedAvatarUrl;
  File? _pickedAvatarFile;
  bool _isAvatarCleared = false;
  final ImagePicker _imagePicker = ImagePicker();

  final String _selectedCountryCode = '+62';

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authViewModelProvider).user;

    _nameController = TextEditingController(
      text: currentUser?.name ?? currentUser?.username ?? '',
    );

    String initialPhone = currentUser?.phone ?? '';
    if (initialPhone.startsWith('+62')) {
      initialPhone = initialPhone.substring(3);
    } else if (initialPhone.startsWith('62')) {
      initialPhone = initialPhone.substring(2);
    } else if (initialPhone.startsWith('0')) {
      initialPhone = initialPhone.substring(1);
    }
    _phoneController = TextEditingController(text: initialPhone);

    _selectedGender = currentUser?.gender;
    _selectedAvatarUrl = currentUser?.avatarUrl;

    // Otomatis meminta izin galeri saat pertama kali masuk ke halaman Complete Your Profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialGalleryPermission();
    });
  }

  /// Meminta izin akses galeri secara otomatis saat halaman dimuat
  Future<void> _requestInitialGalleryPermission() async {
    if (!mounted) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final permissionService = ref.read(permissionServiceProvider);
        final checkResult =
            await permissionService.checkPermission(AppPermissionType.gallery);
        if (!checkResult.isGranted) {
          await permissionService.requestPermission(AppPermissionType.gallery);
        }
      }
    } catch (e) {
      AppLogger.w('Initial gallery permission check: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Dialog yang memandu pengguna membuka Pengaturan Perangkat jika izin galeri ditolak
  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.photo_library_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Izin Galeri Diperlukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Aplikasi membutuhkan izin akses galeri foto untuk memilih foto profil Anda. Silakan aktifkan izin galeri foto melalui Pengaturan Aplikasi.',
          style: TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(permissionServiceProvider).openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  /// Membuka galeri untuk memilih foto avatar profil dengan verifikasi izin otomatis
  Future<void> _pickAvatarFromGallery() async {
    try {
      // 1. Verifikasi izin akses galeri perangkat (Android & iOS)
      if (Platform.isAndroid || Platform.isIOS) {
        final permissionService = ref.read(permissionServiceProvider);
        final checkResult =
            await permissionService.checkPermission(AppPermissionType.gallery);

        if (!checkResult.isGranted) {
          final requestResult =
              await permissionService.requestPermission(AppPermissionType.gallery);

          if (!requestResult.isGranted && requestResult.isPermanentlyDenied) {
            if (mounted) {
              _showPermissionSettingsDialog();
            }
            return;
          }
        }
      }

      // 2. Buka pemilih foto galeri bawaan
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _pickedAvatarFile = File(image.path);
          _isAvatarCleared = false;
        });
        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            'Foto profil berhasil dipilih dari galeri.',
          );
        }
      }
    } on PlatformException catch (pe) {
      AppLogger.e('PlatformException saat membuka galeri', error: pe);
      if (mounted) {
        final code = pe.code.toLowerCase();
        final msg = (pe.message ?? '').toLowerCase();
        if (code == 'channel-error' ||
            msg.contains('unable to establish connection') ||
            msg.contains('pigeon') ||
            msg.contains('image_picker')) {
          AppSnackBar.showError(
            context,
            'Plugin galeri baru ditambahkan. Silakan Stop & Run ulang aplikasi (Full Rebuild) agar plugin aktif di HP.',
          );
        } else if (code.contains('permission') ||
            code.contains('denied') ||
            msg.contains('permission') ||
            msg.contains('denied')) {
          _showPermissionSettingsDialog();
        } else {
          AppSnackBar.showError(
            context,
            'Gagal membuka galeri: ${pe.message ?? pe.code}',
          );
        }
      }
    } on MissingPluginException catch (mpe) {
      AppLogger.e('MissingPluginException image_picker', error: mpe);
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Plugin galeri baru ditambahkan. Silakan Stop & Run ulang aplikasi (Full Rebuild) agar plugin aktif di HP.',
        );
      }
    } catch (e) {
      AppLogger.e('Error saat membuka galeri', error: e);
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('missingpluginexception') ||
            errStr.contains('channel-error') ||
            errStr.contains('unable to establish connection')) {
          AppSnackBar.showError(
            context,
            'Plugin galeri baru ditambahkan. Silakan Stop & Run ulang aplikasi (Full Rebuild) agar plugin aktif di HP.',
          );
        } else if (errStr.contains('permission') || errStr.contains('denied')) {
          _showPermissionSettingsDialog();
        } else {
          AppSnackBar.showError(
            context,
            'Gagal memilih foto dari galeri: $e',
          );
        }
      }
    }
  }

  void _showAvatarPickerSheet() {
    final bool hasCustomAvatar = _pickedAvatarFile != null ||
        (!_isAvatarCleared && _selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto Profil Pengguna',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih foto profil dari galeri perangkat Anda untuk akun ARBatika.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: const Text(
                  'Buka galeri foto di perangkat Anda',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatarFromGallery();
                },
              ),
              if (hasCustomAvatar) ...[
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Gunakan Avatar Bawaan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: const Text(
                    'Kembalikan ke avatar standar ARBatika',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    setState(() {
                      _pickedAvatarFile = null;
                      _selectedAvatarUrl = null;
                      _isAvatarCleared = true;
                    });
                    Navigator.pop(sheetContext);
                    AppSnackBar.showSuccess(
                      context,
                      'Avatar bawaan berhasil dipilih.',
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGender == null || _selectedGender!.trim().isEmpty) {
      AppSnackBar.showError(context, 'Silakan pilih jenis kelamin Anda.');
      return;
    }

    // Format nomor telepon dengan kode negara Indonesia (+62)
    String cleanDigits = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.startsWith('0')) {
      cleanDigits = cleanDigits.substring(1);
    } else if (cleanDigits.startsWith('62')) {
      cleanDigits = cleanDigits.substring(2);
    }
    final fullPhone = '$_selectedCountryCode$cleanDigits';

    final viewModel = ref.read(authViewModelProvider.notifier);
    final success = await viewModel.updateProfile(
      name: _nameController.text.trim(),
      phone: fullPhone,
      gender: _selectedGender!,
      avatar: _isAvatarCleared ? '' : _selectedAvatarUrl,
      avatarFilePath: _pickedAvatarFile?.path,
    );

    if (!mounted) return;

    if (success) {
      AppSnackBar.showSuccess(
        context,
        'Profil Anda berhasil disimpan.',
      );

      final cachedLocation =
          ref.read(locationRepositoryProvider).getCachedLocation();

      if (cachedLocation == null) {
        // Belum pernah menyimpan lokasi / alamat -> Wajib memilih lokasi (GPS / Manual)
        context.go('/location');
      } else {
        // Sudah ada lokasi sebelumnya -> Jalankan sinkronisasi lokasi di background dan langsung ke dashboard
        ref.read(locationViewModelProvider.notifier).loadLocation();
        context.go('/dashboard');
      }
    } else {
      final authState = ref.read(authViewModelProvider);
      AppSnackBar.showError(
        context,
        authState.errorMessage ?? 'Gagal menyimpan profil. Silakan coba lagi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    const purpleBlueBorderColor = Color(0xFFA5B4FC);
    const purpleBlueFocusedColor = Color(0xFF6366F1);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Cokelat Melengkung
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: const _CompleteProfileHeaderClipper(),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.primary,
                      padding: EdgeInsets.only(
                        top: topPadding + 28,
                        bottom: 80,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Complete Your Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Lengkapi identitas Anda untuk melanjutkan belanja batik autentik di ARBatika',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFF5EBE6),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Avatar Melayang di Bawah Header
                  Positioned(
                    bottom: -45,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarPickerSheet,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _pickedAvatarFile != null
                                  ? Image.file(
                                      _pickedAvatarFile!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    )
                                  : (!_isAvatarCleared &&
                                          _selectedAvatarUrl != null &&
                                          _selectedAvatarUrl!.isNotEmpty)
                                      ? Image.network(
                                          _selectedAvatarUrl!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.person_rounded,
                                            size: 56,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 56,
                                          color: Color(0xFF94A3B8),
                                        ),
                            ),
                          ),
                        ),

                        // Tombol Buka Galeri / Ubah Foto
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _showAvatarPickerSheet,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.photo_library_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // 3. Form Isian Profil
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Full Name
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueBorderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueBorderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueFocusedColor,
                              width: 2.0,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2.0,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi.';
                          }
                          if (value.trim().length < 2) {
                            return 'Nama minimal terdiri dari 2 karakter.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Field 2: Phone Number dengan Kode Negara Indonesia (+62)
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: '812 3456 7890',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 18, right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '+62',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ],
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueBorderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueBorderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueFocusedColor,
                              width: 2.0,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2.0,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor telepon wajib diisi.';
                          }
                          final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length < 8) {
                            return 'Nomor telepon minimal 8 digit.';
                          }
                          if (digits.length > 15) {
                            return 'Nomor telepon maksimal 15 digit.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Field 3: Gender Dropdown
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        items: const [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Laki-laki (Male)'),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Perempuan (Female)'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedGender = val;
                          });
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B),
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Pilih jenis kelamin',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.wc_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueBorderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueBorderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: purpleBlueFocusedColor,
                              width: 2.0,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2.0,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jenis kelamin wajib dipilih.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // 4. Tombol Complete Profile
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Complete Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. Tautan Keluar / Ganti Akun jika diperlukan
                      Center(
                        child: TextButton.icon(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(authViewModelProvider.notifier)
                                      .logout();
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
                                },
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          label: const Text(
                            'Gunakan Akun Lain (Sign Out)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
