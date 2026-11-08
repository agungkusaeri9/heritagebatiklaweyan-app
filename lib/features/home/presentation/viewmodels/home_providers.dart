import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository.dart';
import 'home_state.dart';
import 'home_viewmodel.dart';

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final dioClient = ref.watch(dioClientProvider);
  return HomeRemoteDataSourceImpl(dio: dio, dioClient: dioClient);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final remoteDataSource = ref.watch(homeRemoteDataSourceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return HomeRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localStorage: localStorage,
  );
});

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(() {
  return HomeViewModel();
});
