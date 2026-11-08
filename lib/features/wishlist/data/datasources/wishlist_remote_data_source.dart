import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../models/wishlist_item_model.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistItemModel>> getWishlist();
  Future<WishlistItemModel> addToWishlist(int productId);
  Future<bool> removeFromWishlist(int productId);
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;

  WishlistRemoteDataSourceImpl({required this.dio, required this.dioClient});

  @override
  Future<List<WishlistItemModel>> getWishlist() async {
    try {
      AppLogger.d('Mengambil daftar wishlist dari ${ApiConstants.wishlist}');

      final response = await dio.get(ApiConstants.wishlist);
      final responseData = response.data;

      final items = <WishlistItemModel>[];
      if (responseData is Map<String, dynamic> && responseData['data'] is Map) {
        final data = responseData['data'] as Map<String, dynamic>;
        if (data['items'] is List) {
          for (final raw in data['items'] as List) {
            if (raw is Map<String, dynamic>) {
              items.add(WishlistItemModel.fromJson(raw));
            }
          }
        }
      }
      return items;
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal memuat wishlist', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memuat wishlist: $e');
    }
  }

  @override
  Future<WishlistItemModel> addToWishlist(int productId) async {
    try {
      final response = await dio.post(
        ApiConstants.wishlist,
        data: {'product_id': productId},
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData['data'] is Map) {
        return WishlistItemModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      }
      throw const ApiException(message: 'Format respon wishlist tidak sesuai');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal menambahkan ke wishlist', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal menambahkan ke wishlist: $e');
    }
  }

  @override
  Future<bool> removeFromWishlist(int productId) async {
    try {
      await dio.delete(ApiConstants.wishlistItem(productId));
      return true;
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal menghapus dari wishlist', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal menghapus dari wishlist: $e');
    }
  }
}
