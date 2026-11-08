import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/wishlist_remote_data_source.dart';
import '../../data/repositories/wishlist_repository.dart';
import 'wishlist_state.dart';
import 'wishlist_viewmodel.dart';

final wishlistRemoteDataSourceProvider = Provider<WishlistRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  final dioClient = ref.watch(dioClientProvider);
  return WishlistRemoteDataSourceImpl(dio: dio, dioClient: dioClient);
});

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final remoteDataSource = ref.watch(wishlistRemoteDataSourceProvider);
  return WishlistRepositoryImpl(remoteDataSource: remoteDataSource);
});

final wishlistViewModelProvider =
    NotifierProvider<WishlistViewModel, WishlistState>(() {
      return WishlistViewModel();
    });

/// Set ID produk yang ada di wishlist (kompatibel dengan pemakaian lama di UI).
final wishlistIdsProvider = Provider<Set<String>>((ref) {
  final state = ref.watch(wishlistViewModelProvider);
  return state.productIds;
});
