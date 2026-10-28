import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/datasources/search_remote_data_source.dart';
import '../../data/repositories/search_repository.dart';
import 'search_state.dart';
import 'search_viewmodel.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SearchRemoteDataSourceImpl(
    dio: dioClient.dio,
    dioClient: dioClient,
  );
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final remoteDataSource = ref.watch(searchRemoteDataSourceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return SearchRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localStorageService: localStorage,
  );
});

final searchViewModelProvider =
    NotifierProvider<SearchViewModel, SearchState>(() {
  return SearchViewModel();
});
