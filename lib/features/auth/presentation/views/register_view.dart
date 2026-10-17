import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/auth_providers.dart';

/// Custom Clipper untuk membuat lengkungan cembung elegan di bagian bawah Header
class CurvedHeaderClipper extends CustomClipper<Path> {
  const CurvedHeaderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    // Lengkungan quadratic bezier halus ke tengah bawah lalu ke kanan
    final controlPoint = Offset(size.width / 2, size.height);
    final endPoint = Offset(size.width, size.height - 40);

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

/// Halaman Registrasi Akun Baru (Create Account / Sign Up)
class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeWithTerms = false;
  bool _termsError = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Aturan Validasi Password
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpperLower =>
      RegExp(r'[a-z]').hasMatch(_passwordController.text) &&
      RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber =>
      RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecialChar =>
      RegExp(r'[^\w\s]|_').hasMatch(_passwordController.text);

  bool get _isPasswordValid =>
      _hasMinLength && _hasUpperLower && _hasNumber && _hasSpecialChar;

  Widget _buildRequirementItem({
    required bool isMet,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              border: Border.all(
                color: isMet ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                isMet ? Icons.check_rounded : Icons.close_rounded,
                size: 13,
                color: isMet ? const Color(0xFF15803D) : const Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
                color: isMet ? const Color(0xFF15803D) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: Color(0xFF475569),
              ),
              SizedBox(width: 6),
              Text(
                'Ketentuan Password:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRequirementItem(
            isMet: _hasMinLength,
            text: 'Minimal 8 karakter',
          ),
          _buildRequirementItem(
            isMet: _hasUpperLower,
            text: 'Huruf besar (A-Z) dan huruf kecil (a-z)',
          ),
          _buildRequirementItem(
            isMet: _hasNumber,
            text: 'Mengandung angka (0-9)',
          ),
          _buildRequirementItem(
            isMet: _hasSpecialChar,
            text: 'Karakter khusus / simbol (!@#\$%^&*...)',
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Term & Condition',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'By creating an account on ARBatika / Heritage Batik Laweyan, you agree to our terms of service, including authentic batik order processing, privacy policy, and virtual try-on usage guidelines.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!_agreeWithTerms) {
      setState(() {
        _termsError = true;
      });
    }

    if (!isFormValid || !_agreeWithTerms || !_isPasswordValid) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!_isPasswordValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pastikan seluruh ketentuan password telah terpenuhi (semua ceklis hijau).'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (!_agreeWithTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree with the Term & Condition to continue'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final viewModel = ref.read(authViewModelProvider.notifier);
    final success = await viewModel.register(
      username: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to ARBatika.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/dashboard');
    } else {
      final authState = ref.read(authViewModelProvider);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage ?? 'Registration failed. Please try again.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    const purpleBlueBorderColor = Color(0xFFA5B4FC);
    const purpleBlueFocusedColor = Color(0xFF6366F1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: purpleBlueBorderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: purpleBlueBorderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: purpleBlueFocusedColor, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.0),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Section dengan Curved Bottom Clipper
              ClipPath(
                clipper: const CurvedHeaderClipper(),
                child: Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: EdgeInsets.only(
                    top: topPadding + 28,
                    bottom: 56,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          'Fill your information below or register with your social account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Registration Form Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name Input
                      _buildFormField(
                        label: 'Name',
                        hintText: 'John Doe',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Email Input
                      _buildFormField(
                        label: 'Email',
                        hintText: 'example@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Password Input
                      _buildFormField(
                        label: 'Password',
                        hintText: '••••••••',
                        controller: _passwordController,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (!_isPasswordValid) {
                            return 'Password belum memenuhi seluruh ketentuan di bawah';
                          }
                          return null;
                        },
                      ),

                      // Daftar Ketentuan Password (Ceklis / X)
                      _buildPasswordRequirements(),

                      // 4. Terms & Conditions Checkbox & Clickable Link
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreeWithTerms,
                              onChanged: (val) {
                                setState(() {
                                  _agreeWithTerms = val ?? false;
                                  if (_agreeWithTerms) _termsError = false;
                                });
                              },
                              activeColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(
                                color: _termsError ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Agree with ',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF475569),
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Term & Condition',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4F46E5),
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_termsError) ...[
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.only(left: 34),
                          child: Text(
                            'Please agree with the Term & Condition',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // 5. Sign Up Button (Cokelat #704F38, Rounded Pill, Full Width)
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
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
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6. Footer Section: Already have an account? Sign In
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/login');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
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
