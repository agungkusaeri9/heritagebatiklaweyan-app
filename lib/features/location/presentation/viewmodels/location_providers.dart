import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../data/datasources/location_local_data_source.dart';
import '../../data/datasources/location_remote_data_source.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/services/gps_service.dart';
import '../../domain/repositories/location_repository.dart';
import 'location_state.dart';
import 'location_viewmodel.dart';

// === GPS SERVICE ===
final gpsServiceProvider = Provider<IGpsService>((ref) {
  return GpsService();
});

// === DATA SOURCES ===
final locationLocalDataSourceProvider = Provider<ILocationLocalDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return LocationLocalDataSource(storage);
});

final locationRemoteDataSourceProvider = Provider<ILocationRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return LocationRemoteDataSource(dioClient);
});

// === REPOSITORY ===
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final localDataSource = ref.watch(locationLocalDataSourceProvider);
  final remoteDataSource = ref.watch(locationRemoteDataSourceProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  return LocationRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    authRepository: authRepository,
  );
});

// === VIEWMODEL ===
final locationViewModelProvider = NotifierProvider<LocationViewModel, LocationState>(() {
  return LocationViewModel();
});
