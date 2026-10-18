import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../viewmodels/auth_providers.dart';
import '../widgets/otp_input_widget.dart';
import 'login_view.dart';

/// Halaman Verifikasi Kode OTP 6 Kotak
class VerifyOtpView extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpView({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends ConsumerState<VerifyOtpView> {
  final GlobalKey<OtpInputWidgetState> _otpKey = GlobalKey<OtpInputWidgetState>();
  String _currentOtp = '';
  bool _isLoading = false;
  bool _isResending = false;

  // Countdown timer 60 detik untuk kirim ulang
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    final viewModel = ref.read(authViewModelProvider.notifier);
    final result = await viewModel.sendPasswordResetOtp(widget.email);

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    result.fold(
      onSuccess: (message) {
        _otpKey.currentState?.clear();
        _currentOtp = '';
        _startCountdown();
        AppSnackBar.showSuccess(context, 'Kode OTP baru telah dikirimkan ke email Anda.');
      },
      onFailure: (failure) {
        AppSnackBar.showError(context, failure.message);
      },
    );
  }

  Future<void> _handleVerify() async {
    FocusScope.of(context).unfocus();

    if (_currentOtp.length < 6) {
      AppSnackBar.showError(context, 'Masukkan seluruh 6 digit kode OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final viewModel = ref.read(authViewModelProvider.notifier);
    final result = await viewModel.verifyPasswordResetOtp(
      email: widget.email,
      otp: _currentOtp,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.fold(
      onSuccess: (resetToken) {
        AppSnackBar.showSuccess(context, 'Kode OTP berhasil diverifikasi.');
        context.push(
          '/reset-password',
          extra: {
            'email': widget.email,
            'reset_token': resetToken,
            'resetToken': resetToken,
          },
        );
      },
      onFailure: (failure) {
        AppSnackBar.showError(context, failure.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // 1. Header Section dengan Curved Clipper
              ClipPath(
                clipper: const CurvedHeaderClipper(),
                child: Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: EdgeInsets.only(
                    top: topPadding + 16,
                    bottom: 60,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    children: [
                      // Tombol Kembali
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verification Code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          'We have sent the 6-digit OTP code to:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Email chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Form Section OTP
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter 6-Digit OTP Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6 OTP Boxes
                    OtpInputWidget(
                      key: _otpKey,
                      length: 6,
                      onChanged: (otp) {
                        _currentOtp = otp;
                      },
                      onCompleted: (otp) {
                        _currentOtp = otp;
                        _handleVerify();
                      },
                    ),
                    const SizedBox(height: 28),

                    // Countdown & Resend Option
                    Center(
                      child: _secondsRemaining > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : GestureDetector(
                              onTap: _isResending ? null : _handleResendOtp,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          "Didn't receive the code? ",
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          'Resend Code',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify Code',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
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
}
