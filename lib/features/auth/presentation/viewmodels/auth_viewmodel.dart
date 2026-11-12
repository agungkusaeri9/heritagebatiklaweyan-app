import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// ViewModel untuk Authentication Toko Online (MVVM pattern dengan Riverpod Notifier)
class AuthViewModel extends Notifier<AuthState> {
  late final LoginUseCase _loginUseCase;
  late final RegisterUseCase _registerUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _loginUseCase = ref.watch(authLoginUseCaseProvider);
    _registerUseCase = ref.watch(authRegisterUseCaseProvider);
    _logoutUseCase = ref.watch(authLogoutUseCaseProvider);
    _getCurrentUserUseCase = ref.watch(authGetCurrentUserUseCaseProvider);
    _authRepository = ref.watch(authRepositoryProvider);

    // Cek status sesi login saat inisialisasi aplikasi
    Future.microtask(() => checkAuthStatus());

    return const AuthState(
      status: AuthStatus.initial,
      logs: ['Inisialisasi sistem autentikasi toko online...'],
    );
  }

  /// Cek apakah pengguna sudah memiliki token aktif
  Future<void> checkAuthStatus() async {
    state = state.addLog('Memeriksa sesi login tersimpan di secure storage...');

    final result = await _getCurrentUserUseCase();
    result.fold(
      onSuccess: (user) {
        if (user != null) {
          state = state
              .addLog('Sesi ditemukan. Selamat datang kembali, ${user.username}!')
              .copyWith(
                status: AuthStatus.authenticated,
                user: user,
              );
        } else {
          state = state
              .addLog('Belum ada sesi aktif. Silakan masuk ke akun Anda.')
              .copyWith(status: AuthStatus.unauthenticated, clearUser: true);
        }
      },
      onFailure: (failure) {
        state = state
            .addLog('Pemeriksaan token gagal: ${failure.message}')
            .copyWith(status: AuthStatus.unauthenticated, clearUser: true);
      },
    );
  }

  /// Eksekusi Login Toko Online
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state
        .copyWith(status: AuthStatus.loading, clearError: true)
        .addLog('Mengirim permintaan login ke server...');

    AppLogger.i('AuthViewModel: Memproses login untuk $email');

    final result = await _loginUseCase(email: email, password: password);

    return result.fold(
      onSuccess: (user) {
        // Kirim FCM Token ke backend setelah berhasil login
        _authRepository.updateFcmTokenAfterLogin();

        state = state
            .addLog('Login berhasil. Token disimpan secara aman.')
            .copyWith(
              status: AuthStatus.authenticated,
              user: user,
              clearError: true,
            );
        return true;
      },
      onFailure: (failure) {
        AppLogger.w('AuthViewModel login failure: ${failure.message}');
        state = state
            .addLog('Login gagal: ${failure.message}')
            .copyWith(
              status: AuthStatus.error,
              errorMessage: failure.message,
            );
        return false;
      },
    );
  }

  /// Eksekusi Register Akun Baru
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state
        .copyWith(status: AuthStatus.loading, clearError: true)
        .addLog('Membuat akun pembeli baru...');

    AppLogger.i('AuthViewModel: Mendaftarkan akun $username ($email)');

    final result = await _registerUseCase(
      username: username,
      email: email,
      password: password,
    );

    return result.fold(
      onSuccess: (user) {
        // Kirim FCM Token ke backend setelah berhasil register
        _authRepository.updateFcmTokenAfterLogin();

        state = state
            .addLog('Akun berhasil dibuat. Selamat datang di Heritage Batik!')
            .copyWith(
              status: AuthStatus.authenticated,
              user: user,
              clearError: true,
            );
        return true;
      },
      onFailure: (failure) {
        AppLogger.w('AuthViewModel register failure: ${failure.message}');
        state = state
            .addLog('Pendaftaran gagal: ${failure.message}')
            .copyWith(
              status: AuthStatus.error,
              errorMessage: failure.message,
            );
        return false;
      },
    );
  }

  /// Eksekusi Logout
  Future<void> logout() async {
    state = state.addLog('Menghapus token sesi dari penyimpanan...');
    await _logoutUseCase();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      logs: ['Logout berhasil. Sesi telah berakhir.'],
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Melengkapi atau memperbarui profil pengguna (Nama, Telepon, Gender, Avatar)
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String gender,
    String? avatar,
    String? avatarFilePath,
  }) async {
    state = state
        .copyWith(isSubmitting: true, clearError: true)
        .addLog('Menyimpan data profil pengguna ke server...');

    AppLogger.i(
      'AuthViewModel: Memperbarui profil $name, $phone, $gender, avatarFile: $avatarFilePath',
    );

    final result = await _authRepository.updateProfile(
      name: name,
      phone: phone,
      gender: gender,
      avatar: avatar,
      avatarFilePath: avatarFilePath,
    );

    return result.fold(
      onSuccess: (updatedUser) {
        state = state
            .addLog('Profil berhasil diperbarui dan disinkronkan!')
            .copyWith(
              status: AuthStatus.authenticated,
              user: updatedUser,
              isSubmitting: false,
              clearError: true,
            );
        return true;
      },
      onFailure: (failure) {
        AppLogger.w('AuthViewModel updateProfile failure: ${failure.message}');
        state = state
            .addLog('Gagal memperbarui profil: ${failure.message}')
            .copyWith(
              status: AuthStatus.authenticated, // Pertahankan sesi autentikasi
              isSubmitting: false,
              errorMessage: failure.message,
            );
        return false;
      },
    );
  }

  /// Kirim kode OTP pemulihan kata sandi
  Future<Result<String>> sendPasswordResetOtp(String email) async {
    state = state
        .copyWith(status: AuthStatus.loading, clearError: true)
        .addLog('Mengirim permintaan OTP reset password...');
    final result = await _authRepository.sendPasswordResetOtp(email: email);
    result.fold(
      onSuccess: (msg) {
        state = state
            .copyWith(status: AuthStatus.unauthenticated, clearError: true)
            .addLog(msg);
      },
      onFailure: (failure) {
        state = state
            .copyWith(status: AuthStatus.error, errorMessage: failure.message)
            .addLog('Gagal kirim OTP: ${failure.message}');
      },
    );
    return result;
  }

  /// Verifikasi kode OTP pemulihan kata sandi
  Future<Result<String>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    state = state
        .copyWith(status: AuthStatus.loading, clearError: true)
        .addLog('Memverifikasi kode OTP...');
    final result = await _authRepository.verifyPasswordResetOtp(
      email: email,
      otp: otp,
    );
    result.fold(
      onSuccess: (_) {
        state = state
            .copyWith(status: AuthStatus.unauthenticated, clearError: true)
            .addLog('OTP terverifikasi.');
      },
      onFailure: (failure) {
        state = state
            .copyWith(status: AuthStatus.error, errorMessage: failure.message)
            .addLog('Verifikasi OTP gagal: ${failure.message}');
      },
    );
    return result;
  }

  /// Reset kata sandi menggunakan reset token
  Future<Result<String>> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state
        .copyWith(status: AuthStatus.loading, clearError: true)
        .addLog('Menyimpan kata sandi baru...');
    final result = await _authRepository.resetPassword(
      email: email,
      resetToken: resetToken,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    result.fold(
      onSuccess: (msg) {
        state = state
            .copyWith(status: AuthStatus.unauthenticated, clearError: true)
            .addLog(msg);
      },
      onFailure: (failure) {
        state = state
            .copyWith(status: AuthStatus.error, errorMessage: failure.message)
            .addLog('Reset kata sandi gagal: ${failure.message}');
      },
    );
    return result;
  }

  /// Kirim kode OTP verifikasi email
  Future<Result<String>> sendEmailVerificationOtp(String email) async {
    state = state.addLog('Mengirim kode OTP verifikasi email...');
    final result = await _authRepository.sendEmailVerificationOtp(email: email);
    result.fold(
      onSuccess: (msg) {
        state = state.addLog(msg);
      },
      onFailure: (failure) {
        state = state.addLog('Gagal kirim OTP verifikasi: ${failure.message}');
      },
    );
    return result;
  }

  /// Verifikasi kode OTP verifikasi email
  Future<Result<UserEntity>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    state = state.addLog('Memverifikasi kode OTP email...');
    final result = await _authRepository.verifyEmailOtp(
      email: email,
      otp: otp,
    );
    result.fold(
      onSuccess: (user) {
        state = state
            .copyWith(
              user: user,
              status: AuthStatus.authenticated,
              clearError: true,
            )
            .addLog('Email berhasil diverifikasi.');
      },
      onFailure: (failure) {
        state = state
            .copyWith(errorMessage: failure.message)
            .addLog('Verifikasi email gagal: ${failure.message}');
      },
    );
    return result;
  }
}
