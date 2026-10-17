import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../store/presentation/viewmodels/store_providers.dart';

/// Splash Screen dengan tampilan logo di tengah dan background putih bersih
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
    // Ambil data toko, metode pembayaran, dan FAQ dari backend ke Riverpod State
    final fetchFuture =
        ref.read(storeViewModelProvider.notifier).fetchInitialData();

    // Waktu minimum tampilan splash screen (2 detik) untuk menjaga visual tetap mulus
    final minDisplayFuture = Future.delayed(const Duration(milliseconds: 2000));

    // Tunggu pengambilan data ke state dan durasi animasi minimal selesai bersamaan
    await Future.wait([fetchFuture, minDisplayFuture]);

    if (!mounted) return;

    final authState = ref.read(authViewModelProvider);

    if (authState.isAuthenticated) {
      context.go('/dashboard');
    } else {
      // Selalu tampilkan Welcome & Onboarding
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Image.asset(
                AssetConstants.logoSplashScreen,
                width: 280,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
