import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              child: _buildProfileTab(user, displayName, avatarUrl),
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
          if (index == 1) {
            // Buka Wishlist
            context.push('/wishlist');
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

  Widget _buildProfileTab(
    dynamic user,
    String displayName,
    String? avatarUrl,
  ) {
    return SingleChildScrollView(
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
    );
  }
}
