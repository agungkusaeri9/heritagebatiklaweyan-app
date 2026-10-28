import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../cart/presentation/viewmodels/cart_providers.dart';
import '../../../checkout/presentation/views/order_list_view.dart';
import '../../../profile/presentation/widgets/profile_header.dart';
import '../../../profile/presentation/widgets/profile_information.dart';
import '../../../profile/presentation/widgets/profile_menu_list.dart';
import '../../data/models/home_dummy_data.dart';
import '../../../search/data/models/product_filter_model.dart';
import '../../../search/presentation/viewmodels/search_providers.dart';
import '../viewmodels/home_providers.dart';
import '../widgets/best_seller_section.dart';
import '../widgets/category_section.dart';
import '../widgets/home_bottom_navigation.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/other_products_section.dart';
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
  final ScrollController _homeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _homeScrollController.addListener(_onHomeScroll);
  }

  void _onHomeScroll() {
    if (_homeScrollController.hasClients) {
      final maxScroll = _homeScrollController.position.maxScrollExtent;
      final currentScroll = _homeScrollController.position.pixels;
      // Trigger infinite scroll saat mendekati batas bawah (250px sebelum batas akhir)
      if (currentScroll >= maxScroll - 250) {
        ref.read(homeViewModelProvider.notifier).loadMoreOtherProducts();
      }
    }
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Menangani aksi penambahan produk ke keranjang belanja
  Future<void> _handleAddToCart(ProductItem product) async {
    final productId = int.tryParse(product.id) ?? 0;
    if (productId <= 0) {
      AppSnackBar.showError(context, 'ID produk tidak valid.');
      return;
    }

    final success = await ref.read(cartViewModelProvider.notifier).addToCart(
      productId,
      quantity: 1,
      onError: (message) {
        if (!mounted) return;
        AppSnackBar.showError(context, message);
      },
    );

    if (success && mounted) {
      AppSnackBar.showSuccess(
        context,
        '${product.name} berhasil ditambahkan ke keranjang.',
      );
    }
  }

  /// Menangani klik banner promosi
  void _handleBannerTap(PromoBannerItem banner) {
    if (banner.targetType == 'product' && banner.productId != null) {
      context.push('/product/${banner.productId}');
    } else if (banner.targetType == 'category' && banner.categoryId != null) {
      final homeState = ref.read(homeViewModelProvider);
      final category = homeState.categories.firstWhere(
        (c) => c.id == banner.categoryId.toString(),
        orElse: () => ProductCategoryItem(
          id: banner.categoryId.toString(),
          name: banner.title,
        ),
      );
      context.push('/category-products', extra: category);
    } else if (banner.targetType == 'url' &&
        banner.targetUrl != null &&
        banner.targetUrl!.isNotEmpty) {
      AppSnackBar.showSuccess(context, 'Membuka promo: ${banner.title}');
    } else {
      AppSnackBar.showSuccess(context, 'Promo: ${banner.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentTabIndex.clamp(0, 3),
          children: [
            // Tab 0: Home
            _buildHomeContent(),

            // Tab 1: Wishlist
            _buildWishlistTab(),

            // Tab 2: History (Riwayat Transaksi & Pesanan)
            _buildHistoryTab(),

            // Tab 3: Account (Profil & Pengaturan Akun)
            _buildAccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNavigation(
        currentIndex: _currentTabIndex.clamp(0, 3),
        onTabSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  /// Konten Utama Tab Home (Integrasi Kategori, Rekomendasi, Terlaris, & Infinite Scroll Produk Lainnya)
  Widget _buildHomeContent() {
    final homeState = ref.watch(homeViewModelProvider);
    final searchState = ref.watch(searchViewModelProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await ref.read(homeViewModelProvider.notifier).initHome(isRefresh: true);
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Halaman beranda diperbarui.');
        }
      },
      child: SingleChildScrollView(
        controller: _homeScrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header (Alamat Pengiriman, Dropdown, Cart & Notification Badge)
            const HomeHeader(),

            // 2. Search Bar dengan Icon Filter (Navigasi ke Search Screen & Filter Screen)
            HomeSearchBar(
              controller: _searchController,
              readOnly: true,
              activeFilterCount: searchState.activeFilterCount,
              onTap: () {
                context.push('/search');
              },
              onFilterTap: () async {
                final result = await context.push<ProductFilter?>(
                  '/filter',
                  extra: searchState.filter,
                );
                if (result != null) {
                  ref.read(searchViewModelProvider.notifier).applyFilter(result);
                  if (mounted) {
                    context.push('/search');
                  }
                }
              },
            ),

            const SizedBox(height: 6),

            // 3. Banner Promo Carousel dengan Indikator Dots
            PromoCarousel(
              banners: homeState.banners.isNotEmpty
                  ? homeState.banners
                  : HomeDummyData.banners,
              onBannerTap: (index) {
                final banners = homeState.banners.isNotEmpty
                    ? homeState.banners
                    : HomeDummyData.banners;
                if (index < banners.length) {
                  _handleBannerTap(banners[index]);
                }
              },
            ),

            const SizedBox(height: 10),

            // 4. Information Card (Toko & Jarak + Poin URBatik)
            const StoreInfoCard(),

            const SizedBox(height: 12),

            // 5. Category Section (Integrasi Backend & Filter Produk)
            CategorySection(
              categories: homeState.categories,
              selectedCategoryId: homeState.selectedCategoryId,
              onCategorySelected: (cat) {
                context.push('/category-products', extra: cat);
              },
              onSeeAllTap: () {
                context.push('/categories');
              },
            ),

            const SizedBox(height: 14),

            // 6. Recommendation Section (Daftar Produk Rekomendasi Scroll Horizontal)
            RecommendationSection(
              products: homeState.recommendations,
              onAddToCart: _handleAddToCart,
            ),

            const SizedBox(height: 16),

            // 7. Best Seller Section (Daftar Produk Terlaris Scroll Horizontal)
            BestSellerSection(
              products: homeState.bestSellers,
              onAddToCart: _handleAddToCart,
            ),

            const SizedBox(height: 16),

            // 8. Other Products Section (Semua Produk dengan Paginate 10 & Infinite Scroll)
            OtherProductsSection(
              products: homeState.otherProducts,
              isLoadingMore: homeState.isLoadingMore,
              hasMore: homeState.hasMoreOtherProducts,
              onAddToCart: _handleAddToCart,
            ),

            // Ruang bawah agar konten tidak menempel ke bilah navigasi bawah
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Tampilan Tab Wishlist (Koleksi Favorit Pengguna)
  Widget _buildWishlistTab() {
    return _buildPlaceholderTab(
      icon: Icons.favorite_outline_rounded,
      title: 'Wishlist Anda Masih Kosong',
      subtitle:
          'Simpan motif batik favorit Anda di sini untuk mempermudah pembelian berikutnya.',
      buttonText: 'Cari Motif Favorit',
    );
  }

  /// Tampilan Tab History (Riwayat Pesanan & Transaksi - My Orders)
  Widget _buildHistoryTab() {
    return OrderListView(
      embedded: true,
      onBackTap: () {
        setState(() {
          _currentTabIndex = 0;
        });
      },
    );
  }

  /// Tampilan Tab Placeholder yang Rapi untuk Wishlist & History
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
                  _currentTabIndex = 0; // Kembali ke Tab Home
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

    final String displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name
        : (user?.username != null && user!.username.trim().isNotEmpty)
            ? user.username
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
              bottom: 24,
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
                    if (!mounted) return;
                    AppSnackBar.showSuccess(context, 'Berhasil keluar dari akun.');
                    context.go('/login');
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
