import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/cart_remote_data_source.dart';
import '../../data/repositories/cart_repository.dart';
import 'cart_state.dart';
import 'cart_viewmodel.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final dioClient = ref.watch(dioClientProvider);
  return CartRemoteDataSourceImpl(dio: dio, dioClient: dioClient);
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final remoteDataSource = ref.watch(cartRemoteDataSourceProvider);
  return CartRepositoryImpl(remoteDataSource: remoteDataSource);
});

final cartViewModelProvider =
    NotifierProvider<CartViewModel, CartState>(() {
  return CartViewModel();
});

/// Provider sederhana untuk memantau total item di keranjang (misal untuk HomeHeader)
final cartItemCountProvider = Provider<int>((ref) {
  final state = ref.watch(cartViewModelProvider);
  return state.totalItemCount;
});
