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
}
