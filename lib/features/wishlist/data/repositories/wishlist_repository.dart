import '../datasources/wishlist_remote_data_source.dart';
import '../models/wishlist_item_model.dart';

abstract class WishlistRepository {
  Future<List<WishlistItemModel>> getWishlist();
  Future<WishlistItemModel> addToWishlist(int productId);
  Future<bool> removeFromWishlist(int productId);
}

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;

  WishlistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<WishlistItemModel>> getWishlist() {
    return remoteDataSource.getWishlist();
  }

  @override
  Future<WishlistItemModel> addToWishlist(int productId) {
    return remoteDataSource.addToWishlist(productId);
  }

  @override
  Future<bool> removeFromWishlist(int productId) {
    return remoteDataSource.removeFromWishlist(productId);
  }
}
