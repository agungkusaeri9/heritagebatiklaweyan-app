import '../../../../core/logging/app_logger.dart';
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
  });
}

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PromoBannerItem>> getBanners() async {
    try {
      final list = await remoteDataSource.getBanners();
      if (list.isNotEmpty) {
        return list;
      }
      return HomeDummyData.banners;
    } catch (e, stack) {
      AppLogger.w('Gagal mengambil banner dari API, fallback ke dummy data: $e');
      AppLogger.d('Stack trace: $stack');
      return HomeDummyData.banners;
    }
  }

  @override
  Future<List<ProductCategoryItem>> getCategories() async {
    try {
      final list = await remoteDataSource.getCategories();
      if (list.isNotEmpty) {
        return list;
      }
      return HomeDummyData.categories;
    } catch (e, stack) {
      AppLogger.w('Gagal mengambil kategori dari API, menggunakan fallback dummy data: $e');
      AppLogger.d('Stack trace: $stack');
      return HomeDummyData.categories;
    }
  }

  @override
  Future<List<ProductItem>> getRecommendations() async {
    try {
      final list = await remoteDataSource.getRecommendations();
      if (list.isNotEmpty) {
        return list;
      }
      return HomeDummyData.recommendations;
    } catch (e, stack) {
      AppLogger.w('Gagal mengambil rekomendasi dari API, fallback ke dummy data: $e');
      AppLogger.d('Stack trace: $stack');
      return HomeDummyData.recommendations;
    }
  }

  @override
  Future<List<ProductItem>> getBestSellers() async {
    try {
      final list = await remoteDataSource.getBestSellers();
      if (list.isNotEmpty) {
        return list;
      }
      return HomeDummyData.recommendations;
    } catch (e, stack) {
      AppLogger.w('Gagal mengambil produk terlaris dari API, fallback ke dummy data: $e');
      AppLogger.d('Stack trace: $stack');
      return HomeDummyData.recommendations;
    }
  }

  @override
  Future<PaginatedProductsResult> getOtherProducts({
    int page = 1,
    int perPage = 10,
    String? categorySlug,
  }) async {
    try {
      return await remoteDataSource.getOtherProducts(
        page: page,
        perPage: perPage,
        categorySlug: categorySlug,
      );
    } catch (e, stack) {
      AppLogger.w('Gagal mengambil paginated produk dari API: $e');
      AppLogger.d('Stack trace: $stack');
      if (page == 1) {
        return PaginatedProductsResult(
          items: HomeDummyData.recommendations,
          hasMore: false,
          currentPage: 1,
          total: HomeDummyData.recommendations.length,
        );
      }
      rethrow;
    }
  }
}
