import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../profile/presentation/widgets/profile_header.dart';
import '../../../profile/presentation/widgets/profile_information.dart';
import '../../../profile/presentation/widgets/profile_menu_list.dart';
import '../widgets/category_section.dart';
import '../widgets/home_bottom_navigation.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/recommendation_section.dart';
import '../widgets/store_info_card.dart';

/// Halaman Utama (Home / Dashboard Screen) E-Commerce Heritage Batik Laweyan
class HomeView extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const HomeView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late int _currentTabIndex;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            // Tab 0: Home Page Utama
            _buildHomeContent(),

            // Tab 1: Bag / Keranjang Belanja (Placeholder)
            _buildPlaceholderTab(
              icon: Icons.shopping_bag_outlined,
              title: 'Keranjang Belanja Masih Kosong',
              subtitle:
                  'Pilih berbagai busana dan kain batik Laweyan terbaik untuk dimasukkan ke dalam keranjang.',
              buttonText: 'Jelajahi Koleksi Batik',
            ),

            // Tab 2: Wishlist Motif Favorit (Placeholder)
            _buildPlaceholderTab(
              icon: Icons.favorite_outline_rounded,
              title: 'Wishlist Anda Masih Kosong',
              subtitle:
                  'Simpan motif batik favorit Anda di sini untuk mempermudah pembelian berikutnya.',
              buttonText: 'Cari Motif Favorit',
            ),

            // Tab 3: Messages & Chat Toko (Placeholder)
            _buildPlaceholderTab(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Belum Ada Pesan Masuk',
              subtitle:
                  'Obrolan dengan pengrajin dan layanan pelanggan Heritage Batik akan ditampilkan di sini.',
              buttonText: 'Hubungi Customer Service',
            ),

            // Tab 4: Account Page (Profile & 8 Menu Pengaturan Akun)
            _buildAccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNavigation(
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  /// Konten Utama Tab Home (Urutan sesuai Scope & Acceptance Criteria)
  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Halaman beranda diperbarui.');
        }
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header (Alamat Pengiriman, Dropdown, Cart & Notification Badge)
            const HomeHeader(),

            // 2. Search Bar dengan Icon Filter
            HomeSearchBar(
              controller: _searchController,
            ),

            const SizedBox(height: 6),

            // 3. Banner Promo Carousel dengan Indikator Dots
            const PromoCarousel(),

            const SizedBox(height: 10),

            // 4. Information Card (Toko & Jarak + Poin URBatik)
            const StoreInfoCard(),

            const SizedBox(height: 12),

            // 5. Category Section (Sarung, Kain, Tunik, Anak-Anak, All)
            const CategorySection(),

            const SizedBox(height: 14),

            // 6. Recommendation Section (Daftar Produk Scroll Horizontal)
            const RecommendationSection(),

            // Ruang bawah agar rekomendasi tidak tertutup oleh floating pill bar
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  /// Tampilan Tab Placeholder yang Rapi untuk Bag, Wishlist, & Messages
  Widget _buildPlaceholderTab({
    required IconData icon,
    required String title,
    required String subtitle,
    String buttonText = 'Mulai Belanja Batik',
  }) {
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
                icon,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
                  _currentTabIndex = 0;
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
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan Tab Akun Pengguna (Account)
  /// Terintegrasi dengan ProfileInformation dan ProfileMenuList (8 Menu Pengaturan)
  Widget _buildAccountTab() {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    final String displayName =
        (user?.name != null && user!.name!.trim().isNotEmpty)
            ? user.name!
            : (user?.username != null && user!.username!.trim().isNotEmpty)
                ? user.username!
                : 'Agung Kusaeri';

    final String? avatarUrl = user?.avatarUrl;

    return Column(
      children: [
        // Header Tab Account
        ProfileHeader(
          title: 'Account',
          showBackButton: true,
          onBackTap: () {
            setState(() {
              _currentTabIndex = 0; // Kembali ke tab Home
            });
          },
        ),

        // Konten Akun yang Scrollable
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: 110, // Ruang bawah agar tidak tertutup floating rounded pill bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Profile Information: Foto Melingkar, Tombol Edit Pena, dan Nama
                ProfileInformation(
                  name: displayName,
                  subtitle: user?.email,
                  avatarUrl: avatarUrl,
                  onEditTap: () {
                    context.push('/complete-profile');
                  },
                ),

                const SizedBox(height: 28),

                // 2. Profile Menu List: 8 Menu Pengaturan Akun
                ProfileMenuList(
                  onLogout: () async {
                    await ref.read(authViewModelProvider.notifier).logout();
                    if (context.mounted) {
                      AppSnackBar.showSuccess(context, 'Berhasil keluar dari akun.');
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
