import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/models/home_dummy_data.dart';
import '../../data/repositories/home_repository.dart';
import 'home_providers.dart';
import 'home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  late final HomeRepository _repository;

  @override
  HomeState build() {
    _repository = ref.watch(homeRepositoryProvider);
    // Jalankan inisialisasi data beranda saat provider pertama kali di-watch
    Future.microtask(() => initHome());
    return const HomeState(status: HomeStatus.loading);
  }

  /// Memuat seluruh komponen beranda secara paralel (Kategori, Rekomendasi, Terlaris, & Produk Lainnya Hal 1)
  Future<void> initHome({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(status: HomeStatus.loading, errorMessage: null);
    }

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getRecommendations(),
        _repository.getBestSellers(),
        _repository.getOtherProducts(
          page: 1,
          perPage: 10,
          categorySlug: state.selectedCategorySlug,
        ),
        _repository.getBanners(),
      ]);

      final rawCategories = results[0] as List<ProductCategoryItem>;
      final recommendations = results[1] as List<ProductItem>;
      final bestSellers = results[2] as List<ProductItem>;
      final otherProductsResult = results[3] as dynamic;
      final banners = results[4] as List<PromoBannerItem>;

      // Sisipkan opsi "All" di urutan terdepan agar user bisa reset filter kategori
      final List<ProductCategoryItem> categoriesWithAll = [
        const ProductCategoryItem(
          id: 'all',
          name: 'All',
          slug: '',
          description: 'Semua koleksi mahakarya batik warisan Laweyan',
          icon: Icons.grid_view_rounded,
        ),
        ...rawCategories.where((c) => c.id != 'all' && c.slug != 'all'),
      ];

      final otherItems = otherProductsResult.items as List<ProductItem>;
      final hasMore = otherProductsResult.hasMore as bool;
      final currentPage = otherProductsResult.currentPage as int;

      state = state.copyWith(
        status: HomeStatus.success,
        isRefreshing: false,
        banners: banners,
        categories: categoriesWithAll,
        recommendations: recommendations,
        bestSellers: bestSellers,
        otherProducts: otherItems,
        hasMoreOtherProducts: hasMore,
        currentOtherPage: currentPage,
        errorMessage: null,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal memuat data beranda', error: e, stackTrace: stack);
      state = state.copyWith(
        status: HomeStatus.error,
        isRefreshing: false,
        errorMessage:
            'Maaf, server sedang mengalami gangguan atau kendala koneksi. Silakan muat ulang halaman.',
      );
    }
  }

  /// Memilih kategori untuk memfilter daftar "Product Lainnya"
  Future<void> selectCategory(ProductCategoryItem category) async {
    if (state.selectedCategoryId == category.id) return;

    final isAll = category.id == 'all' || category.slug.isEmpty;
    state = state.copyWith(
      selectedCategoryId: category.id,
      selectedCategorySlug: isAll ? null : category.slug,
      clearCategorySlug: isAll,
      isLoadingMore: false,
      currentOtherPage: 1,
      hasMoreOtherProducts: true,
    );

    try {
      final result = await _repository.getOtherProducts(
        page: 1,
        perPage: 10,
        categorySlug: isAll ? null : category.slug,
      );

      state = state.copyWith(
        otherProducts: result.items,
        hasMoreOtherProducts: result.hasMore,
        currentOtherPage: result.currentPage,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal memfilter produk berdasarkan kategori', error: e, stackTrace: stack);
    }
  }

  /// Infinite Scroll: Memuat halaman berikutnya untuk daftar "Product Lainnya"
  Future<void> loadMoreOtherProducts() async {
    if (state.isLoadingMore || !state.hasMoreOtherProducts || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentOtherPage + 1;
      final result = await _repository.getOtherProducts(
        page: nextPage,
        perPage: 10,
        categorySlug: state.selectedCategorySlug,
      );

      // Gabungkan produk baru dengan produk yang sudah ada tanpa duplikasi ID
      final existingIds = state.otherProducts.map((p) => p.id).toSet();
      final newUniqueItems = result.items.where((p) => !existingIds.contains(p.id)).toList();

      state = state.copyWith(
        isLoadingMore: false,
        otherProducts: [...state.otherProducts, ...newUniqueItems],
        hasMoreOtherProducts: result.hasMore,
        currentOtherPage: result.currentPage,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal memuat halaman berikutnya untuk produk lainnya', error: e, stackTrace: stack);
      state = state.copyWith(isLoadingMore: false);
    }
  }
}
