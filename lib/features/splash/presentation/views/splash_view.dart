import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../location/presentation/viewmodels/location_providers.dart';
import '../../../store/presentation/viewmodels/store_providers.dart';
import '../../../../core/storage/storage_providers.dart';

/// Splash Screen dengan tampilan logo di tengah dan feedback status/koneksi di bawahnya
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Jalankan navigasi dan fetch state setelah widget selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSplashNavigation();
    });
  }

  Future<void> _handleSplashNavigation() async {
    // Hanya cek koneksi ping ke backend (tanpa mengambil setting, metode pembayaran, atau FAQ)
    final pingFuture =
        ref.read(storeViewModelProvider.notifier).checkConnection();

    // Waktu minimum tampilan splash screen (1.5 detik) untuk menjaga visual tetap mulus
    final minDisplayFuture = Future.delayed(const Duration(milliseconds: 1500));

    // Tunggu pengecekan ping dan durasi animasi minimal selesai bersamaan
    final results = await Future.wait([pingFuture, minDisplayFuture]);
    final isPingOk = results[0] as bool;

    if (!mounted) return;

    // Lanjutkan navigasi jika ping ke backend OK
    if (isPingOk) {
      _proceedToNextScreen();
    }
  }

  void _proceedToNextScreen() {
    if (!mounted) return;

    final authState = ref.read(authViewModelProvider);
    final storage = ref.read(localStorageServiceProvider);
    final hasCompletedOnboarding = storage.hasCompletedOnboarding();

    if (authState.isAuthenticated) {
      if (authState.user != null && !authState.user!.isProfileComplete) {
        context.go('/complete-profile');
      } else {
        final hasLocation =
            ref.read(locationRepositoryProvider).getCachedLocation() != null;
        if (!hasLocation) {
          context.go('/location');
        } else {
          ref.read(locationViewModelProvider.notifier).loadLocation();
          context.go('/dashboard');
        }
      }
    } else if (hasCompletedOnboarding) {
      context.go('/login');
    } else {
      context.go('/welcome');
    }
  }

  String _getUserFriendlyMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'Gagal terhubung ke layanan. Periksa koneksi Anda.';
    }
    final lower = error.toLowerCase();
    if (lower.contains('timeout')) {
      return 'Koneksi melebihi batas waktu. Periksa jaringan Anda.';
    }
    if (lower.contains('tidak dapat terhubung') ||
        lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('host')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
    }
    return 'Terjadi kendala koneksi ke server. Silakan coba lagi nanti.';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeViewModelProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Logo di tengah bersih
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Image.asset(
                      AssetConstants.logoSplashScreen,
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Area Status di paling bawah layar: Loading atau Pesan Error user-friendly
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: storeState.isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menghubungkan ke server...',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        )
                      : (storeState.errorMessage != null
                          ? GestureDetector(
                              onTap: _handleSplashNavigation,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.wifi_off_rounded,
                                      color: AppColors.error,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _getUserFriendlyMessage(
                                          storeState.errorMessage,
                                        ),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.refresh_rounded,
                                      color: AppColors.error,
                                      size: 15,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
