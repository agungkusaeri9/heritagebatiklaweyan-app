import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../../home/data/models/home_dummy_data.dart';

class SearchResult {
  final List<ProductItem> items;
  final int total;
  final int currentPage;
  final bool hasMore;

  const SearchResult({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });
}

abstract class SearchRemoteDataSource {
  Future<SearchResult> searchProducts({
    required String query,
    int page = 1,
    int perPage = 12,
    String? sort,
    String? direction,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;

  SearchRemoteDataSourceImpl({
    required this.dio,
    required this.dioClient,
  });

  @override
  Future<SearchResult> searchProducts({
    required String query,
    int page = 1,
    int perPage = 12,
    String? sort,
    String? direction,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (query.trim().isNotEmpty) {
        queryParams['search'] = query.trim();
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }
      if (direction != null && direction.isNotEmpty) {
        queryParams['direction'] = direction;
      }

      AppLogger.d('Searching products with params: $queryParams');
      final response = await dio.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      final List<ProductItem> items = [];
      int total = 0;
      int currentPage = page;
      bool hasMore = false;

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
          total = (pagination['total'] as num?)?.toInt() ?? items.length;
          currentPage = (pagination['current_page'] as num?)?.toInt() ?? page;
          hasMore = pagination['has_more_pages'] as bool? ?? false;
        } else {
          total = items.length;
          hasMore = items.length >= perPage;
        }
      }

      return SearchResult(
        items: items,
        total: total,
        currentPage: currentPage,
        hasMore: hasMore,
      );
    } on DioException catch (e) {
      AppLogger.e('DioException during product search: $e', error: e);
      throw dioClient.handleDioError(e);
    } catch (e, stack) {
      AppLogger.e('Unexpected error during search: $e', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mencari produk: $e');
    }
  }
}
