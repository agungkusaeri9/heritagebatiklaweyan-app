import '../datasources/cart_remote_data_source.dart';
import '../models/cart_item_model.dart';

abstract class CartRepository {
  Future<CartResult> getCart();
  Future<CartItemModel> updateQuantity(int cartId, int quantity);
  Future<bool> deleteItem(int cartId);
  Future<CartItemModel> addToCart(int productId, int quantity, {String? variantInfo});
}

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;

  CartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CartResult> getCart() {
    return remoteDataSource.getCart();
  }

  @override
  Future<CartItemModel> updateQuantity(int cartId, int quantity) {
    return remoteDataSource.updateQuantity(cartId, quantity);
  }

  @override
  Future<bool> deleteItem(int cartId) {
    return remoteDataSource.deleteItem(cartId);
  }

  @override
  Future<CartItemModel> addToCart(int productId, int quantity, {String? variantInfo}) {
    return remoteDataSource.addToCart(productId, quantity, variantInfo: variantInfo);
  }
}
