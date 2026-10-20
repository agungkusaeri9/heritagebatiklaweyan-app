import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../widgets/profile_header.dart';

/// Halaman Password Manager pada Settings Profile
class PasswordManagerView extends ConsumerStatefulWidget {
  const PasswordManagerView({super.key});

  @override
  ConsumerState<PasswordManagerView> createState() => _PasswordManagerViewState();
}

class _PasswordManagerViewState extends ConsumerState<PasswordManagerView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan input kata sandi baru untuk mengupdate checklist kriteria
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(() {});
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Ketentuan validasi password (sama dengan alur Forgot Password & Reset Password)
  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasUpperLower =>
      RegExp(r'[a-z]').hasMatch(_newPasswordController.text) &&
      RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get _hasSpecialChar => RegExp(r'[^\w\s]|_').hasMatch(_newPasswordController.text);

  bool get _isPasswordValid =>
      _hasMinLength && _hasUpperLower && _hasNumber && _hasSpecialChar;

  Widget _buildRequirementItem({
    required bool isMet,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? const Color(0xFFDCFCE7) : const Color(0xFFFFF1F2),
            border: Border.all(
              color: isMet ? const Color(0xFF86EFAC) : const Color(0xFFFECDD3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isMet ? Icons.check_rounded : Icons.close_rounded,
              size: 9.5,
              color: isMet ? const Color(0xFF15803D) : AppColors.errorText,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet ? const Color(0xFF15803D) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.shield_outlined,
                size: 13,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 5),
              Text(
                'Ketentuan Password:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRequirementItem(
                  isMet: _hasMinLength,
                  text: 'Min. 8 karakter',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRequirementItem(
                  isMet: _hasUpperLower,
                  text: 'Huruf besar & kecil',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildRequirementItem(
                  isMet: _hasNumber,
                  text: 'Ada angka (0-9)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRequirementItem(
                  isMet: _hasSpecialChar,
                  text: 'Simbol khusus (!@#..)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    // Validasi form field dasar
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi ketentuan password
    if (!_isPasswordValid) {
      AppSnackBar.showError(
        context,
        'Pastikan seluruh ketentuan kata sandi baru telah terpenuhi.',
      );
      return;
    }

    // Validasi konfirmasi password
    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppSnackBar.showError(
        context,
        'Konfirmasi kata sandi tidak cocok.',
      );
      return;
    }

    // Validasi perbedaan dengan current password
    if (_newPasswordController.text == _currentPasswordController.text) {
      AppSnackBar.showError(
        context,
        'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dioClient = ref.read(dioClientProvider);

      // Request API ke backend untuk update password user
      final response = await dioClient.dio.put(
        '/user/password',
        data: {
          'current_password': _currentPasswordController.text.trim(),
          'password': _newPasswordController.text,
          'password_confirmation': _confirmPasswordController.text,
        },
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final message = response.data is Map<String, dynamic>
          ? (response.data['message']?.toString() ?? 'Kata sandi Anda berhasil diperbarui.')
          : 'Kata sandi Anda berhasil diperbarui.';

      AppSnackBar.showSuccess(context, message);
      Navigator.pop(context);
    } on DioException catch (dioErr) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final exception = ref.read(dioClientProvider).handleDioError(dioErr);
      AppSnackBar.showError(context, exception.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      AppSnackBar.showError(
        context,
        'Terjadi kesalahan saat memperbarui kata sandi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar dengan tombol kembali dan judul "Password Manager"
            ProfileHeader(
              title: 'Password Manager',
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/settings');
                }
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 30,
                ),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Kata Sandi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masukkan kata sandi saat ini dan buat kata sandi baru untuk menjaga keamanan akun Anda.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 1. Current Password
                        AppTextField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          hint: 'Masukkan kata sandi saat ini',
                          isPassword: true,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Kata sandi saat ini wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Link Forgot Password? di bawah Current Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              context.push(
                                '/forgot-password',
                                extra: user?.email,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. New Password
                        AppTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          hint: 'Minimal 8 karakter',
                          isPassword: true,
                          prefixIcon: const Icon(
                            Icons.key_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Kata sandi baru wajib diisi';
                            }
                            if (!_isPasswordValid) {
                              return 'Kata sandi belum memenuhi seluruh ketentuan';
                            }
                            if (val == _currentPasswordController.text) {
                              return 'Kata sandi baru tidak boleh sama dengan kata sandi saat ini';
                            }
                            return null;
                          },
                        ),

                        // Live Checklist Ketentuan Password (sama seperti di Forgot / Reset Password)
                        _buildPasswordRequirements(),

                        // 3. Confirm New Password
                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          hint: 'Ulangi kata sandi baru',
                          isPassword: true,
                          prefixIcon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Konfirmasi kata sandi wajib diisi';
                            }
                            if (val != _newPasswordController.text) {
                              return 'Konfirmasi kata sandi harus sama';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Tombol Change Password Fixed di Bagian Bawah Layar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 8
              : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: AppButton(
          text: 'Change Password',
          isLoading: _isLoading,
          onPressed: _handleSubmit,
        ),
      ),
    );
  }
}
