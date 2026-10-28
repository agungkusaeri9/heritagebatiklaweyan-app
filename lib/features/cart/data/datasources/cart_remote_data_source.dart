import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cart_item_model.dart';
import '../models/cart_summary_model.dart';

class CartResult {
  final List<CartItemModel> items;
  final CartSummaryModel summary;

  const CartResult({
    required this.items,
    required this.summary,
  });
}

abstract class CartRemoteDataSource {
  Future<CartResult> getCart();
  Future<CartItemModel> updateQuantity(int cartId, int quantity);
  Future<bool> deleteItem(int cartId);
  Future<CartItemModel> addToCart(int productId, int quantity, {String? variantInfo});
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;

  CartRemoteDataSourceImpl({
    required this.dio,
    required this.dioClient,
  });

  @override
  Future<CartResult> getCart() async {
    try {
      AppLogger.d('Mengambil daftar keranjang belanja dari ${ApiConstants.cart}');

      final response = await dio.get(ApiConstants.cart);
      final responseData = response.data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'] as Map<String, dynamic>;

        final List<CartItemModel> items = [];
        if (data['items'] is List) {
          for (final rawItem in data['items'] as List) {
            if (rawItem is Map<String, dynamic>) {
              items.add(CartItemModel.fromJson(rawItem));
            }
          }
        }

        CartSummaryModel summary = const CartSummaryModel.empty();
        if (data['summary'] is Map<String, dynamic>) {
          summary = CartSummaryModel.fromJson(data['summary'] as Map<String, dynamic>);
        }

        return CartResult(items: items, summary: summary);
      }

      return const CartResult(
        items: [],
        summary: CartSummaryModel.empty(),
      );
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal memuat daftar keranjang', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memuat daftar keranjang: $e');
    }
  }

  @override
  Future<CartItemModel> updateQuantity(int cartId, int quantity) async {
    try {
      final endpoint = ApiConstants.cartItem(cartId);
      AppLogger.d('Mengubah kuantitas item keranjang id $cartId menjadi $quantity via $endpoint');

      final response = await dio.put(
        endpoint,
        data: {'quantity': quantity},
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'] as Map<String, dynamic>;
        return CartItemModel.fromJson(data);
      }

      throw const ApiException(message: 'Format respon update keranjang tidak sesuai');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal memperbarui kuantitas item keranjang', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memperbarui kuantitas: $e');
    }
  }

  @override
  Future<bool> deleteItem(int cartId) async {
    try {
      final endpoint = ApiConstants.cartItem(cartId);
      AppLogger.d('Menghapus item keranjang id $cartId via $endpoint');

      final response = await dio.delete(endpoint);
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final meta = responseData['meta'];
        if (meta is Map<String, dynamic> && meta['status'] == 'success') {
          return true;
        }
      }

      return true;
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal menghapus item dari keranjang', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal menghapus item keranjang: $e');
    }
  }

  @override
  Future<CartItemModel> addToCart(int productId, int quantity, {String? variantInfo}) async {
    try {
      AppLogger.d('Menambahkan produk id $productId ke keranjang');

      final payload = <String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
      };
      if (variantInfo != null && variantInfo.isNotEmpty) {
        payload['variant_info'] = variantInfo;
      }

      final response = await dio.post(
        ApiConstants.cart,
        data: payload,
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        final data = responseData['data'] as Map<String, dynamic>;
        return CartItemModel.fromJson(data);
      }

      throw const ApiException(message: 'Format respon tambah keranjang tidak sesuai');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal menambahkan produk ke keranjang', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal menambahkan produk ke keranjang: $e');
    }
  }
}
