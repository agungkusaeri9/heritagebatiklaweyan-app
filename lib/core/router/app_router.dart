import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_providers.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/auth/presentation/views/complete_profile_view.dart';
import '../../features/auth/presentation/views/forgot_password_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/auth/presentation/views/reset_password_view.dart';
import '../../features/auth/presentation/views/verify_otp_view.dart';
import '../../features/dashboard/presentation/views/permissions_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/location/presentation/viewmodels/location_providers.dart';
import '../../features/location/presentation/views/location_selection_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/onboarding/presentation/views/welcome_view.dart';
import '../../features/profile/presentation/views/help_center_view.dart';
import '../../features/profile/presentation/views/notification_settings_view.dart';
import '../../features/profile/presentation/views/password_manager_view.dart';
import '../../features/profile/presentation/views/privacy_policy_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/profile/presentation/views/settings_view.dart';
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
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfileView(),
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
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const PermissionsView(),
      ),
      GoRoute(
        path: '/location',
        name: 'location',
        builder: (context, state) => const LocationSelectionView(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsView(),
      ),
      GoRoute(
        path: '/settings/password',
        name: 'password-manager',
        builder: (context, state) => const PasswordManagerView(),
      ),
      GoRoute(
        path: '/help-center',
        name: 'help-center',
        builder: (context, state) => const HelpCenterView(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyView(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final storage = ref.read(localStorageServiceProvider);
      final isAuthenticated = authState.isAuthenticated;
      final hasCompletedOnboarding = storage.hasCompletedOnboarding();
      final isProfileComplete = authState.user?.isProfileComplete ?? true;

      final isSplash = state.matchedLocation == '/splash';
      final isWelcomeOrOnboarding = state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/reset-password';
      final isCompleteProfileRoute = state.matchedLocation == '/complete-profile';
      final isLocationRoute = state.matchedLocation == '/location';

      // Biarkan splash screen selesai menampilkan animasi logo sebelum bernavigasi
      if (isSplash) {
        return null;
      }

      // Rute pemilihan lokasi dapat diakses oleh guest maupun user yang sudah login
      if (isLocationRoute) {
        return null;
      }

      // Jika belum login dan mencoba ke complete profile
      if (!isAuthenticated && isCompleteProfileRoute) {
        return '/login';
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

      // Jika sudah login:
      if (isAuthenticated) {
        // Jika profil belum lengkap:
        if (!isProfileComplete) {
          if (!isCompleteProfileRoute) {
            return '/complete-profile';
          }
          return null;
        }

        // Cek apakah user sudah memiliki lokasi tersimpan di cache
        final hasLocation =
            ref.read(locationRepositoryProvider).getCachedLocation() != null;

        // Jika profil sudah lengkap:
        if (isCompleteProfileRoute) {
          if (hasLocation) {
            ref.read(locationViewModelProvider.notifier).loadLocation();
            return '/dashboard';
          }
          return '/location';
        }

        // Jika berada di auth routes (/login, /register, dll):
        if (isAuthRoute || isWelcomeOrOnboarding) {
          if (hasLocation) {
            ref.read(locationViewModelProvider.notifier).loadLocation();
            return '/dashboard';
          }
          return '/location';
        }
      }

      return null;
    },
  );
});
