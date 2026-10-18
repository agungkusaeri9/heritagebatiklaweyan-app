import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_providers.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/auth/presentation/views/forgot_password_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/auth/presentation/views/reset_password_view.dart';
import '../../features/auth/presentation/views/verify_otp_view.dart';
import '../../features/dashboard/presentation/views/dashboard_view.dart';
import '../../features/dashboard/presentation/views/permissions_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/onboarding/presentation/views/welcome_view.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import '../storage/storage_providers.dart';

final routerKey = GlobalKey<NavigatorState>();

/// Provider GoRouter terintegrasi dengan Riverpod Auth State Guard
final routerProvider = Provider<GoRouter>((ref) {
  // Gunakan ref.read agar GoRouter tidak diinisialisasi ulang setiap ada perubahan auth state
  final authNotifier = ValueNotifier<AuthState>(ref.read(authViewModelProvider));

  ref.listen<AuthState>(authViewModelProvider, (previous, next) {
    authNotifier.value = next;
  });

  ref.onDispose(() {
    authNotifier.dispose();
  });

  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeView(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => ForgotPasswordView(
          initialEmail: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        builder: (context, state) {
          final email = (state.extra as String?) ??
              state.uri.queryParameters['email'] ??
              '';
          return VerifyOtpView(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final extraMap = state.extra is Map ? (state.extra as Map) : null;
          final email = extraMap?['email']?.toString() ??
              state.uri.queryParameters['email'] ??
              '';
          final resetToken = extraMap?['reset_token']?.toString() ??
              extraMap?['resetToken']?.toString() ??
              state.uri.queryParameters['token'] ??
              state.uri.queryParameters['reset_token'] ??
              '';
          return ResetPasswordView(
            email: email,
            resetToken: resetToken,
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const PermissionsView(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final storage = ref.read(localStorageServiceProvider);
      final isAuthenticated = authState.isAuthenticated;
      final hasCompletedOnboarding = storage.hasCompletedOnboarding();

      final isSplash = state.matchedLocation == '/splash';
      final isWelcomeOrOnboarding = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/reset-password';

      // Biarkan splash screen selesai menampilkan animasi logo sebelum bernavigasi
      if (isSplash) {
        return null;
      }

      // Jika belum login dan sedang berada di halaman login/register, TETAP DI HALAMAN INI!
      if (!isAuthenticated && isAuthRoute) {
        return null;
      }

      // Jika belum login tapi sudah pernah onboarding, jangan tampilkan welcome/onboarding lagi
      if (!isAuthenticated && hasCompletedOnboarding && isWelcomeOrOnboarding) {
        return '/login';
      }

      // Jika belum selesai onboarding dan belum login (serta bukan di halaman login/register)
      if (!isAuthenticated && !hasCompletedOnboarding && !isWelcomeOrOnboarding && !isAuthRoute) {
        return '/welcome';
      }

      // Jika belum login dan mencoba mengakses rute internal
      if (!isAuthenticated && !isAuthRoute && !isWelcomeOrOnboarding) {
        return hasCompletedOnboarding ? '/login' : '/welcome';
      }

      // Jika sudah login dan masih di halaman login/register/welcome/onboarding
      if (isAuthenticated && (isAuthRoute || isWelcomeOrOnboarding)) {
        return '/dashboard';
      }

      return null;
    },
  );
});
