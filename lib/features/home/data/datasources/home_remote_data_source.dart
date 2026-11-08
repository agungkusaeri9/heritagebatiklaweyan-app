import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../models/home_dummy_data.dart';

class PaginatedProductsResult {
  final List<ProductItem> items;
  final bool hasMore;
  final int currentPage;
  final int total;

  const PaginatedProductsResult({
    required this.items,
    required this.hasMore,
    required this.currentPage,
    this.total = 0,
  });
}

class PaginatedProductReviewsResult {
  final List<ProductReviewItem> items;
  final ProductRatingStats stats;
  final bool hasMore;
  final int currentPage;
  final int total;

  const PaginatedProductReviewsResult({
    required this.items,
    required this.stats,
    required this.hasMore,
    required this.currentPage,
    this.total = 0,
  });
}

abstract class HomeRemoteDataSource {
  Future<List<PromoBannerItem>> getBanners();
  Future<List<ProductCategoryItem>> getCategories();
  Future<List<ProductItem>> getRecommendations();
  Future<List<ProductItem>> getBestSellers();
  Future<PaginatedProductsResult> getOtherProducts({
    int page = 1,
    int perPage = 10,
    String? categorySlug,
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

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({
    required this.dio,
    required this.dioClient,
  });

  @override
  Future<List<PromoBannerItem>> getBanners() async {
    try {
      AppLogger.d('Mengambil daftar banner dari ${ApiConstants.banners}');
      final response = await dio.get(ApiConstants.banners);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => PromoBannerItem.fromJson(json))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      AppLogger.e('DioException saat mengambil banner', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Error tak terduga saat getBanners', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil data banner: $e');
    }
  }

  @override
  Future<List<ProductCategoryItem>> getCategories() async {
    try {
      AppLogger.d('Mengambil daftar kategori dari ${ApiConstants.categories}');
      final response = await dio.get(ApiConstants.categories);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => ProductCategoryItem.fromJson(json))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      AppLogger.e('DioException saat mengambil kategori', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Error tak terduga saat getCategories', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil data kategori: $e');
    }
  }

  @override
  Future<List<ProductItem>> getRecommendations() async {
    try {
      AppLogger.d('Mengambil produk rekomendasi dari ${ApiConstants.productRecommendations}');
      final response = await dio.get(ApiConstants.productRecommendations);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => ProductItem.fromJson(json))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      AppLogger.e('DioException saat mengambil rekomendasi', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Error tak terduga saat getRecommendations', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil rekomendasi produk: $e');
    }
  }

  @override
  Future<List<ProductItem>> getBestSellers() async {
    try {
      AppLogger.d('Mengambil produk terlaris dari ${ApiConstants.productBestSellers}');
      final response = await dio.get(ApiConstants.productBestSellers);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => ProductItem.fromJson(json))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      AppLogger.e('DioException saat mengambil produk terlaris', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Error tak terduga saat getBestSellers', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil produk terlaris: $e');
    }
  }

  @override
  Future<PaginatedProductsResult> getOtherProducts({
    int page = 1,
    int perPage = 10,
    String? categorySlug,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (categorySlug != null && categorySlug.isNotEmpty && categorySlug != 'all') {
        queryParams['category'] = categorySlug;
      }

      AppLogger.d('Mengambil daftar produk lainnya: $queryParams');
      final response = await dio.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );
      final responseData = response.data;

      final List<ProductItem> items = [];
      bool hasMore = false;
      int currentPage = page;
      int total = 0;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is List) {
          items.addAll(
            (responseData['data'] as List)
                .whereType<Map<String, dynamic>>()
                .map((json) => ProductItem.fromJson(json)),
          );
        }

        final meta = responseData['meta'];
        if (meta is Map<String, dynamic> && meta['pagination'] is Map<String, dynamic>) {
          final pagination = meta['pagination'] as Map<String, dynamic>;
          hasMore = pagination['has_more_pages'] as bool? ?? false;
          currentPage = (pagination['current_page'] as num?)?.toInt() ?? page;
          total = (pagination['total'] as num?)?.toInt() ?? 0;
        } else {
          hasMore = items.length >= perPage;
        }
      }

      return PaginatedProductsResult(
        items: items,
        hasMore: hasMore,
        currentPage: currentPage,
        total: total,
      );
    } on DioException catch (e) {
      AppLogger.e('DioException saat mengambil produk paginasi', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Error tak terduga saat getOtherProducts', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil produk: $e');
    }
  }

  @override
  Future<ProductItem> getProductDetail(dynamic idOrSlug) async {
    try {
      AppLogger.d(
        'Mengambil detail produk dari ${ApiConstants.productDetail(idOrSlug)}',
      );
      final response = await dio.get(ApiConstants.productDetail(idOrSlug));
      final responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data') &&
          responseData['data'] is Map<String, dynamic>) {
        return ProductItem.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }

      throw const ApiException(message: 'Format respon detail produk tidak valid.');
    } on DioException catch (e) {
      AppLogger.e('DioException saat mengambil detail produk', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Error tak terduga saat getProductDetail', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil detail produk: $e');
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
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (rating != null && rating >= 1 && rating <= 5) {
        queryParams['rating'] = rating;
      }

      AppLogger.d(
        'Mengambil daftar ulasan produk dari ${ApiConstants.productReviews(idOrSlug)}: $queryParams',
      );
      final response = await dio.get(
        ApiConstants.productReviews(idOrSlug),
        queryParameters: queryParams,
      );
      final responseData = response.data;

      final List<ProductReviewItem> items = [];
      ProductRatingStats stats = const ProductRatingStats();
      bool hasMore = false;
      int currentPage = page;
      int total = 0;

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('data') && responseData['data'] is List) {
          items.addAll(
            (responseData['data'] as List)
                .whereType<Map<String, dynamic>>()
                .map((json) => ProductReviewItem.fromJson(json)),
          );
        }

        final meta = responseData['meta'];
        if (meta is Map<String, dynamic>) {
          if (meta['rating_stats'] is Map<String, dynamic>) {
            stats = ProductRatingStats.fromJson(
              meta['rating_stats'] as Map<String, dynamic>,
            );
          }
          if (meta['pagination'] is Map<String, dynamic>) {
            final pagination = meta['pagination'] as Map<String, dynamic>;
            hasMore = pagination['has_more_pages'] as bool? ?? false;
            currentPage =
                (pagination['current_page'] as num?)?.toInt() ?? page;
            total = (pagination['total'] as num?)?.toInt() ?? 0;
          } else {
            hasMore = items.length >= perPage;
          }
        }
      }

      return PaginatedProductReviewsResult(
        items: items,
        stats: stats,
        hasMore: hasMore,
        currentPage: currentPage,
        total: total,
      );
    } on DioException catch (e) {
      AppLogger.e('DioException saat mengambil ulasan produk', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e(
        'Error tak terduga saat getProductReviews',
        error: e,
        stackTrace: stack,
      );
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil ulasan produk: $e');
    }
  }

  @override
  Future<List<VirtualTryOnModelItem>> getVirtualTryOnModels() async {
    try {
      final response = await dio.get(ApiConstants.virtualTryOnModels);
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        return (responseData['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(VirtualTryOnModelItem.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw dioClient.handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil daftar model Try-On: $e');
    }
  }

  @override
  Future<VirtualTryOnTaskItem> createVirtualTryOn({
    required int productId,
    int? virtualTryOnModelId,
    String? galleryPhotoPath,
    String? gender,
    bool? generateVideo,
  }) async {
    try {
      Response response;
      if (galleryPhotoPath != null && galleryPhotoPath.trim().isNotEmpty) {
        final formData = FormData.fromMap({
          'product_id': productId,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          if (generateVideo != null) 'generate_video': generateVideo ? 1 : 0,
          'model_photo': await MultipartFile.fromFile(galleryPhotoPath),
        });
        response = await dio.post(
          ApiConstants.virtualTryOns,
          data: formData,
        );
      } else {
        response = await dio.post(
          ApiConstants.virtualTryOns,
          data: {
            'product_id': productId,
            'virtual_try_on_model_id': virtualTryOnModelId,
            if (gender != null && gender.isNotEmpty) 'gender': gender,
            if (generateVideo != null) 'generate_video': generateVideo ? 1 : 0,
          },
        );
      }

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic>) {
        return VirtualTryOnTaskItem.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }
      throw const ApiException(
        message: 'Format respon pembuatan Virtual Try-On tidak valid.',
      );
    } on DioException catch (e) {
      throw dioClient.handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memulai Virtual Try-On: $e');
    }
  }

  @override
  Future<VirtualTryOnTaskItem> getVirtualTryOnProgress(int tryOnId) async {
    try {
      final response = await dio.get(ApiConstants.virtualTryOnProgress(tryOnId));
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic>) {
        return VirtualTryOnTaskItem.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }
      throw const ApiException(
        message: 'Format respon progress Virtual Try-On tidak valid.',
      );
    } on DioException catch (e) {
      throw dioClient.handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memeriksa progress Try-On: $e');
    }
  }

  @override
  Future<VirtualTryOnTaskItem> retryVirtualTryOn(int tryOnId) async {
    try {
      final response = await dio.post(ApiConstants.virtualTryOnRetry(tryOnId));
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic>) {
        return VirtualTryOnTaskItem.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }
      throw const ApiException(
        message: 'Format respon retry Virtual Try-On tidak valid.',
      );
    } on DioException catch (e) {
      throw dioClient.handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mencoba ulang Try-On: $e');
    }
  }

  @override
  Future<List<VirtualTryOnTaskItem>> getUserVirtualTryOns({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.virtualTryOns,
        queryParameters: {
          'type': 'my',
          'page': page,
          'per_page': perPage,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        return (responseData['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(VirtualTryOnTaskItem.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw dioClient.handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memuat daftar Virtual Try-On: $e');
    }
  }

  @override
  Future<VirtualTryOnTaskItem> getVirtualTryOnDetail(int tryOnId) async {
    try {
      final response = await dio.get(ApiConstants.virtualTryOnDetail(tryOnId));
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic>) {
        return VirtualTryOnTaskItem.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }
      throw const ApiException(
        message: 'Format respon detail Virtual Try-On tidak valid.',
      );
    } on DioException catch (e) {
      throw dioClient.handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil detail Virtual Try-On: $e');
    }
  }

  @override
  Future<List<VirtualTryOnTaskItem>> getProductVirtualTryOns(int productId) async {
    try {
      // Hanya model default produk (user_id NULL) yang sudah ditentukan admin
      final response = await dio.get(
        ApiConstants.productVirtualTryOns(productId),
        queryParameters: {'type': 'default', 'status': 'completed', 'per_page': 20},
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is List) {
        return (responseData['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(VirtualTryOnTaskItem.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw dioClient.handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil hasil Try-On produk: $e');
    }
  }
}
