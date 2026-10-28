import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../cart/presentation/viewmodels/cart_providers.dart';
import '../../../search/data/models/product_filter_model.dart';
import '../../data/models/home_dummy_data.dart';
import '../viewmodels/home_providers.dart';
import '../widgets/product_card.dart';

/// Screen: CategoryProductsView
/// Menampilkan daftar produk batik berdasarkan kategori yang dipilih,
/// lengkap dengan sorting, filtering, pencarian lokal, infinite scroll, dan keranjang belanja
class CategoryProductsView extends ConsumerStatefulWidget {
  final ProductCategoryItem category;

  const CategoryProductsView({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends ConsumerState<CategoryProductsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ProductItem> _allFetchedProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;

  // Filter & Pengurutan
  ProductFilter _filter = const ProductFilter();
  String _searchQuery = '';
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _fetchProducts(page: 1);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 250 && !_isLoadingMore && _hasMore && !_isLoading) {
        _loadMore();
      }
    }
  }

  /// Mengambil daftar produk untuk kategori ini dari backend
  Future<void> _fetchProducts({int page = 1}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final isAll = widget.category.id == 'all' || widget.category.slug.isEmpty;
      final repository = ref.read(homeRepositoryProvider);

      final result = await repository.getOtherProducts(
        page: page,
        perPage: 12,
        categorySlug: isAll ? null : widget.category.slug,
      );

      if (!mounted) return;

      setState(() {
        if (page == 1) {
          _allFetchedProducts = result.items;
        } else {
          final existingIds = _allFetchedProducts.map((p) => p.id).toSet();
          final newItems = result.items.where((p) => !existingIds.contains(p.id)).toList();
          _allFetchedProducts.addAll(newItems);
        }
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _totalCount = result.total > 0 ? result.total : _allFetchedProducts.length;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e, stack) {
      AppLogger.e('Gagal memuat produk kategori: ${widget.category.name}', error: e, stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Gagal memuat produk kategori. Silakan periksa koneksi Anda.';
      });
    }
  }

  /// Memuat halaman berikutnya untuk infinite scroll
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchProducts(page: _currentPage + 1);
  }

  /// Menangani penambahan produk ke keranjang belanja
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

  /// Menangani tap pada kartu produk
  void _handleProductTap(ProductItem product) {
    AppSnackBar.showSuccess(context, 'Melihat produk: ${product.name}');
  }

  /// Memfilter dan mengurutkan produk secara dinamis di sisi klien
  List<ProductItem> _getFilteredProducts() {
    List<ProductItem> list = List<ProductItem>.from(_allFetchedProducts);

    // 1. Filter Pencarian Teks Lokal
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final matchName = p.name.toLowerCase().contains(_searchQuery);
        final matchCat = p.category.toLowerCase().contains(_searchQuery);
        return matchName || matchCat;
      }).toList();
    }

    // 2. Filter Kriteria (Harga, Gender, Rating)
    list = list.where((p) => _filter.matches(p)).toList();

    // 3. Pengurutan (Sort)
    list = _filter.sortProducts(list);

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);
    final displayedProducts = _getFilteredProducts();
    final isAll = widget.category.id == 'all' || widget.category.slug.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAll ? 'Semua Produk' : widget.category.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          // Toggle Search Bar
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
              size: 24,
              color: const Color(0xFF1E293B),
            ),
            tooltip: 'Cari Produk',
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchController.clear();
                }
              });
            },
          ),

          // Cart Icon dengan badge kuantitas
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 24,
                  color: Color(0xFF1E293B),
                ),
                tooltip: 'Keranjang Belanja',
                onPressed: () => context.push('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await _fetchProducts(page: 1);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Search Bar opsional jika diaktifkan
              if (_showSearchBar)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari dalam ${widget.category.name}...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 2. Banner Header Kategori
              SliverToBoxAdapter(
                child: _buildCategoryBannerHeader(),
              ),

              // 3. Filter & Sort Bar
              SliverToBoxAdapter(
                child: _buildFilterSortBar(),
              ),

              // 4. Area Konten Produk
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (_errorMessage != null && _allFetchedProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else if (displayedProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = displayedProducts[index];
                        return ProductCard(
                          product: product,
                          onProductTap: _handleProductTap,
                          onAddToCart: () => _handleAddToCart(product),
                        );
                      },
                      childCount: displayedProducts.length,
                    ),
                  ),
                ),

              // 5. Indikator Loading Infinite Scroll
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.2,
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner Header Kategori dengan visual, deskripsi, dan total produk
  Widget _buildCategoryBannerHeader() {
    final hasImage = widget.category.imageUrl != null && widget.category.imageUrl!.isNotEmpty;
    final isAll = widget.category.id == 'all' || widget.category.slug.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon / Gambar Kategori Bulat
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      widget.category.imageUrl!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        widget.category.icon,
                        size: 26,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      widget.category.icon,
                      size: 26,
                      color: Colors.white,
                    ),
            ),
          ),

          const SizedBox(width: 14),

          // Detail Kategori
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isAll ? 'Semua Koleksi Batik' : widget.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_totalCount Produk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.category.description.isNotEmpty
                      ? widget.category.description
                      : 'Koleksi mahakarya batik autentik dan eksklusif khas Laweyan.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bilah Filter dan Pilihan Pengurutan (Sort Chips)
  Widget _buildFilterSortBar() {
    final activeCount = _filter.activeFilterCount;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Tombol Buka Layar Filter Lengkap
            InkWell(
              onTap: () async {
                final result = await context.push<ProductFilter?>(
                  '/filter',
                  extra: _filter,
                );
                if (result != null) {
                  setState(() {
                    _filter = result;
                  });
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: activeCount > 0 ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activeCount > 0 ? AppColors.primary : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: activeCount > 0 ? Colors.white : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: activeCount > 0 ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Opsi Sort: Terbaru
            _buildSortChip('Terbaru', SortByFilter.mostRecent),
            const SizedBox(width: 8),

            // Opsi Sort: Terpopuler
            _buildSortChip('Terpopuler', SortByFilter.popular),
            const SizedBox(width: 8),

            // Opsi Sort: Harga Terendah
            _buildSortChip('Harga Terendah', SortByFilter.priceLowToHigh),
            const SizedBox(width: 8),

            // Opsi Sort: Harga Tertinggi
            _buildSortChip('Harga Tertinggi', SortByFilter.priceHighToLow),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, SortByFilter sort) {
    final isSelected = _filter.sortBy == sort;

    return InkWell(
      onTap: () {
        setState(() {
          _filter = _filter.copyWith(sortBy: sort);
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  /// Tampilan jika produk kosong
  Widget _buildEmptyState() {
    final hasActiveFilter = !_filter.isDefault || _searchQuery.isNotEmpty;

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
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasActiveFilter ? 'Tidak Ada Produk Sesuai Filter' : 'Belum Ada Produk di Kategori Ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilter
                  ? 'Coba sesuaikan kriteria filter atau kata kunci pencarian Anda.'
                  : 'Koleksi untuk kategori ${widget.category.name} akan segera hadir. Anda dapat menjelajahi kategori lainnya.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (hasActiveFilter)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _filter = const ProductFilter();
                    _searchController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Reset Filter',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  context.push('/categories');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Lihat Kategori Lainnya',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Tampilan jika terjadi kesalahan saat memuat data
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Produk',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kendala saat menghubungkan ke server.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fetchProducts(page: 1),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
