import 'dart:convert';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/home_dummy_data.dart';

abstract class HomeRepository {
  Future<List<PromoBannerItem>> getBanners();
  Future<List<ProductCategoryItem>> getCategories();
  Future<List<ProductItem>> getRecommendations();
  Future<List<ProductItem>> getBestSellers();
  Future<PaginatedProductsResult> getOtherProducts({
    int page = 1,
    int perPage = 10,
    String? categorySlug,
    int? storeId,
  });
  Future<ProductItem> getProductDetail(dynamic idOrSlug);
  Future<PaginatedProductReviewsResult> getProductReviews(
    dynamic idOrSlug, {
    int page = 1,
    int perPage = 10,
    int? rating,
  });
  Future<List<VirtualTryOnModelItem>> getVirtualTryOnModels();
  Future<VirtualTryOnTaskItem> createVirtualTryOn({
    required int productId,
    int? virtualTryOnModelId,
    String? galleryPhotoPath,
    String? gender,
    bool? generateVideo,
  });
  Future<VirtualTryOnTaskItem> getVirtualTryOnProgress(int tryOnId);
  Future<VirtualTryOnTaskItem> retryVirtualTryOn(int tryOnId);
  Future<List<VirtualTryOnTaskItem>> getUserVirtualTryOns({
    int page = 1,
    int perPage = 20,
    String? status,
  });
  Future<VirtualTryOnTaskItem> getVirtualTryOnDetail(int tryOnId);
  Future<List<VirtualTryOnTaskItem>> getProductVirtualTryOns(int productId);
}

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final ILocalStorageService localStorage;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
  });

  @override
  Future<List<PromoBannerItem>> getBanners() async {
    try {
      final lastFetchTime = localStorage.getInt(StorageKeys.cachedBannersTimestamp) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneHourMillis = 60 * 60 * 1000;

      // Cek apakah cache lokal masih berlaku (< 1 jam)
      if (currentTime - lastFetchTime < oneHourMillis) {
        final cachedString = localStorage.getString(StorageKeys.cachedBanners);
        if (cachedString != null && cachedString.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedString);
            if (decoded.isNotEmpty) {
              AppLogger.d('Mengambil banner dari SharedPreferences cache lokal (berlaku s/d 1 jam)');
              return decoded
                  .whereType<Map<String, dynamic>>()
                  .map((json) => PromoBannerItem.fromJson(json))
                  .toList();
            }
          } catch (_) {
            // Jika parsing gagal, lanjut fetch ke API
          }
        }
      }

      // Fetch dari API backend
      final banners = await remoteDataSource.getBanners();
      if (banners.isNotEmpty) {
        // Simpan ke SharedPreferences lokal beserta timestamp
        final jsonList = banners.map((b) => {
          'id': b.id,
          'title': b.title,
          'description': b.subtitle,
          'image_url': b.imageUrl,
          'target_type': b.targetType,
          'target_url': b.targetUrl,
          'product_id': b.productId,
          'category_id': b.categoryId,
        }).toList();

        await localStorage.setString(StorageKeys.cachedBanners, jsonEncode(jsonList));
        await localStorage.setInt(StorageKeys.cachedBannersTimestamp, currentTime);
      }
      return banners;
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil banner dari API, mencoba fallback cache lokal: $e', error: e, stackTrace: stack);
      // Fallback ke cache lokal jika offline / gagal koneksi
      final cachedString = localStorage.getString(StorageKeys.cachedBanners);
      if (cachedString != null && cachedString.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedString);
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((json) => PromoBannerItem.fromJson(json))
              .toList();
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<List<ProductCategoryItem>> getCategories() async {
    try {
      final lastFetchTime = localStorage.getInt(StorageKeys.cachedCategoriesTimestamp) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneHourMillis = 60 * 60 * 1000;

      // Cek apakah cache lokal kategori masih berlaku (< 1 jam)
      if (currentTime - lastFetchTime < oneHourMillis) {
        final cachedString = localStorage.getString(StorageKeys.cachedCategories);
        if (cachedString != null && cachedString.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedString);
            if (decoded.isNotEmpty) {
              AppLogger.d('Mengambil kategori dari SharedPreferences cache lokal (berlaku s/d 1 jam)');
              return decoded
                  .whereType<Map<String, dynamic>>()
                  .map((json) => ProductCategoryItem.fromJson(json))
                  .toList();
            }
          } catch (_) {}
        }
      }

      // Fetch dari API backend
      final categories = await remoteDataSource.getCategories();
      if (categories.isNotEmpty) {
        final jsonList = categories.map((c) => {
          'id': c.id,
          'name': c.name,
          'slug': c.slug,
          'description': c.description,
          'image_url': c.imageUrl,
          'total_items': c.totalItems,
        }).toList();

        await localStorage.setString(StorageKeys.cachedCategories, jsonEncode(jsonList));
        await localStorage.setInt(StorageKeys.cachedCategoriesTimestamp, currentTime);
      }
      return categories;
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil kategori dari API, mencoba fallback cache lokal: $e', error: e, stackTrace: stack);
      final cachedString = localStorage.getString(StorageKeys.cachedCategories);
      if (cachedString != null && cachedString.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedString);
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((json) => ProductCategoryItem.fromJson(json))
              .toList();
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<List<ProductItem>> getRecommendations() async {
    try {
      return await remoteDataSource.getRecommendations();
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil rekomendasi dari API: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<List<ProductItem>> getBestSellers() async {
    try {
      return await remoteDataSource.getBestSellers();
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil produk terlaris dari API: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<PaginatedProductsResult> getOtherProducts({
    int page = 1,
    int perPage = 10,
    String? categorySlug,
    int? storeId,
  }) async {
    try {
      return await remoteDataSource.getOtherProducts(
        page: page,
        perPage: perPage,
        categorySlug: categorySlug,
        storeId: storeId,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil paginated produk dari API: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<ProductItem> getProductDetail(dynamic idOrSlug) async {
    try {
      return await remoteDataSource.getProductDetail(idOrSlug);
    } catch (e, stack) {
      AppLogger.e(
        'Gagal mengambil detail produk $idOrSlug dari API: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<PaginatedProductReviewsResult> getProductReviews(
    dynamic idOrSlug, {
    int page = 1,
    int perPage = 10,
    int? rating,
  }) async {
    try {
      return await remoteDataSource.getProductReviews(
        idOrSlug,
        page: page,
        perPage: perPage,
        rating: rating,
      );
    } catch (e, stack) {
      AppLogger.e(
        'Gagal mengambil ulasan produk $idOrSlug dari API: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<List<VirtualTryOnModelItem>> getVirtualTryOnModels() {
    return remoteDataSource.getVirtualTryOnModels();
  }

  @override
  Future<VirtualTryOnTaskItem> createVirtualTryOn({
    required int productId,
    int? virtualTryOnModelId,
    String? galleryPhotoPath,
    String? gender,
    bool? generateVideo,
  }) {
    return remoteDataSource.createVirtualTryOn(
      productId: productId,
      virtualTryOnModelId: virtualTryOnModelId,
      galleryPhotoPath: galleryPhotoPath,
      gender: gender,
      generateVideo: generateVideo,
    );
  }

  @override
  Future<VirtualTryOnTaskItem> getVirtualTryOnProgress(int tryOnId) {
    return remoteDataSource.getVirtualTryOnProgress(tryOnId);
  }

  @override
  Future<VirtualTryOnTaskItem> retryVirtualTryOn(int tryOnId) {
    return remoteDataSource.retryVirtualTryOn(tryOnId);
  }

  @override
  Future<List<VirtualTryOnTaskItem>> getUserVirtualTryOns({
    int page = 1,
    int perPage = 20,
    String? status,
  }) {
    return remoteDataSource.getUserVirtualTryOns(
      page: page,
      perPage: perPage,
      status: status,
    );
  }

  @override
  Future<VirtualTryOnTaskItem> getVirtualTryOnDetail(int tryOnId) {
    return remoteDataSource.getVirtualTryOnDetail(tryOnId);
  }

  @override
  Future<List<VirtualTryOnTaskItem>> getProductVirtualTryOns(int productId) {
    return remoteDataSource.getProductVirtualTryOns(productId);
  }
}
