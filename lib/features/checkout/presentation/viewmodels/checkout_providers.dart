import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/checkout_remote_data_source.dart';
import '../../data/repositories/checkout_repository.dart';
import 'checkout_state.dart';
import 'checkout_viewmodel.dart';
import 'order_list_state.dart';
import 'order_list_viewmodel.dart';

final checkoutRemoteDataSourceProvider = Provider<CheckoutRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CheckoutRemoteDataSourceImpl(
    dio: dioClient.dio,
    dioClient: dioClient,
  );
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final remoteDataSource = ref.watch(checkoutRemoteDataSourceProvider);
  return CheckoutRepositoryImpl(remoteDataSource: remoteDataSource);
});

final checkoutViewModelProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(() {
  return CheckoutViewModel();
});

final orderListViewModelProvider =
    NotifierProvider<OrderListViewModel, OrderListState>(() {
  return OrderListViewModel();
});
