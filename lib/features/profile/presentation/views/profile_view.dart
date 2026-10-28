import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../widgets/profile_bottom_navigation.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_information.dart';
import '../widgets/profile_menu_list.dart';

/// Halaman Profile / Account E-Commerce Heritage Batik
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  // Tab Account aktif pada index 3 sesuai 4 menu baru (Home, Wishlist, History, Account)
  int _currentTabIndex = 3;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    // Nama dan Avatar Pengguna (dengan fallback terstandarisasi)
    final String displayName =
        (user?.name != null && user!.name.trim().isNotEmpty)
            ? user.name
            : (user?.username != null && user!.username.trim().isNotEmpty)
                ? user.username
                : 'Agung Kusaeri';

    final String? avatarUrl = user?.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Account (Tombol Back & Judul "Account")
            ProfileHeader(
              title: 'Account',
              onBackTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/dashboard');
                }
              },
            ),

            // 2. Konten Profil yang Scrollable
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex == 3 ? 0 : 1,
                children: [
                  // Tab 3 (Aktif): Konten Halaman Profile Utama
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Information: Foto Melingkar, Tombol Edit Pena, dan Nama
                        ProfileInformation(
                          name: displayName,
                          subtitle: user?.email,
                          avatarUrl: avatarUrl,
                          onEditTap: () {
                            context.push('/your-profile');
                          },
                        ),

                        const SizedBox(height: 28),

                        // Profile Menu List: 8 Menu Pengaturan Akun
                        ProfileMenuList(
                          onLogout: () async {
                            await ref.read(authViewModelProvider.notifier).logout();
                            if (!context.mounted) return;
                            AppSnackBar.showSuccess(context, 'Berhasil keluar dari akun.');
                            context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),

                  // Placeholder Tab Lainnya (Home, Wishlist, History)
                  _buildPlaceholderTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // 3. Bottom Navigation Bersih & Minimalis (4 Menu)
      bottomNavigationBar: ProfileBottomNavigation(
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          if (index == 0) {
            // Kembali ke Home
            context.go('/dashboard');
            return;
          }
          if (index == 2) {
            // Buka My Orders
            context.push('/orders');
            return;
          }

          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildPlaceholderTab() {
    String tabTitle = 'Halaman Sedang Disiapkan';
    IconData tabIcon = Icons.auto_awesome_rounded;

    switch (_currentTabIndex) {
      case 0:
        tabTitle = 'Home';
        tabIcon = Icons.home_rounded;
        break;
      case 1:
        tabTitle = 'Wishlist Motif Favorit';
        tabIcon = Icons.favorite_rounded;
        break;
      case 2:
        tabTitle = 'Riwayat Transaksi';
        tabIcon = Icons.receipt_long_rounded;
        break;
      case 3:
        tabTitle = 'Account Pengguna';
        tabIcon = Icons.person_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tabIcon,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tabTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini sedang dalam pengembangan aktif dan akan segera hadir untuk Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentTabIndex = 3;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Kembali ke Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
