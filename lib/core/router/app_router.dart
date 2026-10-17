import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_providers.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/dashboard/presentation/views/dashboard_view.dart';
import '../../features/dashboard/presentation/views/permissions_view.dart';

final routerKey = GlobalKey<NavigatorState>();

/// Provider GoRouter terintegrasi dengan Riverpod Auth State Guard
final routerProvider = Provider<GoRouter>((ref) {
  // Notifier untuk memicu evaluasi rute saat status autentikasi berubah
  final authNotifier = ValueNotifier<AuthState>(ref.watch(authViewModelProvider));

  ref.listen<AuthState>(authViewModelProvider, (previous, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    routes: [
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
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Jika belum login dan mencoba mengakses rute internal
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Jika sudah login dan masih di halaman login/register
      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
  );
});
