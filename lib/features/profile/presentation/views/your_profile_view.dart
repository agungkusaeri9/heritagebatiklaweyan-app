import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';

/// Clipper untuk lengkungan cembung elegan di bagian bawah Header profil
class _YourProfileHeaderClipper extends CustomClipper<Path> {
  const _YourProfileHeaderClipper();

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

/// Layar Your Profile (Edit Profil Akun Pengguna)
/// Memiliki form lengkap seperti Complete Profile (Foto Profil, Nama Lengkap,
/// Email terverifikasi, Nomor Telepon +62, dan Jenis Kelamin), tombol kembali,
/// serta fungsionalitas simpan langsung ke backend API.
class YourProfileView extends ConsumerStatefulWidget {
  const YourProfileView({super.key});

  @override
  ConsumerState<YourProfileView> createState() => _YourProfileViewState();
}

class _YourProfileViewState extends ConsumerState<YourProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _selectedGender;
  String? _selectedAvatarUrl;
  File? _pickedAvatarFile;
  bool _isAvatarCleared = false;
  final ImagePicker _imagePicker = ImagePicker();

  final String _countryCode = '+62';

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authViewModelProvider).user;

    _nameController = TextEditingController(
      text: currentUser?.name ?? currentUser?.username ?? '',
    );

    _emailController = TextEditingController(
      text: currentUser?.email ?? '',
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Dialog yang memandu pengguna membuka Pengaturan jika izin galeri ditolak permanen
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

  /// Membuka galeri foto dengan pengecekan izin otomatis
  Future<void> _pickAvatarFromGallery() async {
    try {
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
            'Foto profil baru berhasil dipilih dari galeri.',
          );
        }
      }
    } on PlatformException catch (pe) {
      AppLogger.e('PlatformException saat membuka galeri', error: pe);
      if (mounted) {
        final code = pe.code.toLowerCase();
        final msg = (pe.message ?? '').toLowerCase();
        if (code.contains('permission') || msg.contains('permission')) {
          _showPermissionSettingsDialog();
        } else {
          AppSnackBar.showError(
            context,
            'Gagal membuka galeri: ${pe.message ?? pe.code}',
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error saat membuka galeri', error: e);
      if (mounted) {
        AppSnackBar.showError(context, 'Gagal memilih foto dari galeri: $e');
      }
    }
  }

  /// Bottom sheet pemilih opsi foto avatar
  void _showAvatarPickerSheet() {
    final bool hasCustomAvatar = _pickedAvatarFile != null ||
        (!_isAvatarCleared &&
            _selectedAvatarUrl != null &&
            _selectedAvatarUrl!.isNotEmpty);

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
              Text(
                'Foto Profil Pengguna',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih foto terbaik untuk profil akun Heritage Batik Anda.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
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
                title: Text(
                  'Pilih dari Galeri',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                subtitle: Text(
                  'Buka galeri foto di perangkat Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Gunakan Avatar Bawaan',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    'Kembalikan ke avatar standar Heritage Batik',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
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
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
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

  /// Eksekusi penyimpanan perubahan profil ke server backend
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
    final fullPhone = '$_countryCode$cleanDigits';

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
        'Profil Anda berhasil diperbarui.',
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/dashboard');
      }
    } else {
      final authState = ref.read(authViewModelProvider);
      AppSnackBar.showError(
        context,
        authState.errorMessage ?? 'Gagal memperbarui profil. Silakan coba lagi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    const inputBorderColor = Color(0xFFE2E8F0);
    const focusedBorderColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Melengkung dengan Tombol Back & Judul "Your Profile"
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipPath(
                  clipper: const _YourProfileHeaderClipper(),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: EdgeInsets.only(
                      top: topPadding + 14,
                      bottom: 80,
                      left: 20,
                      right: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bar Navigasi Atas (Tombol Kembali & Judul)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('your_profile_back_button'),
                                onTap: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  } else {
                                    context.go('/dashboard');
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'Your Profile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 40, height: 40),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Kelola dan perbarui informasi akun Heritage Batik Anda',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFF5EBE6),
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
                        key: const Key('your_profile_avatar_tap'),
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
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
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

                      // Tombol Ubah Foto (Icon Kamera di Kanan Bawah)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          key: const Key('your_profile_camera_button'),
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
                              Icons.camera_alt_rounded,
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
                    Text(
                      'Full Name',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('your_profile_name_input'),
                      controller: _nameController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
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
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: inputBorderColor,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: inputBorderColor,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: focusedBorderColor,
                            width: 1.8,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.8,
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

                    // Field 2: Email Address (Read-only dengan badge verified)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Email Address',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('your_profile_email_input'),
                      controller: _emailController,
                      readOnly: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Email terhubung dengan akun utama dan tidak dapat diubah.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Field 3: Phone Number dengan Kode Negara (+62)
                    Text(
                      'Phone Number',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('your_profile_phone_input'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: '812 3456 7890',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 18, right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+62',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
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
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: inputBorderColor,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: inputBorderColor,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: focusedBorderColor,
                            width: 1.8,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.8,
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

                    // Field 4: Gender Dropdown
                    Text(
                      'Gender',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('your_profile_gender_input'),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Pilih jenis kelamin',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
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
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: inputBorderColor,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: inputBorderColor,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: focusedBorderColor,
                            width: 1.8,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.8,
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

                    const SizedBox(height: 36),

                    // 4. Tombol Simpan Perubahan (Save Changes)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        key: const Key('your_profile_save_button'),
                        onPressed: authState.isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: authState.isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

